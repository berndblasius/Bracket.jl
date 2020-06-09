               
eval 100 4 trace 1
def 100 \\[10] [eval if eq 1 val 10 [1] [* eval 100 - val 10 1 val 10]]

;eval 100 4 def 100 \\[10] [- val 10 1 val 10]] 
;\\[10] [+ val 10]] 
;eval [+ val 10 def [10]] 4 

