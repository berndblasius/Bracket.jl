# new design of bracket for julia
# closely follow the go-branch

const CELLS     = 100*1024*1024
const GCMARGIN  = CELLS - 24
const STACKSIZE = 1024*1024

# Tagbits (from right  to left)
# three bits are used (from Bit 1 to Bit 3), Bit 4 is free and can be used for gc for tree traversals
# local pointer, global pointer, Int, Prim, Symbol, Float
# global pointers not used yet, will become meta gene pool of gene bracket
# Bit 1 = 0 ->  Cons
#    Bit 2 = 0 --> pointer to cell on local heap
#    Bit 2 = 1 --> pointer to cell on global heap  (not used in the moment)
#    Bit 3 = 0 --> list (or quotation)
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
const tagCons    = 5  # bits 101
const tagClosure = 4  # bits 100
const tagPrim    = 5  # bits 101
const tagSymb    = 1  # bits 001
const tagNumb    = 2  # bits 010
const tagInt     = 3  # bits 011
const tagFloat   = 7  # bits 111

@inline boxCell(x) = x<<4    # create a new local cons
@inline boxClosure(x) = x<<4 | tagClosure   # create a new local closure
#func boxGlobal(x) = x<<4 | tagGlobal
@inline boxPrim(x) = x<<4 | tagPrim  # create a local primitive
@inline boxSymb(x) = x<<4 | tagSymb
@inline boxInt(x)  = x<<4 | tagInt

# floats not yet interpreted
#func box_float(x Int) Int { Int(reinterpret(Int32,x)) << 32 | tagFloat
#func unbox_float(x value) float = reinterpret(Float32, Int32(x>>32))

@inline unbox(x) = x>>4   # remove all tags
# in contrast to C, here the pointer is
# just the heap index, that is, a number
#func ptr(x value) int    {return int(x)>>4}   

@inline isInt(x)    = x & tagType == tagInt
@inline isFloat(x)  = x & tagType == tagFloat
@inline isPrim(x)   = x & tagType == tagPrim
@inline isSymb(x)   = x & tagType == tagSymb
@inline isLocal(x)  = x & tagGlobal == 0
@inline isGlobal(x) = x & tagGlobal == tagGlobal
@inline isCons(x)   = x & tagCons == 0
@inline isClosure(x) = x & tagCons == tagClosure
@inline isAtom(x)   = !isCons(x)
@inline isNumb(x)   = x & tagNumb == tagNumb
@inline isAbstractSymb(x) = x & tagNumb == 0  # symbol or primitive

@inline isNil(x) = x == NIL
@inline isDef(x) = x != NIL
isCons2(vm,x) = isCons(x) && isCons(cdr(vm,x))
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
const COND = newprimitive()
const EVAL = newprimitive()
const DIP  = newprimitive()
const VAL  = newprimitive()
const REC  = newprimitive()
const DEF  = newprimitive()
const LAMBDA = newprimitive()
const ESC   = newprimitive()
const VESC  = newprimitive()
const META  = newprimitive()
const TOR   = newprimitive()
const RTO   = newprimitive()
const RIS   = newprimitive()
const TRACE = newprimitive()
const PRINT = newprimitive()

const UNBOUND = 0


const symboltable = Dict(
   "dup"=>DUP, "drop"=>DROP, "swap"=>SWAP, "cons"=>CONS, "car"=>CAR, "cdr"=>CDR,
   "add"=>ADD, "sub"=>SUB, "mul"=>MUL, "div"=>DIV, "+"=>ADD, "-"=>SUB,
   "*"=>MUL, "/"=>DIV, "lt"=>LT, "gt"=>GT, "eq"=>EQ,
   "rnd" =>RND, "if"=>IF, "cond"=>COND, "eval"=>EVAL, "val"=>VAL,
   "rec"=>REC, "def"=>DEF, "lambda"=>LAMBDA, "\\"=>LAMBDA,
   "esc"=>ESC, "'"=>ESC, "`"=>VESC, "toR"=> TOR, "Rto"=>RTO, "Ris"=>RIS, 
   "dip"=>DIP, "meta"=>META, "trace"=>TRACE,
   "print"=>PRINT)

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
    next     :: Int    # index into current cell in heap
    bra      :: Int    # global program stack
    ket      :: Int    # global data stack
    aux      :: Int    # auxillary global stack
    env      :: Int    # environment
    stack    :: Vector{Int}
    stackindex :: Int
    stats    :: Stats # some statistics about the running program
    trace    :: Int   # trace mode e: 0=no trace, 1=trace non-verbose, 3=verbose
    depth    :: Int   # current recursion depth
    need_gc  :: Bool  # flag to indicate that heap space gets rare
end

function Vm()
    arena   = Vector{Cell}(undef,CELLS)
    brena   = Vector{Cell}(undef,CELLS)
    next    = 0
    stack   = Vector{Int}(undef,STACKSIZE)
    stats = Stats(0,0,0,0)
    vm = Vm(arena,brena,next,NIL,NIL,NIL,NIL,stack,0,stats,0,0,false)
    vm.env  = cons(vm,NIL,NIL)
    vm
