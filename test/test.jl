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
   @test test("1 [ ]",     "1 [ ]")  # values of bra are shifted on ket
   @test test("[1 2 3]",   "[1 2 3]")  # values of bra are shifted on ket
   @test test("dup 2",     "2 2")
   @test test("dup 2 3",   "2 2 3")
   @test test("dup [2 3]", "[2 3] [2 3]")

   end # testset

# ------------------------------------
   @testset "Math" begin
   # Math
   @test test("add 2 2",            "4")
   @test test("+ 2 2",             "4")

   end # testset

end

tests()

end #module