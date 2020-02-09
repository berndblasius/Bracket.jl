module Test

using Test

include("../src/bracket.jl")

    function test(func,result)
        vm = Vm()
        #reset!(vm)
        # load prelude
        #vm.bra = load_file("prelude.clj", vm)
        #eval_bra!(vm)
   
        vm.depth = 1  # normal programs start in depth 1
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
   # Stack shuffling
   @test test("1 2 3",     "1 2 3")  # values of bra are shifted on ket
   @test test("1 2 3; this is a comment",  "1 2 3")  # values of bra are shifted on ket
   @test test("1 [ ]",     "1 [ ]")  # values of bra are shifted on ket
   @test test("[1 2 3]",   "[1 2 3]")  # values of bra are shifted on ket
   @test test("dup 2",     "2 2")
   @test test("dup 2 3",   "2 2 3")
   @test test("dup [2 3]", "[2 3] [2 3]")
   @test test("drop 2 3",  "3")
   @test test("drop 2",    "")
   @test test("swap 2 3",  "3 2")

   @test test("x esc 4",   "x 4")      # escape a symbol
   @test test("x' 4",      "x 4")      # short notation
   #@test test("[1 2 3]'",  "[3 2 1]")  # escaping a list -> reverse
   @test test("[1 2 3]'",  "[1 2 3]")   # list and numbs: ..
   @test test("3'",        "3")         # .. just move to the ket


   # car, cdr, cons
   @test test("car [1 2 3] 10", "3 [1 2] 10")
   @test test("car [x] 4",      "x [] 4") # bring a symbol on ket       
   @test test("car [] 10", "10")          # car empty list
   @test test("car 1", "")    
   @test test("car x' def x' [1 2]",  "2")
   # car a symbol, leaves symbol intact
   @test test("car x' car x' def x' [1 2]",  "2 2")
   @test test("car x' def x' 1",  "")
   
   @test test("cdr [1 2 3] 4",   "[1 2] 4")
   @test test("cdr []",        "[]")     # cdr empty list
   @test test("cdr 1",         "[]")     # cdr atom
   @test test("cdr x' def x' [1 2 3]",  "[1 2]")           # cdr a symbol ..
   @test test("x` cdr x' def x' [1 2 3]", "[1 2 3] [1 2]") # .. leaves symbol intact
   @test test("cdr foo' def foo' bar'",  "[]")
   
   # list manipulation with cons
   @test test("cons 1 []",          "[1]")
   @test test("cons 4 [1 2 3]",     "[1 2 3 4]")
   @test test("cons [4 5] [1 2 3]", "[1 2 3 [4 5]]")
   @test test("cons car [1 2 3 4]",  "[1 2 3 4]") # identity
   @test test("cons car x' cdr x' def x' [1 2 3 4]",  "[1 2 3 4]") # identity
   # cons into variable
   #@test test("cons 4 x' def x' [1 2 3]",  "[x . 4]")     # dotted list ..
   

   # def, val
   @test test("def x' 2 10",  "10")   # x bound to 2, def consumes value on ket
   @test test("x",            "[]")   # unbound variable evaluates to NIL
   @test test("x def x' 2",   "2")  
   @test test("x y x def y' 3 def x' 2",  "2 3 2") 

   @test test("foo-bar def foo-bar' 2", "2")         # dash in symbol name
   @test test("foo1 def foo1' 2", "2")               # digit in symbol name
   @test test("foo_bar def foo_bar' 2", "2")         # underscore in symbol name
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
   @test test("foo 1 2 def foo' add'", "add 1 2")       # def a symbol that is a builtin
   @test test("foo 1 2 def foo' [add]", "3")            # this not

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
 
   @test test("a def [a`] 2",             " 2")    # set
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
   # shorter syntax, but we need golang raw strings and cannot use backqoute for val
   #test(`eval \x' [+ x 1] 10`,"11")      
   #test(`f def f' \x' [+ x 1] 10`,"11")
   # alternative use interpreted strings and "\\""
   @test test("eval \\x' [+ x 1] 10","11")      
 
   @test test("eval \\[x] [+ x 1] 10","11")      # lambda with list of arguments
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
   @test test("if 20 30 1",            "20")
   @test test("if 20 30 0",            "30")
   @test test("if 20 30 [7]",          "20") # nonempty list is true
   @test test("if 20 30 []",           "30") # empty list is false
   @test test("if 20 30 foo'",         "20") # any symbol not Nil is true
   @test test("if 20 30",              "")
   @test test("if 20",                 "20")
   @test test("if foo' bar' 1",        "foo") 

   # dip
   @test test("dip [+ 1] 5 2", "5 3")
   @test test("dip [+ 1] [+ 10] 2", "[+ 10] 3")
   @test test("dip [1 2 3] 4", "4 1 2 3")
 
   # cond
   @test test("cond [[2]]",       "2")                 
   @test test("cond [[10] [11] [0]]",   "10")
   @test test("cond [[10] [11] [1]]",   "11")
   @test test("cond [[3] [1] [eq 4] [2 drop] [lt 4 dup]] 3", "3")                 
   @test test("cond [[3] [1] [eq 4] [2 drop] [lt 4 dup]] 5", "2")                 
   @test test("cond foo' 5 def foo' [[3] [1] [eq 4] [2 drop] [lt 4 dup]]", "2")    
 
   end # testset


