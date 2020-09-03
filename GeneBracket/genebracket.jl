# GeneBracket
# = reduced Bracket for genetic programming
# no symbols
# no ESC, VAL, META, PRINT
# builtin for side_effects
# no need for GC during single run
# numbers as int8

# new design of bracket for julia
# closely follow the go-branch

const CELLS     = 24*1024*1024
const GCMARGIN  = CELLS - 24
const STACKSIZE = 1024*1024

# Tagbits (from right  to left)
# three bits are used (from Bit 1 to Bit 3), Bit 4 is free and can be used for gc for tree traversals
# local pointer, global pointer, Int, Prim, Symbol, Float
# global pointers not used yet, will become meta gene pool of gene bracket
# Bit 1 = 0 ->  Cell
#    Bit 2 = 0 --> pointer to cell on local heap
#    Bit 2 = 1 --> pointer to cell on global heap  (not used in the moment)
#    Bit 3 = 0 --> cons (ie, list or quotation)
#    Bit 3 = 1 --> closure
# Bit 1 = 1 ->  Number or Symb
# Bit 2 = 0 --> Symb
#    Bit 3 = 0 --> assignable symbol
#    Bit 3 = 1 --> primitive
# Bit 2 = 1 ->  Number
#    Bit 3 = 0 --> Int
#    Bit 3 = 1 --> Float

const tagType    = 7  # mask with bits 111
const tagGlobal  = 2  # bits 010    cell on global heap
const tagCell    = 1  # bits 001
const tagCons    = 5  # bits 101
const tagClosure = 4  # bits 100
const tagPrim    = 5  # bits 101
const tagSymb    = 1  # bits 001
const tagNumb    = 2  # bits 010
const tagInt     = 3  # bits 011
const tagFloat   = 7  # bits 111

boxCons(x) = x<<4    # create a new local cons
boxClosure(x) = x<<4 | tagClosure   # create a new local closure
#func boxGlobal(x) = x<<4 | tagGlobal
boxPrim(x) = x<<4 | tagPrim  # create a local primitive
boxSymb(x) = x<<4 | tagSymb
boxInt(x)  = Int64(x)<<4 | tagInt

unbox(x) = x>>4   # remove all tags
unbox8(x) = Int8(x>>4)   # remove all tags
# in contrast to C, here the pointer is
# just the heap index, that is, a number
#func ptr(x value) int    {return int(x)>>4}   

isInt(x)    = x & tagType == tagInt
isFloat(x)  = x & tagType == tagFloat
isPrim(x)   = x & tagType == tagPrim
isSymb(x)   = x & tagType == tagSymb
isLocal(x)  = x & tagGlobal == 0
isGlobal(x) = x & tagGlobal == tagGlobal
isCell(x)   = x & tagCell == 0
isAtom(x)   = x & tagCell == tagCell
isCons(x)   = x & tagCons == 0
isClosure(x) = x & tagCons == tagClosure
isNumb(x)   = x & tagNumb == tagNumb
isAbstractSymb(x) = x & tagNumb == 0  # symbol or primitive

isNil(x) = x == NIL
isDef(x) = x != NIL
isCell2(vm,x) = isCell(x) && isCell(cdr(vm,x))
#isCons2(vm,x) = isCons(x) && isCons(cdr(vm,x))
#isCons3(x,vm) = isCons(x) && isCons(cdr(x,vm)) && isCons(cddr(x,vm))

struct Cell
    car :: Int
    cdr :: Int
end

# use a closure to generate primitives
function make_primitives()
   counter = 0
   function closure()
      counter += 1
      boxPrim(counter)
   end
end

newprimitive = make_primitives()
const NIL  = newprimitive()
const DUP  = newprimitive()
const DROP = newprimitive()
const SWAP = newprimitive()
const ROT  = newprimitive()
const CONS = newprimitive()
const CAR  = newprimitive()
const CDR  = newprimitive()
const ADD  = newprimitive()
const SUB  = newprimitive()
const MUL  = newprimitive()
const DIV  = newprimitive()
const LT   = newprimitive()
const GT   = newprimitive()
const RND  = newprimitive()
const EQ   = newprimitive()
const IF   = newprimitive()
const EVAL = newprimitive()
#const COND = newprimitive()
const DIP  = newprimitive()
const VAL  = newprimitive()
const REC  = newprimitive()
const DEF  = newprimitive()
const LAMBDA = newprimitive()
#const ESC   = newprimitive()
#const VESC  = newprimitive()
#const META  = newprimitive()
const TRACE = newprimitive()
const TYP   = newprimitive()
const SE    = newprimitive()  # side effects
#const PRINT = newprimitive()
# probably not really needed SET, WHL,COND, RTo, RIS
const UNBOUND = 0


const symboltable = Dict(
   "dup"=>DUP, "drop"=>DROP, "swap"=>SWAP, "rot"=>ROT, "cons"=>CONS, "car"=>CAR, "cdr"=>CDR,
   "add"=>ADD, "sub"=>SUB, "mul"=>MUL, "div"=>DIV, "+"=>ADD, "-"=>SUB,
   "*"=>MUL, "/"=>DIV, "lt"=>LT, "gt"=>GT, "eq"=>EQ,
   "rnd" =>RND, "if"=>IF, "eval"=>EVAL, "dip"=>DIP, "val"=>VAL,
   "rec"=>REC, "def"=>DEF, "lambda"=>LAMBDA, "\\"=>LAMBDA,
   "trace"=>TRACE, "typ"=>TYP, "se"=>SE)

