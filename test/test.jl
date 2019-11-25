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
        eval_bra!(vm)
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

   @test test("car [1 2 3] 10", "3 [1 2] 10")
   @test test("car [x] 4",      "x [] 4") # bring a symbol on ket       
   @test test("car [] 10", "10")          # car empty list
   @test test("car 1", "")    
   @test test("car x' def x' [1 2]",  "2")
   # car a symbol, leaves symbol intact
   @test test("car x' car x' def x' [1 2]",  "2 2")
   @test test("car x' def x' 1",  "")
   
   @test test("cdr [1 2 3] 4",   "[1 2] 4")
   @test test("cdr []",        "[]")
   @test test("cdr 1",         "[]")
   @test test("cdr x' def x' [1 2 3]",  "[1 2]")
   @test test("x` cdr x' def x' [1 2 3]",  "[1 2 3] [1 2]")
   @test test("cdr foo' def foo' bar'",  "[]")
   
   # list manipulation with cons
   @test test("cons 1 []",          "[1]")
   @test test("cons 4 [1 2 3]",     "[1 2 3 4]")
   @test test("cons [4 5] [1 2 3]", "[1 2 3 [4 5]]")
   @test test("cons car [1 2 3 4]",  "[1 2 3 4]") # identity
   @test test("cons car x' cdr x' def x' [1 2 3 4]",  "[1 2 3 4]") # identity
   # cons into variable
   #@test test("cons 4 x' def x' [1 2 3]",  "[x . 4]")     # dotted list ..
   
   # dict, val, def
   @test test("def x' 2 10",        "10")
   @test test("x",      "[]")   # undefined variable
  # @test test("def [x] 2 10",        "10")
   @test test("x def x' 2",           "2")  
   @test test("x y x def y' 3 def x' 2",  "2 3 2") 

   @test test("x` def x' 2",           "2")  # vesc
   @test test("val x' def x' 2",       "2")
   @test test("val [1 2]",             "[1 2]")
   @test test("[1 2]`",                "[1 2]")
   @test test("x` def x' [1 2 3]",     "[1 2 3]")
   @test test("val x' def x' [1 2 3]", "[1 2 3]")
   @test test("x def x' [1 2 3]",      "1 2 3")
   #@test test("val x' def [x] 2 10", "2 10")
   @test test("val x' def x' 3 x ` def x' 2",  "3 2")
  # @test test("x` def [x] [1 2 3]",      "[1 2 3]")

  # @test test("x def x' [[1 2 3]]",      "[1 2 3]")

   @test test("f 2 3 def f' [add]",      "5")
   @test test("foo def foo' [add 1] 2",  "3")

  # @test test("eval 10 def 10 5",        "5")   # numbers as symbol
  # @test test("eval 10 def [10] 5",      "5")
  # @test test("eval 10 def 10 5",        "5")
  # @test test("eval 10 1 2 def 10 [add]", "3")
  # @test test("val 10 1 2 def 10 [add]", "[add] 1 2")
  # @test test("10` 1 2 def 10 [add]",    "[add] 1 2")
  # @test test("val 10 1 2 def 10 add'",  "add 1 2")

   @test test("eval [add 1] 2",          "3")
   @test test("eval [add 1 2]",          "3")
   @test test("eval [1 2 3] 4",          "1 2 3 4")
   @test test("eval [] 1",               "1") # eval empty list
   @test test("eval add' 1 2",           "3")
   @test test("eval foo' def foo' 5",    "5")
   @test test("eval foo' def foo' bar'", "bar")
  # @test test("eval foo' 1 2 def foo' [add]", "3")      # this creates a closure
  # @test test("eval foo' 1 2 def foo' add'", "add 1 2") # this not
   #@test test("foo 1 2 def foo' add'", "add 1 2")       # def a symbol that is a builtin
   #@test test("foo 1 2 def foo' [add]", "3")            # this not



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

   @test test("lt 4 10",               "1")
   @test test("lt 10 4",               "0")
   @test test("lt 4 4",                "0")
   @test test("gt 10 4",               "1")
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

   end # testset

# ------------------------------------
   @testset "Recur and loops" begin

   @test test("eval [rec gt 0 dup add 1] -5",  "0")  # simple loop 

   end # testset
   


end

tests()

end #module