# ------------------------------------
   @testset "Recur and small examples" begin

   # recur
   @test test("eval [ rec gt 0 dup add 1 dup] -5", "0 -1 -2 -3 -4 -5")   #simple loop
   @test test("foo def foo' [ rec gt 0 dup add 1 dup] -5", "0 -1 -2 -3 -4 -5")   #simple loop

   @test test("eval [rec gt 0 dup add 1] -5",  "0")  # simple loop 

   # simple closure for bank account
   @test test("
   acc withdraw' 60 
   acc deposit' 100 acc withdraw' 60 acc withdraw' 60 acc deposit' 40 
   def acc' make-acc 50  
   def make-acc' [
     \\[m][ cond [ 
           [unknown']
           deposit [eq m deposit'] 
           withdraw [eq m withdraw'] ]]
    def withdraw' [
        eval if 
          [balance def [balance`] - balance]
          [insuff' drop]
          gt balance dup] 
    def deposit' [balance def [balance`] + balance]
    def balance' ]"    , "70 130 insuff 30 90")


    # Factorial
    #simple recursive
    @test test("fac 4 def fac' [cond [[* fac - swap 1 dup] [1 drop] [eq 1 dup]]]", "24")
    @test test("fac 4 def fac' \\[n] [cond [[* fac - n 1 n] 1 [eq 1 n]]]", "24")
    # tail recursive
    @test test("fac 4 def fac' \\[n] 
        [drop swap eval \\[acc cnt] [rec lt cnt n * acc cnt + cnt 1] 1 1]", "24")
 
    @test test("fac 4 def fac' \\[n] 
        [drop swap eval [rec lt cnt n * acc cnt + cnt 1 def [acc cnt]] 1 1]", "24")
 
    @test test("fac 4 def fac' [eval if [1 drop] [* fac - swap 1 dup] eq 1 dup]", "24")
 



    # Fibonacci numbers with simple recursion
    # simple recursion
    @test test("fib 6 
     def fib' \\[n] [cond [ [+ fib - n 1 fib - n 2] n [lt n 2]]]", "8") 
    @test test("fib 6 def fib' \\[n] [eval if [n] [+ fib - n 1 fib - n 2]  lt n 2]", "8")
    @test test("fib 6 def fib' [eval if [] [+ fib - swap 1 swap fib - swap 2 dup] gt 2 dup]", "8")
    
    # tail recursive
    @test test("fib 6 def fib' \\[n][              
               loop 1 1 n def loop' \\[a b n][ 
               eval if [a] [loop b + a b - n 1]
             eq n 0 ] ]", "13")
     
    @test test("fib 6 def fib' \\[max] [
        drop drop fib-iter 1 0 1 
        def fib-iter' [rec lt n max + n 1 j + i j def [n i j]] ]", "13")
  
     @test test("fib 6 def fib' \\[max] [
        drop drop fib-iter 1 0 1 
        def fib-iter' \\[n i j] [rec lt n max + n 1 j + i j]] ]", "13")
  
    # Ackermann function
    @test test("ack 3 4 def ack' \\[m n]
      [cond 
        [ [ack - m 1 ack m - n 1]
          [ack - m 1 1]  [eq 0 n]
          [+ n 1]  [eq 0 m]] ]",  "125")
  


   end # testset
   


end

tests()


end #module