const symboltable1 = Dict(
   "u"=>DUP, "o"=>DROP, "s"=>SWAP, "t"=>ROT, 
   "n"=>CONS, "a"=>CAR, "d"=>CDR,
   "+"=>ADD, "-"=>SUB, "*"=>MUL, "/"=>DIV, "lt"=>LT, "gt"=>GT, "eq"=>EQ,
   "rnd" =>RND, "?"=>IF, "e"=>EVAL, "i"=>DIP, "v"=>VAL,
   "r"=>REC, "d"=>DEF, "l"=>LAMBDA, "\\"=>LAMBDA,
   "trace"=>TRACE, "typ"=>TYP, "se"=>SE)

#   "dip"=>DIP, "cond"=>COND, 
#   "`"=>VESC, "vesc"=>VESC, 

mutable struct Stats   # some statistics about the running program
    nInst :: Int    # number of Instructions
    nRecur :: Int   # recursion depth
    nSteps :: Int   # no of performed programming steps
    extent :: Int   # exent of genome at birth (vm size)
end

# virtual machine
mutable struct Vm
    arena    :: Vector{Cell}  # memory arena to hold the cells
    brena    :: Vector{Cell}  # second arena, needed for copying gc
    next     :: Int    # index into current cell in arena
    bra      :: Int    # global program stack
    ket      :: Int    # global data stack
    env      :: Int    # environment
    stack    :: Vector{Int}
    stackindex :: Int
    stats    :: Stats # some statistics about the running program
    trace    :: Int   # trace mode e: 0=no trace, 1=trace non-verbose, 3=verbose
    depth    :: Int   # current recursion depth
    need_gc  :: Bool  # flag to indicate that heap space gets rare
    side_effect
end

function Vm(side_eff)
    arena   = Vector{Cell}(undef,CELLS)
    brena   = Vector{Cell}(undef,CELLS)
    next    = 0
    stack   = Vector{Int}(undef,STACKSIZE)
    stats = Stats(0,0,0,0)
    vm = Vm(arena,brena,next,NIL,NIL,NIL,stack,0,stats,0,0,false,side_eff)
    vm.env  = cons(vm,NIL,NIL)
    vm
end

function reset!(vm)
    vm.next = 0
    vm.stats = Stats(0,0,0,0)
    vm.bra = NIL
    vm.ket = NIL
    vm.env = cons(vm,NIL,NIL)
    vm.stackindex = 0
    vm.depth = 0
    vm.trace = 0
    vm.need_gc = false
end


#  garbage collector  *********************************
#  implement Cheney copying algorithm
#    Cheney :  non-recursive traversal of live-objects
function relocate!(vm, c)
    if !isCell(c)
        return c
    end
    indb = unbox(c)    # index into brena
    @inbounds bcell = vm.brena[indb]
    if bcell.car == UNBOUND
        return bcell.cdr
    end
    inda = vm.next     # index into arena
    if isCons(c)
        c1 = boxCons(inda)
    else
        c1 = boxClosure(inda)
    end
    @inbounds begin
         vm.arena[inda] = bcell
         vm.brena[indb] = Cell(UNBOUND, c1)
    end
    vm.next += 1
    c1
end
 
function gc(vm)
    println("starting gc ************************************************")
 
    (vm.brena, vm.arena) = (vm.arena, vm.brena)
    finger =  1
    vm.next = 1
 
    # scan root of every live object
    vm.bra = relocate!(vm, vm.bra)
    vm.ket = relocate!(vm, vm.ket)
    vm.env = relocate!(vm, vm.env)
    @inbounds for i = 1 : vm.stackindex
      vm.stack[i] = relocate!(vm,vm.stack[i])
    end
 
    # scan remaining objects in heap (including objects added by this loop)
    @inbounds while finger < vm.next
       c = vm.arena[finger]
       vm.arena[finger] = Cell(relocate!(vm,c.car), relocate!(vm,c.cdr))
       finger += 1
    end
 
    #println("GC: live objects found: ", vm.next-1)
    #println("GC: stack ", vm.stackindex, " ", vm.depth)
 
    if vm.next >= GCMARGIN
        error("Bracket GC, heap too small")
    end
    vm.need_gc = false
    #println("GC finished")
end
 
# **********************
 
function new_cons(vm,pcar, pcdr)
    vm.next += 1
    if vm.next > GCMARGIN
      vm.need_gc = true
    end
    @inbounds vm.arena[vm.next] = Cell(pcar,pcdr)
    vm.next  # return a boxed index
end
  
cons(vm,pcar,pcdr) = boxCons(new_cons(vm,pcar,pcdr))
closure(vm,pcar,pcdr) = boxClosure(new_cons(vm,pcar,pcdr))

strip_closure(vm,cl) = isClosure(cl) ? car(vm,cl) : cl


# ------- careful that we do not leak mutablilty
#         should be used only for environments
# modify car or cdr of a cell without allocating a new cell
# should only be used for bindings
@inline function setcar!(vm, cl, newcar)
    ind = unbox(cl)
    @inbounds  c = vm.arena[ind]
    @inbounds  vm.arena[ind] = Cell(newcar, c.cdr)
end
 
@inline function setcdr!(vm, cl, newcdr)
    ind = unbox(cl)
    @inbounds  c = vm.arena[ind]
    @inbounds  vm.arena[ind] = Cell(c.car, newcdr)
end
# --------------------
 
