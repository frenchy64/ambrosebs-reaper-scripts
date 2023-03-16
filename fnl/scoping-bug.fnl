;;(let [(rv_8_ arg1_7_) (let [arg1_7_ a $ arg1_7_ $1 arg1_7_] (b $))] (set a arg1_7_) (values rv_8_ arg1_7_))
;
;(var a 1)
;(let [(_ A) (let [A a] (values nil 2))]
;  (set a A))
;(print a)
;
;(doimgui a (values 1 2))

(macro scoping [a]
  `(let [(rv# v1#) (let [v1# 44] (values 1 2))] (set ,a v1#) rv#))
(var some-reason 1)
(var a 1)
(fn something []
  (when some-reason
    (scoping a)
    (print a)))
(something)

;; -
(var a 42)
(fn try []
  (let [(rv_8_ arg1_7_) (let [arg1_7_ a $ arg1_7_ $1 arg1_7_] (values 1 2))] (set a arg1_7_) (values rv_8_ arg1_7_)))
(try)

;; - fails at the repl (prints nil)
;;   - failed the first few times, then succeeded??
;; - but runs correctly when compiled to lua
(do
  (var a 42)
  (let [(rv_8_ arg1_7_) (let [arg1_7_ a $ arg1_7_ $1 arg1_7_] (values 1 2))]
  (set a arg1_7_) ;; set a to 2
  (print "should be 2: " arg1_7_)))

(do
  (var a 2)
  (let [arg1_11_ (let [arg1_11_ a] 2)]
    (set a arg1_11_)
    (print "first: " arg1_11_)))
(do
  (var a 2)
  (let [A (let [A a] 2)]
    (set a A)
    (print "second: " A)))
