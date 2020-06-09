
foo foo def foo' [+ 1] 2
;drop drop loop [lt 0 dup - swap 1 keep [*]] 4 1 trace 1
; drop eval [rec lt 0 dup - swap 1 keep [*]] 4 1 trace 1

;[rec swap keep [eval]] fac
;rec swap fac eval fac

;[* dup] [1 2 3]
;[1 2 3] [* dup]
;[1 2 3] [* dup] []
;3 [1 2] [* dup] []
;[* dup] [1 2] [* dup] 3 []
;[* dup] [1 2]  [9]
;[1 2] [* dup]  [9]

 
;def map' [
;[]
;]

;def map' [
;  drop drop drop eval if rot [
;     rec dup swap dip2 [cons eval] over rot1 car
;  ]
;  [drop drop drop] dup rot rot [] swap
;]

;rot4 1 2 3 4 trace 1
;dip [1 2 3] 4
;map [+ 1] [4 5 6] trace 1

;myor1 [print 10] temp def temp' 3
;myor [print 10] temp def temp' 3
;myor1 0 temp def temp' 3

;def myor1' \[x y] 
;   [eval if temp` [temp`] [y`]
;    def temp' x`] 

;def myor' \[x y] 
;   [eval if x` [x`] [y`]] 

; ****************************
; test macro problem

;whl [gt cnt 0] 
;   [print cnt` def [cnt`] - cnt` 1]

;whl [gt cnt 0] 
;   [print cnt` def [loop`] oops' 
;               def [cnt`] - cnt`1]

;trace 1

; this has a problem
;wh [gt cnt 0] 
;   [print cnt` def [loop`] oops' 
;               def [cnt`] - cnt`1]

; this has no problem
;wh [gt cnt 0] foo'
;def foo' \[]  [print cnt` def [loop`] oops' 
;               def [cnt`] - cnt` 1]
            
;            trace 0

; this works
;wh [gt cnt 0] 
;   [print cnt` def [cnt`] - cnt` 1]

;def cnt' 10

;def wh' \[condition body]
;  [loop
;   def loop' 
;     [eval if condition [loop eval body`] [] ]]


; (while (< counter 10)
;      (display counter)
;      (newline)
;      (set! loop 'oops))


; (while (> counter 0)
;     (display counter)
;     (newline)
;     (set! counter (- counter 1)))

; (define counter 10)

; (defmacro (while condition . body)
;   `(let loop ()
;      (cond (,condition
; 	    (begin . ,body)
; 	    (loop)))))