#unsafe, assumes c is a Cell
@inbounds car(vm,c) = vm.arena[unbox(c)].car
@inbounds cdr(vm,c) = vm.arena[unbox(c)].cdr
caar(vm,c) = car(vm,car(vm,c))
cadr(vm,c) = car(vm,cdr(vm,c))
cddr(vm,c) = cdr(vm,cdr(vm,c))
pop(vm,list) = (car(vm,list), cdr(vm,list))   # unsafe
pop2(vm,list) = (car(vm,list), car(vm,cdr(vm,list)), cdr(vm,cdr(vm,list)))  # unsafe
#popsafe(vm,elem) = isCons(elem) ? pop(vm,elem) : (elem,elem)

# just count the number of conses, ie dotted pair has length 1
function length_list(vm,l)
    n=0
    while isCell(l)
        n += 1
        l = cdr(vm,l)
    end
    n
 end
 
 #list length, without quoted values (but also including dotted pairs) 
 function length_nonquoted(vm, list)
    n = 0
    while isCell(list) 
        elem = car(vm,list)
        #if elem == ESC     # a quoted element
        #   if isDef(cdr(vm,list))  
        #      list = cdr(vm,list)
        #   end
        #else
        #if elem != VESC && elem != LAMBDA    #no quoted element
        if elem != VAL && elem != LAMBDA    #no quoted element
           n += 1
        end
        list = cdr(vm,list)
    end
    if isDef(list)   #count last element in dotted pair
        n += 1
    end
    n
 end

# reverse a list
# if list contained a dotted pair, reverse returns normal list
# but also a flag 
# reverse only to first occurence of a closure, because
#   closures can occur only at end of a list
#   to avoid infinite loop when printing environments
function reverse_list_long(vm,list)
    l = NIL
    while isCons(list)    # take care not to pop from a closure
      p, list = pop(vm,list)
      l = cons(vm,p,l)
      if vm.need_gc
        #pushstack(vm,l)
        #pushstack(vm,list)
        #gc(vm)
        throw(BracketException("need gc"))
        #list = popstack(vm)
        #l = popstack(vm)
      end
    end
    if isClosure(list)    # take only quotation from closure, not the environment
         # seems to be wrong, no reversal!
      l = cons(vm,car(vm,list),l)
      return l, true
    elseif isDef(list)    # list contained a dotted pair 
      l = cons(vm,list,l)
      return l, true
    else
      return l, false     # list did not contain a dotted pair
    end
end

# simple version if list does not contain a dotted pair
# still might be issues of list is a closure
function reverse_list(vm,list)
    l = NIL
    #list = strip_closure(vm,list)  # no need because list is not a closure
    while isCons(list)    # take care not to pop from a closure
      p, list = pop(vm,list)
      l = cons(vm,p,l)
      if vm.need_gc
        #pushstack(vm,l)
        #pushstack(vm,list)
        #gc(vm)
        throw(BracketException("need gc"))
        #list = popstack(vm)
        #l = popstack(vm)
      end
    end
    l
end


function isEqual(vm,p1,p2)
    p1 = strip_closure(vm,p1)
    p2 = strip_closure(vm,p2)
    if isCell(p1) && isCell(p2)
        isEqual(vm,car(vm,p1),car(vm,p2)) && 
        isEqual(vm,cdr(vm,p1),cdr(vm,p2))
    else
        p1 == p2
    end
end
 
# stack functions #############
@inline function pushstack(vm, x)
    vm.stackindex += 1
    if vm.stackindex > STACKSIZE
        error("VM stack overflow")
    end
    @inbounds vm.stack[vm.stackindex] = x
end

@inline function popstack(vm)
    #println("pop")
    #if vm.stackindex == 0
    #  error("VM stack underflow")
    #end
    @inbounds x = vm.stack[vm.stackindex]
    vm.stackindex -= 1
    return x
end

@inline function getstack(vm)
    #if vm.stackindex == 0
    #  error("VM stack underflow")
    #end
    @inbounds x = vm.stack[vm.stackindex]
    x
end

@inline function replacestack(vm, x)
    @inbounds vm.stack[vm.stackindex] = x
end

function print_stack(vm)
    println("Stack: ")
    for i = 1 : vm.stackindex
        printElem(vm, vm.stack[i])
        println()
    end
    println()
end

# creates new empty environment
@inline newenv(vm,env) = cons(vm, NIL, env)


# ************ bindings ************************************************

function find_localkey(vm, key, env)
# search binding with key in current (= top of env) frame 
    if isNil(key)
        return NIL
    end
    bnds = car(vm,env)  #current frame (list of bindings) is on top of env
    while isCell(bnds) 
       bnd = car(vm,bnds)
       if car(vm,bnd) == key 
           return bnd
       end 
       bnds = cdr(vm,bnds) 
    end
    return NIL
end

function findkey(vm, key)
# search binding with key in whole environment
    if isNil(key)
        return NIL
    end
    env = vm.env
    while isDef(env) 
       bnd = find_localkey(vm, key, env)
       if isDef(bnd) 
          return bnd
       end
       env = cdr(vm,env)
    end
    return NIL
end

function boundvalue(vm, key) # lookup symbol.. 
    bnd = findkey(vm, key)
    if bnd == NIL 
        return NIL
    else 
        return cdr(vm,bnd)
    end
end      

