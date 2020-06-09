module Test

using Test

include("../src/bracket.jl")

function test(func,result)
    vm = Vm()
    #reset!(vm)
    # load prelude
    vm.bra = load_file(vm,"../src/prelude.clj")
    vm.ket = NIL
    eval_bra(vm)

    #vm.depth = 1  # normal programs start in depth 1
    vm.ket = NIL
    vm.bra = make_bra(vm,func)
    res, b =reverse_list(vm, make_bra(vm,result))
    eval_bra(vm)
    #println("ket is ")
    #printKet(vm,vm.ket)
    #println("res is")
    #printKet(vm,res)
    isEqual(vm,res,vm.ket)
end

function tests()

   println("Bracket Tests")

   @testset "Stack shuffling and list manipulation" begin
   
   @test test("1 2 3",     "1 2 3")  # values of bra are shifted on ket
   @test test("1 2 3; this is a comment",  "1 2 3")  # values of bra are shifted on ket
   @test test("1 [ ]",     "1 [ ]")  # values of bra are shifted on ket
   @test test("[1 2 3]",   "[1 2 3]")  # values of bra are shifted on ket
   @test test("1 [a ; comment \n [+ 2 3 ]]",  "1 [a [+ 2 3 ]]")

   @test test("x esc 4",   "x 4")      # escape a symbol
   @test test("x' 4",      "x 4")      # short notation
   #@test test("[1 2 3]'",  "[3 2 1]")  # escaping a list -> reverse
   @test test("[1 2 3]'",  "[1 2 3]")   # list and numbs: ..
   @test test("3'",        "3")         # .. just move to the ket


   # Stack shuffling
   @test test("dup 2",     "2 2")
   @test test("dup 2 3",   "2 2 3")
   @test test("dup [2 3]", "[2 3] [2 3]")
   @test test("drop 2 3",  "3")
   @test test("drop 2",    "")

   @test test("swap 2 3",  "3 2")
   @test test("swap f' g'",  "g f")
   @test test("swap [] [1 2]",  "[1 2] []")

   @test test("rot 1 2 3",  "3 1 2")
   @test test("rot 1",         "")
   @test test("rot [x y] f' 3", "3 [x y] f")


   # car, cdr, cons
   #@test test("car [1 2 3] 4", "3 [1 2] 4")
   @test test("car [1 2 3] 4", "3 4")
   #@test test("car [x]",      "x []")   # bring a symbol on ket       
   @test test("car [x]",      "x")   # bring a symbol on ket       
   @test test("car [] 10", "10")        # car empty list
   @test test("car 1", "")              # car atom
   @test test("car x' def x' [1 2]",  "2")          # car a symbol ..
   @test test("car x' car x' def x' [1 2]",  "2 2") # .. leaves the symbol intact
   @test test("car x' def x' 1",  "")
   
   @test test("cdr [1 2 3] 4",   "[1 2] 4")
   @test test("cdr []",        "[]")     # cdr empty list
   @test test("cdr 1",         "[]")     # cdr atom
   @test test("cdr x' def x' [1 2 3]",  "[1 2]")           # cdr a symbol ..
   @test test("x` cdr x' def x' [1 2 3]", "[1 2 3] [1 2]") # .. leaves symbol intact
   @test test("cdr foo' def foo' bar'",  "[]")
   
   @test test("cons 1 []",          "[1]")
   @test test("cons 4 [1 2 3]",     "[1 2 3 4]")
   @test test("cons [4 5] [1 2 3]", "[1 2 3 [4 5]]")
   #@test test("cons car [1 2 3 4]",  "[1 2 3 4]") # identity
   @test test("cons car swap cdr dup [1 2 3]", "[1 2 3]")  # identity
   @test test("cons car x' cdr x' def x' [1 2 3 4]",  "[1 2 3 4]") # identity
   # cons into variable
   #@test test("cons 4 x' def x' [1 2 3]",  "[x . 4]")     # dotted list ..
   

   # def, val
   @test test("def x' 2 10",  "10")   # x bound to 2, def consumes value on ket
   @test test("x",            "[]")   # unbound variable evaluates to NIL
   @test test("x def x' 2",   "2")  
   @test test("x y x def y' 3 def x' 2",  "2 3 2") 

   @test test("foo-bar def foo-bar' 2", "2")         # dash in symbol name
   @test test("foo_bar def foo_bar' 2", "2")         # underscore in symbol name
   @test test("foo1 def foo1' 2", "2")               # digit in symbol name
   @test test("Fo-13g def Fo-13g' 2", "2")           # digit in symbol name
   @test test("f123456789  def f123456789' 2", "2")  # symbol name with 10 characters

   @test test("val x' def x' 2",       "2")
   @test test("x vesc def x' 2",       "2")  # vesc, escape value of symbol to ket 
   @test test("x` def x' 2",           "2")  # backtick = short for vesc 
   @test test("val [1 2]",             "[1 2]")
   @test test("[1 2]`",                "[1 2]")
   @test test("x` def x' [1 2 3]",     "[1 2 3]")
   @test test("val x' def x' [1 2 3]", "[1 2 3]")
   @test test("x def x' [1 2 3]",      "1 2 3")
   @test test("val x' def x' 3 x ` def x' 2",  "3 2")

   @test test("f 2 3 def f' [add]",      "5")
   @test test("foo def foo' [add 1] 2",  "3")
   @test test("foo 1 2 def foo' add'", "add 1 2") # def a symbol that is a builtin
   @test test("foo 1 2 def foo' [add]", "3")      # [add] is quotation

   @test test("a def [a] 2",             "2")    # def: bind a list of keys
   @test test("a b def [a b] 1 2",       "1 2")    
   @test test("a b c def [a b c] 1 2 3", "1 2 3")  
   @test test("a b c def [a b c] 1 2",   "[] 1 2") 
   @test test("a b` def [a b] 1 [2 3]",  "1 [2 3]")    
   @test test("def [] 1 2",              "2")    

   @test test("a` b` def [[a b]] 2", "2 2")       # pattern matching
   @test test("a` b` c` d` def [[a b [c d]]] 2", "2 2 2 2")
   @test test("b` def [[b]] [1 2 3]", "[1 2 3]") 
   @test test("a` b` def [[a b]] [1 2 3]", "[1 2] 3") 
   @test test("a` b` c` def [[a b c]] [1 2 3]", "[1] 2 3") 
 
   @test test("a def [a`] 2",             " 2")    # backtick interpreted as set
   @test test("a b def [a` b] 2 3",       " 2 3")    
   @test test("b a b def [a` b`] 2 3",    "3 2 3")    
   @test test("f 2 3 def [f`] [add]",     "5")
   @test test("eval [x def [x`] 2]",      "2")     
 
   #test("x set x' 2",  "2")                  # set as a primary operator, obsolete now
   #test("x y x set y' 3 set x' 2",  "2 3 2")     
   #test("f 2 3 set f' [add]",     "5")
   #test("eval [x set x' 2]",  "2")     


  # numbers as symbols
  # @test test("eval 10 def 10 5",        "5")   
  # @test test("eval 10 def [10] 5",      "5")
  # @test test("eval 10 def 10 5",        "5")
  # @test test("eval 10 1 2 def 10 [add]", "3")
  # @test test("val 10 1 2 def 10 [add]", "[add] 1 2")
  # @test test("10` 1 2 def 10 [add]",    "[add] 1 2")
  # @test test("val 10 1 2 def 10 add'",  "add 1 2")

   @test test("eval [x def x' 2]",  "2") 
   @test test("eval [x def x' 2] def x' 3",  "2")          # local scope
   @test test("eval [x] def x' 2]",  "2")    # inner scope can use value defined outside     
   #@test test("eval [x] set x' 2]",  "2")    # inner scope can use value defined outside     
   @test test("eval [x] def [x`] 2]", "2")    # inner scope can use value defined outside     
   @test test("x eval [x def x' 2] x def x' 3",  "3 2 3")  # def changes only within scope
   #@test test("x eval [x set x' 2] x set x' 3",  "2 2 3")  # set changes also outside 
   @test test("x eval [x def [x`] 2] x def [x`] 3",  "2 2 3")  # set changes also outside 
   @test test("x eval [x def [x`] 2] x def x' 3",  "2 2 3")  # set changes also outside 
  
   @test test("eval [add 1] 2",          "3")
   @test test("eval [add 1 2]",          "3")
   @test test("eval [1 2 3] 4",          "1 2 3 4")
   @test test("eval [] 1",               "1") # eval empty list
   @test test("eval add' 1 2",           "3")
   @test test("eval foo' def foo' 5",    "5")
   @test test("eval foo' def foo' bar'", "bar")

  
   # lambda and lexical scoping
   @test test("lambda x' [+ x 1]","[+ x 1 def x']")
   @test test("f def f' lambda x' [+ x 1] 10","11")
   @test test("eval lambda x' [+ x 1] 10","11")
   # alternative use interpreted strings and "\\""
   @test test("eval \\x' [+ x 1] 10","11")      
 
   @test test("eval \\[x] [+ x 1] 10","11")      # lambda with list of arguments
   @test test("\\[x y] [- x y]","[- x y def [x y]]")      
   @test test("eval \\[x y] [- x y] 10 2","8")      
 
   @test test("eval foo` def foo' \\[x] [+ x 1] 10","11")      # backquote or val .. 
   @test test("eval val foo' def foo' \\[x] [+ x 1] 10","11")  # .. puts closure on ket 
   @test test("eval val val foo' def foo' \\[x] [+ x 1] 10","11")  # val on closure puts quotation on stack 
   
   @test test("eval eval [       [x def x' + 1 x`] def x' 10] def x' 1", "2")
   @test test("eval eval [\\ [] [x def x' + 1 x`] def x' 10] def x' 1", "11")
   @test test("eval swap eval dup eval [\\[] [x def [x`] + 1 x`]] def x' 10",         "12 11")
   @test test("x foo foo def foo' eval [\\[] [x def [x`] + 1 x`]] def x' 10",         "12 12 11")
   #@test test("x foo foo def foo' eval [\\[] [x set x' + 1 x`]]  def x' 10",          "12 12 11")
   @test test("x foo foo def foo' eval [\\[] [x def x' + 1 x`]]  def x' 10",          "10 11 11")
   @test test("x foo foo def foo' eval [\\[] [x def [x`] + 1 x`] def x' 10] def x' 1", "1 12 11")
   @test test("x foo foo def foo' eval [\\[] [x def x' + 1 x`]   def x' 10] def x' 1", "1 11 11")
   @test test("x foo foo def foo' [x def x' + 1 x`]   def x' 10",                     "10 11 11")
   @test test("x foo foo def foo' [x def [x`] + 1 x`] def x' 10",                     "12 12 11")
 
   @test test("100 eval [f def x' 20] def f' \\[] [x] def x' 10","100 10")
   @test test("100 eval [f def x' 20] def f'     [x] def x' 10","100 20")
   @test test("100 g def g' [f def x' 20] def f' \\[] [x] def x' 10","100 10")
   @test test(" g g def g' [f def x' 20] def f' \\[] [x] def x' 10","20 10")
   # the 2nd evaluation of g is the last command and due to tail elimination
   #  f is evaluated in the global scope
 
   # closure
   @test test("a 2 a 3 def a' [make-adder 4] a 2 a 3 def a' [make-adder 5] 
       def make-adder' [addx def x'] 
       def addx' [+ x z def z']" , "6 7 7 8")
   
   end # testset


