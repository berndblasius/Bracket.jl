eval 106 103 60 
    eval 106 102 100 eval 106 103 60 eval 106 103 60 eval 106 102 40 
    def 106 eval 105 50  
    def 105 [ 
        \[10][eval if eq val 10 103 
                [eval 103] 
            [eval if eq val 10 102 
                [eval 102] 
                [104]]] 
        def 103 [ 
            eval if gt val 100 rot  
            [val 100 def [100 val] - val 100] 
            [101 drop] dup]  
        def 102 [val 100 def [100 val] + val 100] 
        def 100 ]    
                 

  ;, "70 130 101 30 90")


;eval + 4 1 def 5 3

;eval 100 4 trace 1
;def 100 \\[10] [eval if eq 1 val 10 [1] [* eval 100 - val 10 1 val 10]]

;eval 100 4 def 100 \\[10] [- val 10 1 val 10]] 
;\\[10] [+ val 10]] 
;eval [+ val 10 def [10]] 4 