function bindkey(vm, key, val) 
# search for key in top frame, if key found override
# otherwise make new binding in top frame
    env = vm.env
    bnd = find_localkey(vm,key,env)
    if isNil(bnd)  # key does not yet exist
       bnd = cons(vm, key, val)  
       setcar!(vm, env, cons(vm,bnd,car(vm,env)))
    else           # key exists, just override val
       setcdr!(vm,bnd,val)
    end
end

function setkey(vm, key, val) 
# search for key in full environment, if key found override
# otherwise make new binding in top frame
    env = vm.env
    bnd = findkey(vm,key)
    if isNil(bnd)  # key does not yet exist
       bnd = cons(vm, key, val)  
       setcar!(vm, env, cons(vm,bnd,car(vm,env)))
    else           # key exists, just override val
       setcdr!(vm,bnd,val)
    end
end

#istrue(l) = isDef(l) ?  (unbox(l) != 0) : false
 
@inline istrue(l) = l != NIL && unbox(l) != 0
@inline isfalse(l) = l == NIL || unbox(l) == 0

          
# ************ io   ****************************************************+

# compared to Base64 we place the digits at the beginning 
# and use 'minus' and 'underscore' as additional chars  
# 0..9 have position 0..9, 'A' .. 'Z' have position 10..35
# 'a' .. 'z' have position 36..61, '-' has position 62 and '_' has 63*/
const base64_enc_table =
	"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
	
# position in table is ASCII index, value is the index in Base64 
const base64_dec_dict = Dict( 
'0'=>0, '1'=>1, '2'=>2, '3'=>3, '4'=>4, '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, 
'A'=>10,'B'=>11,'C'=>12,'D'=>13,'E'=>14,'F'=>15,'G'=>16,'H'=>17,'I'=>18,'J'=>19,
'K'=>20,'L'=>21,'M'=>22,'N'=>23,'O'=>24,'P'=>25,'Q'=>26,'R'=>27,'S'=>28,'T'=>29, 
'U'=>30,'V'=>31,'W'=>32,'X'=>33,'Y'=>34,'Z'=>35,'a'=>36,'b'=>37,'c'=>38,'d'=>39, 
'e'=>40,'f'=>41,'g'=>42,'h'=>43,'i'=>44,'j'=>45,'k'=>46,'l'=>47,'m'=>48,'n'=>49, 
'o'=>50,'p'=>51,'q'=>52,'r'=>53,'s'=>54,'t'=>55,'u'=>56,'v'=>57,'w'=>58,'x'=>59, 
'y'=>60,'z'=>61,'-'=>62,'_'=>63 )
    

#=
function string2symbol(str)
# encode each character into 6 bits Base64-value
# only 10*6=60 bits are used, 
# the remaining 4 bits can be used either as flags bits (at the right side)
   x = 0
   nok = 0
   for j=1:lastindex(str)
       if haskey(base64_dec_dict, str[j])
         x  = ( x << 6 ) | base64_dec_dict[str[j]] 
         nok += 1
         if nok == 10; break; end
       end
   end
   boxSymb(x)
end
=#

#=
function symbol2string(symb)
# decode symbol back to string for output
   x = unbox(symb)  # remove the flag bits 
   s = base64_enc_table[(x & 0x3F)+1]
   for i = 2 : 10
       x = x>>6
       s = s * base64_enc_table[(x & 0x3F)+1]
   end
   s = reverse(s) # revert ..
   for i=1:10     # ..  and cut-off trailing 0's 
      if s[i] != '0'
        return s[i:10]
      end
   end
   return ""
end
=#

function printElem(vm, q)
    if isInt(q)
        print(unbox(q))
    #elseif isFloat(q)
    #    print(unbox_float(q))
    elseif isNil(q)
         print("[]")
    elseif isPrim(q)
         print(first(keys(filter(p->p.second == q , symboltable))))
    #elseif isSymb(q)
    #     print(symbol2string(q))
    else
        printList(vm,q)
    end
end

function printInnerList(vm, list, invert)
    isdotted = false
    list = strip_closure(vm,list)
    if isCell(list)
       if invert 
          list, isdotted = reverse_list_long(vm,list) 
       end
       p, list = pop(vm,list) 
       printElem(vm,p)
       if isdotted   # dotted list that was reversed
          print(" .")
       end
       while isCell(list)
          p, list = pop(vm,list) 
          print(" ")
          printElem(vm,p)
       end
       if isDef(list)   # dotted list
          print(" *")
          printElem(vm,list)
       end
    end
end

function printList(vm,l)
    print("[")
    printInnerList(vm,l,true)
    print("]")
end

function printKet(vm,l)
    print("[")
    printInnerList(vm,l,false)
    println(">")
end

function printBra(vm,l)
    print("<")
    printInnerList(vm,l,true)
    println("]")
end

function atom(token)
     if (length(token) == 1) && haskey(symboltable,token)   # + - * /
         return symboltable[token]
     end
     sign = 1
     if token[1] == '+'; token = token[2:end]; end
     if token[1] == '-'
       token = token[2:end]
       sign = -1
     end
 
     #ind = findfirst(x -> x=='.', token)
     #if ind != nothing && all(isdigit,token[1:ind-1]) && all(isdigit,token[ind+1:end])
     #      f = Float32(sign*Meta.parse(token))
     #      a = box_float(f)
     #else
     if all(isdigit,token)   # Ints
           a = boxInt(sign*Meta.parse(token))
     elseif haskey(symboltable,token)
           a = symboltable[token]
     else
         error("Symbol in code")
          # a = string2symbol(token)
     end
     a
end
 