# ------------------------------------
   @testset "Math and logic" begin
   # Math
   @test test("add 2 2",            "4")
   @test test("+ 2 2",             "4")
   @test test("sub 5 2",           "3")
   @test test("- 5 2",             "3")
   @test test("mul 2 3",           "6")
   @test test("* 2 3",             "6")
   @test test("div 9 2",           "4")
   @test test("/ 8 2",             "4")
   @test test("/ 9 2",             "4")
   @test test("/ 9 0",             "0")   # division by zero returns 0
   @test test("- * 2 4 10",        "-2")
   #@test test("+ 2.0 2.0",         "4.0")
   #@test test("+ 2.0 2",           "4.0")
   #@test test("- 2.0 2",           "0.0")
   #@test test("* 3.14 -2.0",       "-6.28")
   #@test test("/ 3.14 2.0",        "1.57")
   #@test test("/ 3.14 2",          "1.57")
   #@test test("/ 3.14 0.0",        "0.0")  # division by zero
   #@test test("/ 3.14 0",          "0.0")  # division by zero
   #@test test("/ 3 0.0",           "0.0")  # division by zero

   @test test("+ 2 x' def x' 3",     "5")
   @test test("- 5 x' def x' 2",     "3")
   @test test("- y' 2 def y' 5",     "3")
   @test test("- y' x' def y' 5 def x' 2",  "3")

   @test test("+ [2 3] 1", "[3 4]")  # add to a list
   @test test("- [2 3] 1", "[1 2]")
   @test test("+ 1 [2 3]", "[3 4]")  # add to a list
   @test test("- 4 [2 3]", "[2 1]")
   @test test("+ [10 20][1 2]", "[11 22]")
   @test test("+ [10 20][3 1 2]", "[11 22]") # list of different length
   @test test("lt 5 [4 5 6 7]" , "[0 0 1 1]")
   @test test("+ x' 2 def [x] [5 6]", "[7 8]")
   @test test("+ x' 2 def x' 3", "5")
   @test test("+ 2 x' def x' 3", "5")
   @test test("- x' y' def [x y] 5 3", "2")
   @test test("- x' y' def [x y] [5 6] 3", "[2 3]")
   @test test("- [5 6] x' def [x] 3", "[2 3]")

   @test test("lt 4 10",               "1")
   @test test("lt 10 4",               "0")
   @test test("lt 4 4",                "0")
   @test test("gt 10 4",               "1")
   @test test("gt 10 10",              "0")
   @test test("gt 4 10",               "0")
   #@test test("lt 4.0 10",             "1")
   #@test test("lt 4.0 10.0",           "1")
   #@test test("lt 4 10.0",             "1")
   #@test test("lt 5 [4 5 6 7]",        "[0 0 1 1]")
   #@test test("gt 4 [-2.0 3 4.0 5]",   "[1 1 0 0]")
   #@test test("lt [1 1.0] [0.2 0.2 0.2]",  "[0 0]")

   # eq
   @test test("eq 2 2",                "1")
   @test test("eq 2 3",                "0")
   @test test("eq [] []",              "1")
   @test test("eq [1 2 3] [1 2 3] ",   "1")
   @test test("eq [1 2 3] [1 2 4] ",   "0")
   @test test("eq 2 []",               "0")
   @test test("eq 2 x'",               "0")
   @test test("eq x' x'",              "1")
   @test test("eq y' x'",              "0")
   @test test("eq y' x' def y' x'",    "0")
   #@test test("eq 2 car [eq]",         "0")
   #@test test("eq car [eq] car [eq]",  "1")
   #@test test("eq car [car] car [eq]", "0")
   #@test test("eq [car [1 4] 2] [car [1 4] 2]", "1")

   # logic, if
   @test test("if 1 20 30",            "20")
   @test test("if 0 20 30",            "30")
   @test test("if [7] 20 30",          "20") # nonempty list is true
   @test test("if [] 20 30",           "30") # empty list is false
   @test test("if foo' 20 30",         "20") # any symbol not Nil is true
   @test test("if 20 30",              "")
   @test test("if 20",                 "")
   @test test("if 1 foo' bar'",        "foo") 

   # dip
   @test test("dip [+ 1] 5 2", "5 3")
   @test test("dip [+ 1] [+ 10] 2", "[+ 10] 3")
   @test test("dip [1 2 3] 4", "4 1 2 3")
 
   # cond
   #@test test("cond [[2]]",       "2")                 
   #@test test("cond [[10] [11] [0]]",   "10")
   #@test test("cond [[10] [11] [1]]",   "11")
   #@test test("cond [[3] [1] [eq 4] [2 drop] [lt 4 dup]] 3", "3")                 
   #@test test("cond [[3] [1] [eq 4] [2 drop] [lt 4 dup]] 5", "2")                 
   #@test test("cond foo' 5 def foo' [[3] [1] [eq 4] [2 drop] [lt 4 dup]]", "2")    

   @test test("typ 20",     "1")
   @test test("typ add'",   "2")
   @test test("typ foo'",   "3")
   @test test("typ [2 3]",  "4")
   @test test("typ []",     "2")   # == NIL
   @test test("typ \\[x][2 3]",  "5")
 
   end # testset

