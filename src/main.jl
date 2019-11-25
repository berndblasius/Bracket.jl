module Bracket

include("bracket.jl")


function main()
    println("Start Bracket")
    vm = Vm()
    #vm.env = cons(vm,NIL,NIL)
    #load prelude
    #vm.bra = load_file("prelude.clj", vm)
    #vm.ket = NIL
    #eval_bra!(vm)


    # repl(vm)    # repl should run in depth 0
    vm.depth = 1  # normal programs start in depth 1


    vm.ket = NIL

    str = "1 3 foo [bar 4 dup]"
    str = "eval [ rec gt 0 dup add 1 print dup] -20 trace 0"
    #str = "eval [ rec gt 0 dup add 1 ] -50000000"  # 5e7  # 2.8 sec
    #str = "eval [ rec gt 0 dup add 1 ] -500000000"  # 5e8  # 12.6sec

    str = "cons 4 x'"

    vm.bra = make_bra(vm, str)
    
    #vm.bra = cons(vm, boxInt(3), cons(vm,boxInt(4), boxInt(5)))
    #vm.bra = cons(vm, boxInt(2), vm.bra)
    #vm.bra = cons(vm, boxInt(3), cons(vm,DEF, NIL))
    #vm.bra = cons(vm, VAL, cons(vm,DEF, boxPrim(2)))
    #vm.bra = load_file("test.clj",vm)

    printBra(vm, vm.bra)
    #vm.bra = cons(box_int(1), NIL, vm)
    vm.ket = NIL;

    eval_bra!(vm)

    printKet(vm, vm.ket)
    println("done")


end
 

@time main()



end # end module