function nextchar(io)
    c = '\0'
    while true
       if eof(io); return '\0'; end
       c = read(io, Char)
       if c == ';'  # single line comment
          while true
             if eof(io); return '\0'; end
             c = read(io, Char)
             if c == '\n'; break; end
          end
       end
       if !isspace(c); break; end
    end
    return c
end
 
function read_token(io)
    token = ""
    ndots = 0  # number of dots in token
    while true
       if eof(io); break; end
       c = read(io, Char)
       if c == '.'
         ndots += 1
       end
       if ndots > 1 # can have at most 1 dot in number
          skip(io,-1)
          break
       end
       if c == '\n' || isspace(c)
          break
       elseif !(isdigit(c) || c=='+' || c=='-' || c=='.' || c=='_'
                          || c == '*' || c == '/' || isletter(c))
          #write(io,c)
          skip(io,-1)
          break
       elseif c=='`' || c == '\'' || c == '\\' || c == ';'
          #write(io,c)
          skip(io,-1)
          break
       else
         #push!(buf,c)
         token = token * c
       end
    end
    token
end
 
function read_tokens!(vm,io)
    val = NIL
    while true
      c = nextchar(io)
      if c == '\0'       # end of stream
        return val
      elseif c == ']'    # end of list
        return val
      elseif c == '['    # begin of list
        newval = read_tokens!(vm,io)
        val = cons(vm,newval, val)
      #elseif c == '\''   # escape
      #  val = cons(vm,ESC, val)
      #elseif c == '`'   # Vesc (escape value)
      #  val = cons(vm, VESC, val)
      elseif c == '\\'   # Backslash = lambda
        val = cons(vm, LAMBDA, val)
      else               # read new atom
        #write(io, c)
        skip(io,-1)
        token = read_token(io)
        newval = atom(token)
        val = cons(vm, newval, val)
      end
    end
end
 
function make_bra(vm,prog::String)
    io = IOBuffer(prog)
    read_tokens!(vm, io)
end
 
function load_file(vm, prog)
     io = open(prog)
     val = read_tokens!(vm, io)
     close(io)
     val
end

# **************************** builtins *********************************
function f_dup(vm)
    if isCell(vm.ket)
        vm.ket = cons(vm,car(vm,vm.ket), vm.ket)
    end
 end

function f_drop(vm)
    if isCell(vm.ket)
        vm.ket = cdr(vm,vm.ket)
    end
end
 
function f_swap(vm)
    if isCell2(vm,vm.ket)
        a,b,vm.ket  = pop2(vm,vm.ket)
        vm.ket = cons(vm,a,vm.ket)
        vm.ket = cons(vm,b,vm.ket)
    end
end
 
function f_rot(vm)
    if isCell(vm.ket)
        a, vm.ket = pop(vm,vm.ket)
        if isCell(vm.ket)
            b,vm.ket = pop(vm,vm.ket)
            if isCell(vm.ket)
              c,vm.ket = pop(vm,vm.ket)
              vm.ket = cons(vm,b,vm.ket)
              vm.ket = cons(vm,a,vm.ket)
              vm.ket = cons(vm,c,vm.ket)
            end
        end
    end
end
 
function f_cons(vm)
    if isCell2(vm,vm.ket)
       p1, p2, vm.ket = pop2(vm,vm.ket)
       p2 = strip_closure(vm, p2)  # cons to a closure strips the closure
                  # instead here we could cons to the quotation of the closure
       vm.ket = cons(vm,cons(vm,p1,p2),vm.ket)
    end
end
 
function f_car(vm)
    if isCell(vm.ket)
        p, vm.ket = pop(vm,vm.ket)
        p = strip_closure(vm, p)
        if isCell(p) # car a list
            head,p = pop(vm,p)
            # !!!!!!
            #vm.ket = cons(vm,p,vm.ket)  # leave rest of list on the ket
            vm.ket = cons(vm,head,vm.ket)
        else          # car a symbol
            ####if isNil(p); return; end
            val = boundvalue(vm,p)  # lookup symbol
            val = strip_closure(vm, val)
            if isCons(val)
              vm.ket = cons(vm,car(vm,val), vm.ket)
            end
        end
    end
end

function f_cdr(vm)
    if isCell(vm.ket)
        p, vm.ket = pop(vm,vm.ket)
        p = strip_closure(vm, p)
        if isCell(p)   # cdr a list
            head, p = pop(vm,p)
            vm.ket = cons(vm,p,vm.ket)
        else
            val = boundvalue(vm,p)  # look up symbole
            val = strip_closure(vm, val)
            if isCons(val)
               vm.ket = cons(vm,cdr(vm,val), vm.ket)
            else
               vm.ket = cons(vm,NIL,vm.ket) # at least leave a nill on ket
            end
        end
    end
end

 
# some math functions (we can easily extend to more..)
rnd(x) = x < 1 ? 0 : rand(1:x)
lt(x1,x2) = x1 < x2 ? 1 : 0
gt(x1,x2) = x1 > x2 ? 1 : 0
my_div(x1,x2) = x2 == 0 ? 0 : div(x1,x2)

function f_math1(vm,op)
    if isCell2(vm,vm.ket)
       n1,n2, vm.ket = pop2(vm,vm.ket)
       #if isSymb(n1)
       #  n1 = boundvalue(vm,n1)
       #end
       #if isSymb(n2)
       #  n2 = boundvalue(vm,n2)
       #end
       # Here we should check that n1 and n2 are numbers now !!!!!!
       n3 = boxInt(op(unbox8(n1), unbox8(n2)))
       vm.ket = cons(vm,n3,vm.ket)
    end