# ------------------------------------
   @testset "prelude" begin

   # @test test("splt [1 2 3 4]", "4 [1 2 3]")
   @test test("over 1 2", "2 1 2")
   @test test("over 1"  , "")
   @test test("over"    , "")
   @test test("rot1 1 2 3", "2 3 1")
   @test test("rot 1 2 [+ 4]", "[+ 4] 1 2")
   @test test("rot 1",         "")
   @test test("rot1 1 2 3", "2 3 1")
   @test test("drop2 10 11 12", "12")
   @test test("drop3 10 11 12", "")
   @test test("dup2 2 3", "2 3 2 3")
   @test test("dupd 2 3", "2 3 3")
   @test test("nip 2 3 4", "2 4")
   @test test("nip2 2 3 4", "2")
   @test test("swapd 2 3 4", "2 4 3")
   @test test("dupd 2 3", "2 3 3")
   @test test("dup2 2 3", "2 3 2 3")
   @test test("rot4 1 2 3 4", "4 1 2 3")
   @test test("rot14 1 2 3 4", "2 3 4 1")
   @test test("splt [1 2 3]", "3 [1 2]")
   @test test("cons splt [1 2 3]", "[1 2 3]") # identity
 
   @test test("dip [+ 1] 5 2", "5 3")
   @test test("dip [+ 1] [+ 10] 2", "[+ 10] 3")
   @test test("dip [1 2 3] 4", "4 1 2 3")
   @test test("dip2 [+ 1] 1 2 3", "1 2 4")
   @test test("keep [+] 2 3", "2 5")
   #@test test("keep2 [+] 2 3", "2 3 5")
 
   #@test test("+ 2 3 meta stop 10", "10")   // stop execution
   #@test test("empty_ket 1 2 3","")         // set ket to empty list
   #@test test("print_list [x y] def x' 2 def y' 3", "")  // print list

   @test test("curry [eq] foo'", "[eq foo']")
   @test test("eqfoo bar' eqfoo foo' def eqfoo' curry [eq] foo'", "0 1")
 
   @test test("not 5", "0")
   @test test("not 0", "1")
   @test test("and 1 0", "0")
   @test test("and 0 1", "0")
   @test test("and 2 5", "5")
   @test test("and [] 1", "[]")
   @test test("or 0 1", "1")
   @test test("or 1 0", "1")
   @test test("or 0 0", "0")
   @test test("or 2 5", "2")
   @test test("when 1 [+ 10] 20","30")
   @test test("when 0 [+ 10] 20","20")
   @test test("when1 6 [+ 10]","16")  # retains the argument of the logical decision
   @test test("when1 0 [+ 10]","")
   @test test("unless 1 [+ 10] 20","20")
   @test test("unless 0 [+ 10] 20","30")
   #@test test("reverse [1 2 3]","[3 2 1]")
   
   @test test("keep [+ 1] 2","2 3")
   @test test("keep2 [+] 2 3","2 3 5")
   @test test("bi [* dup][+ 1] 2","4 3")
   @test test("bi2 [*][+] 3 4","12 7")
   @test test("tri [- 1] [* dup][+ 1] 2","-1 4 3")
   @test test("tri2 [-][*][+] 3 4","-1 12 7")
   @test test("bistar [* dup][+ 1] 3 2","9 3")
   @test test("bi2star [*][+] 4 3 2 1","12 3")

   @test test("cleave [[* dup][+ 1]] 2","4 3")
   @test test("cleave [[- 1] [* dup][+ 1]] 2","-1 4 3")
   @test test("cleave2 [[-][*][+]] 3 4","-1 12 7")

   @test test("each [* dup] [4 3 2 1]", "16 9 4 1")
   #@test test("map [* dup] [4 3 2 1]", "[16 9 4 1]")
   @test test("map [* dup] [4 3 2 1]", "[1 4 9 16]")    # reverse still missing
   #@test test("map1 [* dup] [4 3 2 1]", "[1 4 9 16]")
   @test test("unstack [4 3 2 1]", "4 3 2 1")

   @test test("sum [2 5 10]", "17")
   @test test("prod [2 5 10]", "100")
   @test test("size [2 5 foo [3 4] 10]", "5")
   @test test("repeat 4 [+ 2] 0", "8")
   @test test("filter [gt swap 0] [2 -1 5] ", "[5 2]")  # reverse still missing
   @test test("filter [gt swap 0] [-2 -1 -10] ", "[]")  # reverse still missing
   @test test("drop drop loop [lt 0 dup - swap 1 keep [*]] 4 1", "24")


   end