end

function reset!(vm)
    vm.next = 0
    vm.stats = Stats{0,0,0,0}
    vm.bra = NIL
    vm.ket = NIL
    vm.aux = NIL
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
    if !isCons(c)
        return c
    end
    indv = unbox(c)
    @inbounds ah = vm.brena[indv]
    if ah.car == UNBOUND
        return ah.cdr
    end
    ind = vm.next
    bc = boxCell(ind)
    @inbounds begin
         vm.arena[ind]   = vm.brena[indv]
         vm.brena[indv] = Cell(UNBOUND, bc)
    end
    vm.next += 1
    bc
end
 
function gc!(vm)
    println("starting gc ************************************************")
 
    (vm.brena, vm.arena) = (vm.arena, vm.brena)
    finger =  1
    vm.next = 1
 
    # scan root of every live object
    vm.bra = relocate!(vm, vm.bra)
    vm.ket = relocate!(vm, vm.ket)
    vm.aux = relocate!(vm, vm.aux)
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
 
    if vm.next >= GCMARGIN
        error("Bracket GC, heap too small")
    end
    vm.need_gc = false
    #println("GC finished")
end
 
# **********************
 
@inline function cons(vm,pcar, pcdr)
    vm.next += 1
    if vm.next > GCMARGIN
      vm.need_gc = true
    end
    @inbounds vm.arena[vm.next] = Cell(pcar,pcdr)
    boxCell(vm.next)  # return a boxed index
end
  
@inline @inbounds car(vm,c) = vm.arena[unbox(c)].car
@inline @inbounds cdr(vm,c) = vm.arena[unbox(c)].cdr
caar(c,vm) = car(car(c,vm),vm)
cadr(c,vm) = car(cdr(c,vm),vm)
cddr(c,vm) = cdr(cdr(c,vm),vm)
pop(vm,list) = (car(vm,list), cdr(vm,list))   # unsafe
pop2(vm,list) = (car(vm,list), car(vm,cdr(vm,list)), cdr(vm,cdr(vm,list)))  # unsafe
#popsafe(vm,elem) = isCons(elem) ? pop(vm,elem) : (elem,elem)

function length_list(vm,l)
    n=0
    while isCons(l)
        n += 1
        l = cdr(vm,l)
    end
    n
 end
 
# reverse a list
# if list contained a dotted pair, reverse returns normal list
# but also a flag 
function reverse_list(vm,list)
    l = NIL
    while isCons(list)
      p, list = pop(vm,list)
      l = cons(vm,p,l)
    end
    if isDef(list)   # list contained a dotted pair 
      l = cons(vm,list,l)
      return l, true
    else
      return l, false  # list did not contain a dotted pair
    end
end

function reverse_list1(vm,list)
    l = NIL
    while isDef(list)
      e, list = pop(vm,list)
      l = cons(vm,e,l)
    end
    if isDef(list)   # list contained a dotted pair 
      l = cons(vm,list,l)
      return l,true
    else
      return l,false  # list did not contain a dotted pair
    end
end
 
function isEqual(vm,p1,p2)
    if isCons(p1) && isCons(p2)
        isEqual(vm,car(vm,p1),car(vm,p2)) && 
        isEqual(vm,cdr(vm,p1),cdr(vm,p2))
    else
        p1 == p2
    end
end
 
istrue(l) = isDef(l) ?  (unbox(l) != 0) : false
 
@inline istrue(l) = l != NIL && unbox(l) != 0
@inline isfalse(l) = l == NIL || unbox(l) == 0

# stack functions #############
@inline function pushstack!(vm, x)
    vm.stackindex += 1
    if vm.stackindex == STACKSIZE
        error("VM stack overflow")
    end
    @inbounds vm.stack[vm.stackindex] = x
end

@inline function popstack!(vm)
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

@inline function replacestack!(vm, x)
    @inbounds vm.stack[vm.stackindex] = x
    nothing
end

# creates new empty environment
@inline newenv(vm,env) = cons(vm, NIL, env)


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
   symb(x)
end

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

function printElem(vm, q)
    if isInt(q)
        print(unbox(q))
    #elseif isFloat(q)
    #    print(unbox_float(q))
    elseif isNil(q)
         print("[]")
    elseif isPrim(q)
         print(first(keys(filter(p->p.second == q , symboltable))))
    elseif isSymb(q)
         print(symbol2string(q))
    else
        printList(vm,q)
    end
end

