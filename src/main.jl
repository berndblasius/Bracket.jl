module Bracket

#include("bracket.jl")
include("bracket_point.jl")


function main(prog)
    println("Start Bracket")
    vm = Vm()

    #load prelude
    #vm.bra = load_file(vm,"prelude.clj")
    #eval_bra(vm)

    vm.bra = load_file(vm,prog)
    println("File loaded")
    printBra(vm, vm.bra)
    vm.ket = NIL

    @time eval_bra(vm)

    printKet(vm, vm.ket)
    println("done")
end

function main()
    println("Start Bracket")
    vm = Vm()
    #reset!(vm)
    #vm.env = cons(vm,NIL,NIL)
    #load prelude
    vm.bra = load_file(vm,"prelude.clj")
    #vm.ket = NIL
    eval_bra(vm)


    # repl(vm)    # repl should run in depth 0
    #vm.depth = 1  # normal programs start in depth 1


    #vm.ket = NIL

    #str = "1 3 foo [bar 4 dup]"
    #str = "eval [ rec gt 0 dup add 1 print dup] -20 trace 0"
    #str = "eval [ rec gt 0 dup add 1 ] -50000000"  # 5e7  # 2.8 sec
    #str = "eval [ rec gt 0 dup add 1 ] -500000000"  # 5e8  # 16-17.6sec

     # ***************************

    str = "ack 3 10 def ack' \\[m n]
     [eval if eq 0 m 
        [+ n 1] 
     [eval if eq 0 n 
         [ack - m 1 1] 
     [ack - m 1 ack m - n 1] ]] " # "125")

     # bench
     # ack 3 4 --> 0.028
     # ack 3 5 --> 0.038
     # ack 3 6 --> 0.086
     # ack 3 7 --> 0.26
     # ack 3 8 --> 0.92
     # ack 3 9 --> 2.87
     # ack 3 10 --> 10.7

     # ***************************

    #str = " x eval [x def x' 2] x def x' 1 trace 1"
    #str = "foo def x' 3 def foo' [x` def x'] 4"
    #str = "rnd 3 rnd 3 rnd 3 rnd 3 rnd 3 rnd 3 rnd 3 rnd 3"
    #str = "rnd [1 2 3] rnd [1 2 3] rnd [1 2 3] rnd [1 2 3] rnd [1 2 3] rnd [1 2 3] rnd [1 2 3] "
    #= str = "ack 3 10 def ack' \\[m n]
      [cond 
        [ [ack - m 1 ack m - n 1]
          [ack - m 1 1]  [eq 0 n]
          [+ n 1]  [eq 0 m]] ]"
    =#

    #=str = "ack 3 11 def ack' \\[m n]
        [eval if
            [+ n 1]  
            [ eval if 
                [ack - m 1 1]  
                [ack - m 1 ack m - n 1]
                eq 0 n
            ]
            eq 0 m
        ]"
    =#

    #str = "eval [rec gt 0 dup add 1 dup] -5"
    #str  = "typ 20 trace 1"

    vm.bra = make_bra(vm, str)
    
    #vm.bra = cons(vm, boxInt(3), cons(vm,boxInt(4), boxInt(5)))
    #vm.bra = cons(vm, boxInt(2), vm.bra)
    #vm.bra = cons(vm, boxInt(3), cons(vm,DEF, NIL))
    #vm.bra = cons(vm, VAL, cons(vm,DEF, boxPrim(2)))
    #vm.bra = load_file("test.clj",vm)

    printBra(vm, vm.bra)
    #vm.bra = cons(box_int(1), NIL, vm)
    vm.ket = NIL

    @time eval_bra(vm)

    printKet(vm, vm.ket)
    println("done")


end
 

@time main("play.clj")

function dummy()
  println("start dummy")
  vm = Vm()
  n = boxInt(5)
  println(n)
  q = new_cons(vm,n,NIL)
  println(car(q))

end


#dummy()

end # end module