# ------------------------------------
   @testset "Recur and small examples" begin

   # recur
   @test test("eval [rec gt 0 dup add 1 dup] -5", "0 -1 -2 -3 -4 -5")   #simple loop
   @test test("foo def foo' [rec gt 0 dup add 1 dup] -5", "0 -1 -2 -3 -4 -5")  #simple loop

   # simple closure for bank account
   @test test("
    acc withdraw' 60 
    acc deposit' 100 acc withdraw' 60 acc withdraw' 60 acc deposit' 40 
    def acc' make-acc 50  
    def make-acc' [ 
        \\[m][eval if eq m withdraw' 
                [withdraw] 
            [eval if eq m deposit' 
                [deposit] 
                [unknown']]] 
        def withdraw' [ 
            eval if gt balance rot  
            [balance def [balance`] - balance] 
            [insuff' drop] dup]  
        def deposit' [balance def [balance`] + balance] 
        def balance' ]"    , "70 130 insuff 30 90")


    # Factorial
    #simple recursive
    #@test test("fac 4 def fac' [cond [[* fac - swap 1 dup] [1 drop] [eq 1 dup]]]", "24")
    @test test("fac 4 def fac' [eval if eq 1 rot [1 drop] [* fac - swap 1 dup] dup]", "24")
    #@test test("fac 4 def fac' \\[n] [cond [[* fac - n 1 n] 1 [eq 1 n]]]", "24")
    @test test("fac 4 def fac' \\[n] [eval if eq 1 n 1 [* fac - n 1 n]] " , "24")

    # tail recursive
    @test test("fac 4 def fac' \\[n] 
        [drop swap eval \\[acc cnt] [rec lt cnt n * acc cnt + cnt 1] 1 1]", "24")
 
    @test test("fac 4 def fac' \\[n] 
        [drop swap eval [rec lt cnt n * acc cnt + cnt 1 def [acc cnt]] 1 1]", "24")
 
   # factorial with loop     
   @test test("drop drop loop [lt 0 dup - swap 1 keep [*]] 4 1", "24")
   @test test("drop eval [rec lt 0 dup - swap 1 keep [*]] 4 1", "24")


    # Fibonacci numbers with simple recursion
    # simple recursion
    #@test test("fib 6 
    # def fib' \\[n] [cond [ [+ fib - n 1 fib - n 2] n [lt n 2]]]", "8") 

    @test test("fib 6 
     def fib' \\[n] [eval if lt n 2 [n] [+ fib - n 1 fib - n 2]]" , "8") 

    @test test("fib 6 def fib' [eval if gt 2 rot [] [+ fib - swap 1 swap fib - swap 2 dup] dup]", "8")

    # tail recursive
    @test test("fib 6 def fib' \\[n][              
               loop 1 1 n def loop' \\[a b n][ 
               eval if rot [a] [loop b + a b - n 1] 
             eq n 0 ] ]", "13")
     
    @test test("fib 6 def fib' \\[max] [
        drop drop fib-iter 1 0 1 
        def fib-iter' [rec lt n max + n 1 j + i j def [n i j]] ]", "13")
  
     @test test("fib 6 def fib' \\[max] [ 
        drop drop fib-iter 1 0 1 
        def fib-iter' \\[n i j] [rec lt n max + n 1 j + i j]] ]", "13")
  
    # Ackermann function
    #@test test("ack 3 4 def ack' \\[m n]
    #  [cond 
    #    [ [ack - m 1 ack m - n 1]
    #      [ack - m 1 1]  [eq 0 n]
    #      [+ n 1]  [eq 0 m]] ]",  "125")
  
    @test test("ack 3 4 def ack' \\[m n]
     [eval if eq 0 m 
        [+ n 1] 
     [eval if eq 0 n 
         [ack - m 1 1] 
     [ack - m 1 ack m - n 1] ]] ", "125")


   end # testset


end

tests()


end #module