end

function f_math(vm,op)
    if isCell2(vm,vm.ket)
       n1,n2, vm.ket = pop2(vm,vm.ket)
       #if isSymb(n1)
       #  n1 = boundvalue(vm,n1)
       #end
       #if isSymb(n2)
       #  n2 = boundvalue(vm,n2)
       #end
       if isNumb(n1) && isNumb(n2)
          n3 = boxInt(op(unbox8(n1), unbox8(n2)))
          vm.ket = cons(vm, n3, vm.ket)
       elseif isCell(n1) && isCell(n2)
          n1 = strip_closure(vm,n1)
          n2 = strip_closure(vm,n2)
          c = NIL
          while isCell(n1) && isCell(n2)
             c1, n1 = pop(vm,n1)
             c2, n2 = pop(vm,n2)
             #if isSymb(c1)
             #    c1 = boundvalue(vm,c1)
             #end
             #if isSymb(c2)
             #    c2 = boundvalue(vm,c2)
             #end
             if isNumb(c1) && isNumb(c2)
                 n3 = boxInt(op(unbox8(c1), unbox8(c2)))
                 c = cons(vm, n3, c)
             end
             if vm.need_gc 
                #pushstack(vm,c)
                #pushstack(vm,n1)
                #pushstack(vm,n2)
                #gc(vm)
                throw(BracketException("need gc"))
                #n2 = popstack(vm)
                #n1 = popstack(vm)
                #c  = popstack(vm)
             end
          end
          #c,_ =reverse_list(vm,c)
          c =reverse_list(vm,c)
          vm.ket = cons(vm,c,vm.ket)
       elseif isCell(n1)
          n1 = strip_closure(vm,n1)
          c = NIL
          while isCell(n1) 
             c1, n1 = pop(vm,n1)
             #if isSymb(c1)
             #    c1 = boundvalue(vm,c1)
             #end
             if isNumb(c1) && isNumb(n2)
                 n3 = boxInt(op(unbox8(c1), unbox8(n2)))
                 c = cons(vm, n3, c)
             end
             if vm.need_gc 
                #pushstack(vm,c)
                #pushstack(vm,n1)
                #gc(vm)
                throw(BracketException("need gc"))
                #n1 = popstack(vm)
                #c  = popstack(vm)
             end
          end
          #c,_ =reverse_list(vm,c)
          c =reverse_list(vm,c)
          vm.ket = cons(vm,c,vm.ket)
       elseif isCell(n2)
          n2 = strip_closure(vm,n2)
          c = NIL
          while isCell(n2)
             c2, n2 = pop(vm,n2)
             #if isSymb(c2)
             #    c2 = boundvalue(vm,c2)
             #end
             if isNumb(n1) && isNumb(c2)
                 n3 = boxInt(op(unbox8(n1), unbox8(c2)))
                 c = cons(vm, n3, c)
             end
             if vm.need_gc 
                #pushstack(vm,c)
                #pushstack(vm,n2)
                #gc(vm)
                throw(BracketException("need gc"))
                #n2 = popstack(vm)
                #c  = popstack(vm)
             end
          end
          #c,_ =reverse_list(vm,c)
          c =reverse_list(vm,c)
          vm.ket = cons(vm,c,vm.ket)
       end
    end
end

function f_rnd(vm)
    if isCell(vm.ket)
        p, vm.ket = pop(vm,vm.ket)
        if isInt(p)
            if p >= 1
               p=boxInt(rand(1:unbox8(p)))
            else
               p=boxInt(0)
            end
        elseif isCell(p)
            p = strip_closure(vm,p)
            n=length_list(vm,p)-1
            n1=rand(0:n)
            for i=1:n1
                p = cdr(vm,p)
            end
            p = car(vm,p)
        end
        vm.ket=cons(vm,p,vm.ket)
    end
end

function f_eq(vm)
    if isCell2(vm,vm.ket)
       p1, p2, vm.ket = pop2(vm,vm.ket)
       b = isEqual(vm,p1,p2)
       # <<4 of Boolean is automatically converted to Int64
       vm.ket = cons(vm,boxInt(b),vm.ket)
    end
end

function f_if(vm)
    if isCell(vm.ket)
        b, vm.ket = pop(vm,vm.ket)
        if isCell(vm.ket)
            e1,vm.ket = pop(vm,vm.ket)
            if isCell(vm.ket)
              e2,vm.ket = pop(vm,vm.ket)
              vm.ket = istrue(b) ? cons(vm,e1,vm.ket) : cons(vm,e2,vm.ket)
            end
        end
    end
end

function f_dip(vm)
    if isCell2(vm,vm.ket)
        q1,q2,vm.ket = pop2(vm,vm.ket)
        vm.bra = cons(vm,q2,vm.bra)
        vm.bra = cons(vm,EVAL,vm.bra)
        vm.ket = cons(vm,q1,vm.ket)
    end
end

 
function f_esc(vm)
    if isCell(vm.bra)
        val, vm.bra = pop(vm,vm.bra)
        vm.ket = cons(vm,val,vm.ket)
     end
end

#=
function f_vesc(vm)
    if isCell(vm.bra)
        val, vm.bra = pop(vm,vm.bra)
        vm.ket = cons(vm,val,vm.ket)
        f_val(vm)
     end
end
=#