function printInnerList(vm, list, invert)
    isdotted = false
    if isCons(list)
       if invert 
          list, isdotted = reverse_list(vm,list) 
       end
       p, list = pop(vm,list) 
       printElem(vm,p)
       if isdotted   # dotted list that was reversed
          print(" .")
       end
       while isCons(list)
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
 
     ind = findfirst(x -> x=='.', token)
     #if ind != nothing && all(isdigit,token[1:ind-1]) && all(isdigit,token[ind+1:end])
     #      f = Float32(sign*Meta.parse(token))
     #      a = box_float(f)
     #else
     if all(isdigit,token)   # Ints
           a = boxInt(sign*Meta.parse(token))
     elseif haskey(symboltable,token)
           a = symboltable[token]
     else
           a = string2symbol(token)
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
       elseif !(isdigit(c) || c=='+' || c=='-' || c=='.'
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
      elseif c == '\''   # escape
        val = cons(vm,ESC, val)
      elseif c == '`'   # Asc (escape value)
        val = cons(vm, VESC, val)
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
# ************ io   ****************************************************+

# **************************** builtins *********************************
function f_dup!(vm)
    if isCons(vm.ket)
        vm.ket = cons(vm,car(vm,vm.ket), vm.ket)
    end
 end
 
# some math functions (we can easily extend to more..)
rnd(x) = x < 1 ? 0 : rand(1:x)
lt(x1,x2) = x1 < x2 ? 1 : 0
gt(x1,x2) = x1 > x2 ? 1 : 0
my_div(x1,x2) = x2 == 0 ? 0 : div(x1,x2)

function f_math!(vm,op)
    if isCons2(vm,vm.ket)
       n1,n2, vm.ket = pop2(vm,vm.ket)
       #if isSymb(n1)
       #  n1 = boundvalue(n1,vm)
       #end
       #if isSymb(n2)
       #  n2 = boundvalue(n2,vm)
       #end
 
       n3 = boxInt(op(unbox(n1), unbox(n2)))
       vm.ket = cons(vm,n3,vm.ket)
    end
end

function f_rec!(vm)
    #anonymous recursion: replace bra of this scope by original value
    if isCons(vm.ket)
        b, vm.ket = pop(vm,vm.ket)
        if istrue(b)
            vm.bra = getstack(vm)
        end
    end
    nothing
end
    

function f_eval!(vm)
    if isCons(vm.ket)
        op,vm.ket = pop(vm,vm.ket)
        if isCons(op)
            eval_cons!(vm,op)
        elseif isNil(op)
            return
        elseif isPrim(op)
              eval_prim!(vm,op)
        #elseif isSymb(op)
        #      eval_symb!(op,vm)
        #else    # eval a number
        #    eval_numb!(op,vm)
        end
    end
   nothing
end

function eval_cons!(vm, op)
    if isCons(vm.bra)
        vm.depth += 1
        pushstack!(vm,vm.env)
        pushstack!(vm,vm.bra)
        pushstack!(vm,op)   # 2nd
        vm.env = newenv(vm.env,vm)
    else      # tail position
        replacestack!(vm,op)
    end
    vm.bra = op
    nothing
end


@inline function eval_prim!(vm,x)
    #println("eval prim")
    if x == DUP
        f_dup!(vm)
    #elseif x == DROP
    #    f_drop!(vm)
    #elseif x == SWAP
    #    f_swap!(vm)
    #elseif x == CONS
    #    f_cons!(vm)
    #elseif x == CAR
    #    f_car!(vm)
    #elseif x == CDR
    #    f_cdr!(vm)
    elseif x == ADD
        f_math!(vm,+)
    #elseif x == SUB
    #    f_math!(vm,-)
    #elseif x == MUL
    #    f_math!(vm,*)
    #elseif x == DIV
    #    f_math!(vm,my_div)
    #elseif x == LT
    #    f_math!(vm,lt)
    elseif x ==GT
        f_math!(vm,gt)
    #elseif x ==RND
    #    f_rnd!(vm)
    #elseif x ==EQ
    #    f_eq!(vm)
    #elseif x ==IF
    #    f_if!(vm)
    #elseif x ==TYP
    #    f_typ!(vm)
    elseif x ==EVAL
        f_eval!(vm)
    #elseif x == DEF
    #    f_def!(vm)
    elseif x == REC
        f_rec!(vm)
    #elseif x == VAL
    #    f_val!(vm)
    #elseif x == ESC
    #    f_esc!(vm)
    #elseif x == ASC
    #    f_asc!(vm)
    #elseif x == RTO
    #    f_rto!(vm)
    #elseif x == TOR
    #    f_tor!(vm)
    #elseif x == RIS
    #    f_ris!(vm)
    #elseif x == DIP
    #    f_dip!(vm)
    #elseif x == TRACE
    #    f_trace!(vm)
    #elseif x == PRINT
    #    f_print!(vm)
    #elseif x == META
    #    f_meta!(vm)
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


function eval_bra!(vm)
    #println("eval bra")
    if isAtom(vm.bra) 
        return
    end
    starting_depth = vm.depth
    pushstack!(vm,vm.bra)
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
          eval_prim!(vm,e)
      #elseif isSymb(e)
      #     eval_symb!(vm,e)
      else
           vm.ket = cons(vm,e,vm.ket)
      end
 
      if vm.need_gc
         gc!(vm)
      end
 
      if isAtom(vm.bra)   # exit scope
         if vm.depth == starting_depth
               break
         end
         vm.depth -= 1
         popstack!(vm) # 2nd
         vm.bra = popstack!(vm)
         vm.env = popstack!(vm)
      end
    end
    vm.bra = popstack!(vm)
 end