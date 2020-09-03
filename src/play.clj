;add -1 2

  ;   eval [ rec gt 0 dup add 1 ] -500000000
;    eval [ rec gt 0 dup add 1 ] -500000000

;"  # 5e8  # 16-17.6 sec Bracket
;"  # 5e8  # 15-16 sec Bracket_point



;    ack 3 10 def ack' \\[m n]
;     [eval if eq 0 m 
;        [+ n 1] 
;     [eval if eq 0 n 
;         [ack - m 1 1] 
;     [ack - m 1 ack m - n 1] ]] 
; Bracket_point 7.8-8 sec
; Bracket       9.8-10 sec    


add1 add1 add1 
def add1' eval [\[][x def [x`] + x 1] def x'] 0

;a 5 a 6 
;def a' f 1    
;def f' [ \[y][+ x y] def x']

;","5 6 7")


;foo foo def foo' [+ 1] 2
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