function f_val(vm)
    if isCell(vm.ket)
        key, vm.ket = pop(vm,vm.ket)
        if isCell(key)
           vm.ket = cons(vm,key,vm.ket)
        else
           val = boundvalue(vm,key)       # lookup symbol ..
           vm.ket = cons(vm,val,vm.ket)   # .. and place on ket
        end
     end
end

function f_typ(vm)
    if isCell(vm.ket)
       p,vm.ket = pop(vm,vm.ket)
       if isInt(p)
          t = 1
       elseif isPrim(p)
          t = 2
       #elseif isSymb(p)
       #   t=3
       elseif isCons(p)
          t=4
       elseif isClosure(p)
          t=5
       else 
          t=0
       end
       vm.ket = cons(vm,boxInt(t),vm.ket)
    end
end

function f_trace(vm)
    if isCell(vm.ket)
       p,vm.ket = pop(vm,vm.ket)
       vm.trace = unbox(p)
    end
end

function f_print(vm)
    if isCell(vm.ket)
        p,vm.ket = pop(vm,vm.ket)
        #print_bra(p,vm)
        #println(" here goes the next")
        printElem(vm,p)
        print(" ")
    end
end

function f_rec(vm)
    #anonymous recursion: replace bra of this scope by original value
    if isCell(vm.ket)
        b, vm.ket = pop(vm,vm.ket)
        if istrue(b)
            vm.bra = getstack(vm)
        end
    end
end
    
function f_lambda(vm) 
   if isCell2(vm,vm.ket)
       keys,q,vm.ket = pop2(vm,vm.ket)
       if isAtom(q) 
          q = boundvalue(vm, q)
       end
       if isCons(q) # make a closure (only of not yet)
           if isDef(keys)           # if arguments are not NIL ..
               q = cons(vm,DEF, q)  # .. push a definition on q
               q = cons(vm,keys, q)
               #if isAtom(keys) 
               #    q = cons(vm,ESC, q)
               #end
           end
          env  = newenv(vm, vm.env)
          clos = closure(vm,q,env)
        elseif isClosure(q) # new closure with keys as quotation
          env  = cdr(vm,q)
          clos = closure(vm,keys,env)
        else  # isAtom(q) # we need a quotation to do lambda
           return
        end
        vm.ket = cons(vm, clos, vm.ket) # push the new closure on ket
    end
end


function deepbind(vm, keys, val) 
# recursively bind all values of list keys to atom val
# keys must be a list, val an atom
    while isCell(keys) 
        key, keys = pop(vm,keys) 
        if isAtom(key) 
            bindkey(vm,key,val)
            if vm.need_gc 
                #pushstack(vm,keys)
                #gc(vm)
                throw(BracketException("need gc"))
                #keys = popstack(vm)
            end
        else   # key itself is a list
            #pushstack(vm,keys)
            deepbind(vm,key, val)
            #keys = popstack(vm)
        end
    end
end 

function match(vm, keys, vals) 
# bind elements from keys to elements from vals with pattern matching
# keys must be a list
    if isAtom(vals)
        deepbind(vm,keys,vals)
        return
    end                                # Q: do we need an else here??
    while isCell(keys) 
       key, keys = pop(vm,keys) 
       if isNil(keys) 
           bindkey(vm,key,vals)
       else 
           val, vals = pop(vm, vals)    # Q: do we need to check for list ??
           bindkey(vm,key,val)
       end
       if isAtom(vals) 
          deepbind(vm, keys, vals)
          return
       end
    end
end 

function f_def(vm)
   if isCell(vm.ket)
       key, vm.ket = pop(vm,vm.ket)
       if isAtom(key)
           if isCell(vm.ket) 
              val, vm.ket = pop(vm, vm.ket) 
              bindkey(vm,key,val)  #bind key to val in top env-frame
           end
       elseif isDef(key)       # binding a list of keys
           n = length_nonquoted(vm, key)
           n1 = 0    # push max n values from ket to stack
           for i = 1 : n 
               if isCell(vm.ket)
                   val, vm.ket = pop(vm,vm.ket)
                   n1 += 1   
                   pushstack(vm,val)
               else
                  break
               end
           end
           for i = 1 : n1 # make the bindings
               k, key = pop(vm, key)  # we should have enough elements in key
               #if k == VESC  
               if k == VAL  
                  k, key = pop(vm,key)   # this is interpreted as set
                  setkey(vm, k, popstack(vm))
               elseif isAtom(k) 
                  bindkey(vm, k, popstack(vm))
               else 
                  elem = popstack(vm)
                  pushstack(vm,key)  # safe key in case of gc
                  match(vm,k,elem)
                  key = popstack(vm)
               end
           end
       end
   end
end

# we remove set (replaced by backtick)
#=
function f_set(vm) 
   if isCell2(vm, vm.ket) 
       key, val, vm.ket = pop2(vm, vm.ket) 
       if isAtom(key) 
           setkey(vm,key,val)  # bind key to val in top env-frame
       end
    end
end
=#

function f_side(vm)
# perform a side effect
   e,vm.ket = pop(vm,vm.ket)
   vm.side_effect(unbox(e))
   #vm.ket = cons(vm, res, vm.ket)
end


function f_eval(vm)
    if isCell(vm.ket)
        op,vm.ket = pop(vm,vm.ket)
        if isCons(op)
            eval_cons(vm,op)
        elseif isClosure(op)
            eval_closure(vm,op)
        elseif isNil(op)
            return
        elseif isPrim(op)
              eval_prim(vm,op)
        #elseif isSymb(op)
        #      eval_symb(vm,op)
        else    # eval a number
              eval_numb(vm,op)
        end
    end
