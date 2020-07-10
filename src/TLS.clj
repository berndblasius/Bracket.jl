; Functions from The Little Schemer ...
; ... and translation to Bracket

; *************************************************
; subst: substitute all occurrences

;substar orange' banana' [ [brandy banana]
;      [bread]
;      [sherbet [[banana] cream] [[ice banana]]]]
      ; => [[brandy orange] [bread] [sherbet [[orange] cream] [[ice orange]]]]

def substar' \[new old l]    ; --- Bracket ---
   [eval if isNull l` [[]]
   [eval if isAtom car l'
      [eval if eq car l' old`
          [cons new` substar new` old` cdr l']
          [cons car l' substar new` old` cdr l'] ]
      [cons substar new` old` car l' 
            substar new` old` cdr l']]]

;(define subst*           ; --- Scheme ---
;  (lambda (new old l)
;    (cond
;      ((null? l) (quote ())) 
;      ((atom? (car l))
;        (cond
;          ((eq? (car l) old)
;          (cons new
;            (subst* new old (cdr l))))
;         (else (cons (car l) 
;              (subst* new old
;                (cdr l))))))
;       (else
;         (cons (subst* new old (car l))
;             (subst* new old (cdr l)))))))


; *************************************************
; remberStar: remove all occurrences of atom from list

;remberStar sauce' [[sauce [[flying] and]]
;                   [sauce [bean]]
;                   [[sauce tomato]]]
                   ; =>  [[[[flying] and]] [[bean]] [[tomato]]]

;def remberStar' \[a l]     ; --- Bracket ---
;   [eval if isNull l` [[]]
;   [eval if isAtom car l' 
;      [eval if eq car l' a` 
;         [remberStar a` cdr l']
;         [cons car l' remberStar a` cdr l']]
;      [cons remberStar a` car l' remberStar a` cdr l']]]

;(define rember*          ; --- Scheme ---
;   (lambda (a l)
;     (cond
;        ((null? l) (quote ())) 
;        ((atom? (car l})
;         (cond
;           ((eq? (car l) a) 
;            (rember* a (cdr l)))
;           (else (cons (car l)
;                (rember* a (cdr l))))))
;         (else (cons (rember* a (car l}) 
;            (rember* a (cdr l)))))))


; *************************************************
; rempick: remove nth atom from list

;rempick 3 [pie salty meringue lemon]  ; =>  [pie meringue lemon]

def rempick' \[n lat]      ; --- Bracket ---
  [eval if isone n [cdr lat']
  [cons car lat' rempick sub1 n cdr lat']]

def isone' \[n] [eq n 1]

;(define one?             ; --- Scheme ---
;  (lambda (n)
;     (= n 1)))
;
;(define rempick 
;  (lambda (n lat)         ; --- Scheme ---
;    (cond
;      ((one? n) (cdr lat)) 
;      (else (cons (car lat)
;         (rempick (sub1 n) 
;            (cdr lat)))))))


; *************************************************
; eqan: check if two atoms are the same arguments

;(define eqan? 
;   (lambda (a1 a2)
;     (cond
;       ((and (number? a1 ) (number? a2))
;          (= a1 a2))
;       ((or (number? a1 ) (number? a2)) #f)
;          (else (eq? a1 a2)))))



; *************************************************
; length

;length [rye on cheese and ham] 

;def length' \[lat]          ; --- Bracket ---
;  [eval if isNull lat` [0]
;  [add1 length cdr lat']]

;(define length             ; --- Scheme ---
;   (lambda (lat)
;     (cond
;       ((null? lat) 0)
;       (else (add1 (length (cdr lat)))))))



; *************************************************
; tupplus

;tupplus [7 3] [1 8 6 4] ; => [1 8 13 7]

;def tupplus' \[tup1 tup2]     ; --- Bracket ---
;   [eval if isNull tup1` [tup2`]
;   [eval if isNull tup2` [tup1`]
;   [cons myplus car tup1' car tup2'
;      tupplus cdr tup1' cdr tup2']]]

;(define tupplus              ; --- Scheme ---
;   (lambda (tup1 tup2)
;      (cond
;         ((null? tup1) tup2) 
;         ((null? tup2) tup1) (else
;           (cons (myplus (car tup1) (car tup2)) 
;             (tupplus
;                (cdr tup1) (cdr tup2)))))))

; *************************************************
; mymult

;mymult 12 3  ; => 36

;def mymult' \[n m]     ;; --- Bracket ---
;   [eval if isZero m [0]
;   [myplus n mymult n sub1 m]]

;(define mymult         ;; --- Scheme --
;   (lambda (n m)
;      (cond
;        ((zeroP m) 0)
;        (else (myplus n (mymult n (sub1 m)))))))


; *************************************************
; myminus

;myminus 14 3  ; => 11

;def myminus' \[n m]     ;; --- Bracket ---
;   [eval if isZero m [n]
;   [sub1 - n sub1 m]]

;(define myminus        ;; --- in Scheme ---
;   (lambda (n m)
;     (cond
;       ((zero? m) n)
;       (else (sub1 (- n (sub1 m)))))))
 

; *************************************************
; myplus

;myplus 46 12  ; => 58

def myplus' \[n m]     ;; --- Bracket ---
   [eval if isZero m [n]
   [add1 myplus n sub1 m]]

 
;(define myplus         ;; --- Scheme ---
;   (lambda (n m)
;     (cond
;     ((zero? m) n) 
;     (else (add1 (myplus n (sub1 m)))))))



; *************************************************
; multiple remove atom from list of atoms

;multrember cup' [cup hick and cup tea and cup coffee] 
   ; =>  [[[hick and tea and coffee]

;def multrember' \[a lat]     ; currently symbol names have max 10 characters
;  [eval if isNull lat` [[]]
;  [eval if eq car lat' a`
;      [multrember a` cdr lat']
;      [cons car lat' multrember a`cdr lat']]]

;(define multirember    ;; --- in Scheme ---
;  (lambda (a lat)
;    (cond
;      ((null? lat) (quote ())) 
;      (else
;        (cond
;          ((eq? (car lat) a)
;           (multirember a (cdr lat))) 
;          (else (cons (car lat)
;             (multirember a 
;               (cdr lat)))))))))


; *************************************************
; insert new at first occurrence of old in list of atoms

;insertR topping' fudge' [desert for fudge with creame ice] 
      ; => [desert for topping fudge with creame ice]
;insertR a' b' [d b c]  ;=> [d a b c]

;def insertR' \[new old lat]   ;; --- in Bracket ---
;  [eval if isNull lat` [[]]
;  [eval if eq car lat' old` 
;      [cons old`cons new` cdr lat']
;      [cons car lat' insertR new` old` cdr lat']]]

;(define insertR   ;; --- in Scheme ---
;  (lambda (new old lat)
;    (cond
;      ((null? lat) (quote ())) 
;      (else 
;         (cond
;          ((eq? (car lat) old) 
;           (cons old 
;             (cons new (cdr lat)))) 
;          (else (cons (car lat)
;                (insertR new old (cdr lat)))))))))



; *************************************************
; list of first elements of a list

;firsts [[[five plums] four] [eleven green oranges] [no [more]]] ; => [four oranges [more]]
; firsts []   ; => []
;firsts [[a b] [c d] [e f]]    ; => [b d f]

;def firsts' \[l]   ;; --- in Bracket ---
;  [eval if isNull l` [[]]
;  [cons car car l' firsts cdr l']]

;(define firsts    ;; --- in Scheme ---
;  (lambda (l)
;    (cond
;      ((null? l) . . .)
;        (else (cons (car (car l))
;           (firsts (cdr l)))))))

; *************************************************
; remove a member from list

;rember cup' [coffee cup tea cup and hick cup] ; => [coffee cup tea cup and hick]
;rember toast' [bacon lettuce and tomato] ; => [bacon lettuce and tomato]
;rember mint' [lamb chops and mint flavored mint jelly] ; => [lamb chops and mint flavored jelly] 
                                                       ; remember first element is jelly
;rember mint' [lamb chops and mint jelly] ; => [lamb chops and jelly
;rember and' [bacon lettuce and tomato]   ; => [bacon lettuce tomato]

;def rember' \[a lat]   ;; --- in Bracket ---
;  [eval if isNull lat` [[]]
;  [eval if eq car lat' a` [cdr lat']
;  [cons car lat' rember a` cdr lat']]]

; (define rember   ;; --- in Scheme ---
;    (lambda (a lat)
;       (cond
;         ((null? lat) (quote ())) 
;         ((eq? (car lat) a) (cdr lat)) 
;         (else (cons (car lat)
;            (rember a (cdr lat)))))))


; *************************************************
;isMember1 poached' [fried eggs and scrambled eggs]  ; => 0
;isMember1 tea' [coffee tea or milk]  ; => 1

;def isMember1' \[a lat]     ;; --- in Bracket (a bit shorter) ---
;   [eval if isNull lat` [0]
;   [or isMember1 a` swap eq a` car lat`]]

;def isMember' \[a lat]     ;; --- in Bracket ---
;   [eval if isNull lat` [0]
;   [or eq car lat' a`
;       isMember a` cdr lat']]

;define member?     ;; --- in Scheme ---
;  (lambda (a lat)
;  (cond
;    ((null? lat) #f)
;    (else (or (eq? (car lat) a)
;       (member? a (cdr lat)))))))



; *************************************************
; is list of atoms

;isLat1 [10 5 foo] ; => 1
;isLat []   ; => 1
;isLat [Jack [Sprat] could eat no chicken fat]  ; => 0
;isLat [[Jack] Sprat could eat no chicken fat]  ; => 0
;isLat [Jack Sprat could eat no chicken fat]  ; => 1

;def isLat' \[l]      ;; --- in Bracket ---
;   [eval if isNull l` [1]
;   [eval if isAtom car l' [isLat cdr l'] [0]]]

;(define lat?     ;; --- in Scheme ---
;  (lambda (l)
;    (cond
;      ((null? l) #t)
;      ((atom? (car l)) (lat? (cdr l))) 
;       (else #f))))


; *************************************************


def sub1' \[n] 
  [- n 1]

def add1' \[n] 
  [+ n 1]

def isNull'
   [not]

def isZero'
  [eq 0]

def isAtom'
  [not isList]

def isList'
  [or eq [] swap or eq 4 typ swap eq 5 typ dup dup]