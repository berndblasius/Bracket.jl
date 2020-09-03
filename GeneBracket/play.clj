   ;se 3 se 2 se 1 

    ;eval [ rec gt 0 dup add 1 ] -500000000
    eval [ rec gt 0 dup add 1 ] -50



; Ackermann function
   ;  eval 100 4 4 def 100 \\[10 11]
   ;  [eval if eq 0 val 10 
   ;     [+ val 11 1] 
   ;  [eval if eq 0 val 11 
   ;      [eval 100 - val 10 1 1] 
   ;  [eval 100 - val 10 1 eval 100 val 10 - val 11 1] ]] 
  ;", "125")

   ; show-bal 
   ; eval deposit1 acc' 3    
   ; def deposit1' \\[ac]   
   ;   [\\[def [bal`] + bal] ac`] 
   ; show-bal deposit 5      
   ; def deposit' \\[def [bal`] + bal] acc'   
   ; show-bal                      
   ; def show-bal' \\[bal] acc'   
   ; acc                      
   ; def acc' make-acc 10     
   ; def make-acc' [          
   ;    \\[][do-stuff']       
   ;    def bal'              
   ; ]", "18 15 10 do-stuff")    

   ; eval 103 
  ;  eval eval 106 val 102 3    
  ;  def 106 \[108]   
  ;    [\[def [100 val] + val 100] val 108] 
  ;  eval 103 eval 105 5      
  ;  def 105 \[def [100 val] + val 100] val 102   
  ;  eval 103                      
  ;  def 103 \[val 100] val 102   
  ;  eval 102                      
  ;  def 102 eval 101 10     
  ;  def 101 [          
  ;     \[][107]       
  ;     def 100              
  ;  ]


;e 103 e e 106 v 102 3 d 106 l[108] [l[d [100 v] + v 100] 
;v 108] e 103 e 105 5 d 105 l[d [100 v] + v 100] v 102   
;e 103 d 103 l[v 100] v 102   
;e 102 d 102 e 101 10 d 101 [l[][107] d 100]


; "18 15 10 107")    


;eval 106 103 60 
;    eval 106 102 100 eval 106 103 60 eval 106 103 60 eval 106 102 40 
;    def 106 eval 105 50  
;    def 105 [ 
;        \[10][eval if eq val 10 103 
;                [eval 103] 
;            [eval if eq val 10 102 
;                [eval 102] 
;                [104]]] 
;        def 103 [ 
;            eval if gt val 100 rot  
;            [val 100 def [100 val] - val 100] 
;            [101 drop] dup]  
;        def 102 [val 100 def [100 val] + val 100] 
;        def 100 ]    
;                 

  ;, "70 130 101 30 90")


;eval + 4 1 def 5 3

;eval 100 4 trace 1
;def 100 \\[10] [eval if eq 1 val 10 [1] [* eval 100 - val 10 1 val 10]]

;eval 100 4 def 100 \\[10] [- val 10 1 val 10]] 
;\\[10] [+ val 10]] 
;eval [+ val 10 def [10]] 4 