end

function eval_cons(vm, op)
    if isCell(vm.bra)
        vm.depth += 1
        pushstack(vm,vm.env)
        pushstack(vm,vm.bra)
        pushstack(vm,op)   # 2nd
        vm.env = newenv(vm,vm.env)
    else      # tail position
        replacestack(vm,op)
    end
    vm.bra = op
end

function eval_closure(vm, clos)
    op = car(vm,clos)
    env = newenv(vm, cdr(vm,clos))
    if isCell(vm.bra)
        vm.depth += 1
        pushstack(vm,vm.env)
        pushstack(vm,vm.bra)
        pushstack(vm,op)   # 2nd
    else      # tail position
        replacestack(vm,op)
    end
    vm.env = env
    vm.bra = op
end

function eval_numb(vm, n)
    val = boundvalue(vm,n)
    if isCons(val)
        eval_cons(vm,val)
    elseif isClosure(val)
        eval_closure(vm,val)
    else
        vm.ket = cons(vm,val,vm.ket)
    end
    #vm.ket = cons(vm,n,vm.ket)
end

#=
function eval_symb(vm,sym)
    val = boundvalue(vm,sym)
    if isCons(val)
        eval_cons(vm,val)
    elseif isClosure(val)
        eval_closure(vm,val)
    else
        vm.ket = cons(vm,val,vm.ket)
    end
end
=#


@inline function eval_prim(vm,x)
    #println("eval prim")
    if x == DUP
        f_dup(vm)
    elseif x == DROP
        f_drop(vm)
    elseif x == SWAP
        f_swap(vm)
    elseif x == ROT
        f_rot(vm)
    elseif x == CONS
        f_cons(vm)
    elseif x == CAR
        f_car(vm)
    elseif x == CDR
        f_cdr(vm)
    elseif x == ADD
        f_math(vm,+)
    elseif x == SUB
        f_math(vm,-)
    elseif x == MUL
        f_math(vm,*)
    elseif x == DIV
        f_math(vm,my_div)
    elseif x == LT
        f_math(vm,lt)
    elseif x == GT
        f_math(vm,gt)
    elseif x == RND
        f_rnd(vm)
    elseif x == EQ
        f_eq(vm)
    elseif x == IF
        f_if(vm)
    #elseif x == COND
    #    f_cond(vm)
    elseif x ==TYP
        f_typ(vm)
    elseif x == EVAL
        f_eval(vm)
    elseif x == DEF
        f_def(vm)
    elseif x == LAMBDA
        f_lambda(vm)
    elseif x == REC
        f_rec(vm)
    elseif x == VAL
        f_val(vm)
   # elseif x == ESC
   #     f_esc(vm)
   # elseif x == VESC
   #     f_vesc(vm)
    elseif x == DIP
        f_dip(vm)
    elseif x == SE
        f_side(vm)
    elseif x == TRACE
        f_trace(vm)
    #elseif x == PRINT
    #    f_print(vm)
    #elseif x == META
    #    f_meta(vm)
    end
    nothing

#      @match s begin
#         2 => f_dup!(vm)
#       #  3 => f_drop!(vm)
#       #  4 => f_swap!(vm)
#       #  5 => f_cons!(vm)
#       #  6 => f_car!(vm)
#       #  7 => f_cdr!(vm)
#         8 => f_add!(vm)
#       #  9 => f_lt!(vm)
#         10 => f_gt!(vm)
#       #  11 => f_eq!(vm)
#       #  12 => f_if!(vm)
#       #  13 => f_eval!(vm)
#       #  14 => f_each!(vm)
#         15 => f_whl!(vm)
#         _  => vm.ket = cons(e,vm.ket,vm)
#      end

end


function eval_bra(vm)
    #try

    #println("eval bra")
    if isAtom(vm.bra) 
        return
    end
    starting_depth = vm.depth
    pushstack(vm,vm.bra)

    while true
      if vm.trace > 0
         #println("trace ")
         printBra(vm,vm.bra)
         printKet(vm,vm.ket)
         #println("stackdepth ", vm.stackindex)
         #printElem(vm.stack[vm.stackindex],false, vm)
         #printBra(vm.ket,vm)
         #println("depth ", vm.depth)
         #if vm.trace > 1
         #    dump_env(vm.env[vm.depth],vm)
         #end
         println()
      end
 
      e, vm.bra = pop(vm,vm.bra)
      if isNil(e)
          vm.ket = cons(vm,e,vm.ket)
      elseif isPrim(e)
          eval_prim(vm,e)
      #elseif isSymb(e)
      #     eval_symb(vm,e)
      else
           vm.ket = cons(vm,e,vm.ket)
      end
 
      if vm.need_gc
         #gc(vm)
         throw(BracketException("need gc"))
         
      end
 
      if isAtom(vm.bra)   # exit scope
         if vm.depth == starting_depth
               break
         end
         vm.depth -= 1
         popstack(vm) # 2nd
         vm.bra = popstack(vm)
         vm.env = popstack(vm)
      end
    end
    vm.bra = popstack(vm)

    #catch
    #  println("error")
    #end
 end



 # questions
 #
 # def: should this leave the result on the ket?
 #
 # car quotion: keep the cdr or not?
 #
 # do we need rec?

 # break (leave quotation if false)
 # call-cc, continuations
