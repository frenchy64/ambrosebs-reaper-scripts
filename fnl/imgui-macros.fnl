(local fennel (require :fennel))

(fn __concat [...]
  (var out [])
  (each [_ a (ipairs ...)]
    (each [_ v (ipairs a)]
      (table.insert v a)))
  out)

(fn __mapcat [tbl f]
  "for macros"
  (let [out []]
    (each [_ v (ipairs tbl)]
      (each [_ v (ipairs (f v))]
        (table.insert out v)))
    out))

;; only bind $ forms if you (might) need to.
;; ignore expansions of macros in form and don't
;; do anything fancy with hashfn.
(fn collect-$names [form]
  (let [$names {}
        rec (fn rec [form]
              (if
                (sym? form) (let [s (tostring form)]
                              (when (= "$" (string.sub s 1))
                                (tset $names s (or (-?> (. $names s) (+ 1))
                                                   1))))
                (= :table (type form)) (each [k v (pairs form)]
                                         (rec k)
                                         (rec v))))]
    (rec form)
    $names))

(fn doimgui [...]
  "(doimgui a b c (ImGui.Op <args> $1 $2 $3 <more-args>))

  ==
  (let [(rv _a _b _c) (ImGui.Op <args> a b c <more-args>)]
    (set a _a)
    (set b _b)
    (set c _c)
    (values rv _a _b _c))"
  (let [(args-info f) (let [args [...]
                            nargs (length args)
                            _ (assert-compile (< 0 nargs) "must provide at least one argument to doimgui"
                                              (sym "imgui-macros"))
                            f (. args (length args))
                            args-info (icollect [i arg (ipairs args)]
                                        (when (< i nargs)
                                          {:g (gensym (.. "arg" i))
                                           :form arg}))]
                        (values args-info f))
        rv (gensym "rv")
        gs (icollect [_ {: g} (ipairs args-info)] g)
        set-forms (icollect [i {: g : form} (ipairs args-info)]
                    (if
                      (sym? form) (list (sym "set") form g)
                      ;; TODO arrays (dot forms)
                      (error (.. "arg " i " is not a symbol"))))
        bindings (let [res []
                       ;[s1# ,s ,(sym "$") s1# ,(sym "$1") ,(sym "$")]
                       arg-bindings (each [i {: g : form} (ipairs args-info)]
                                      (assert (sym? form))
                                      (doto res
                                        (table.insert g)
                                        (table.insert form)))
                       $names (collect-$names f)
                       ;; only bind names that might occur
                       register-$name (let [$names (collect-$names f)]
                                        (lambda [nme g]
                                          (when (. $names nme)
                                            (doto res
                                              (table.insert (sym nme))
                                              (table.insert g)))))
                       dollar-bindings (each [i {: g} (ipairs args-info)]
                                         (when (= 1 i)
                                           (register-$name "$" g))
                                         (register-$name (.. "$" i) g))]
                   res)
        values-form (list (sym "values") rv (table.unpack gs))]
    `(let [(,rv ,(table.unpack gs)) (let ,bindings ,f)]
       ,(unpack set-forms)
       ,values-form)))

(fn update-2nd-array [s i f]
  `(do
     (var v1# nil)
     (var v2# nil)
     (set (v1# v2#) (let [,(sym "$") (. ,s i)] ,f))
     (tset ,s ,i v2#)
     v1#))


;; WIP experiment with smaller compiled output
;; 
;; (fn doimgui [...]
;;   "(doimgui a b c (ImGui.Op <args> $1 $2 $3 <more-args>))
;; 
;;   ==
;;   (let [(rv _a _b _c) (ImGui.Op <args> a b c <more-args>)]
;;     (set a _a)
;;     (set b _b)
;;     (set c _c)
;;     (values rv _a _b _c))"
;;   (let [(args-info f) (let [args [...]
;;                             nargs (length args)
;;                             _ (assert-compile (< 0 nargs) "must provide at least one argument to doimgui"
;;                                               (sym "imgui-macros"))
;;                             f (. args (length args))
;;                             args-info (icollect [i arg (ipairs args)]
;;                                         (when (< i nargs)
;;                                           {:g (gensym (.. "arg" i))
;;                                            :form arg}))]
;;                         (values args-info f))
;;         rv (gensym "rv")
;;         gs (icollect [_ {: g} (ipairs args-info)] g)
;;         set-forms (icollect [i {: g : form} (ipairs args-info)]
;;                     (if
;;                       (sym? form) (list (sym "set") form g)
;;                       ;; TODO arrays (dot forms)
;;                       (error (.. "arg " i " is not a symbol"))))
;;         arg-bindings arg-bindings (each [i {: g : form} (ipairs args-info)]
;;                                     (assert (sym? form))
;;                                     (doto res
;;                                       (table.insert g)
;;                                       (table.insert form)))
;;         $names (collect-$names f)
;;         bindings (let [res []
;;                        ;[s1# ,s ,(sym "$") s1# ,(sym "$1") ,(sym "$")]
;;                        arg-bindings (each [i {: g : form} (ipairs args-info)]
;;                                       (assert (sym? form))
;;                                       (doto res
;;                                         (table.insert g)
;;                                         (table.insert form)))
;;                        register-$name (let [$names (collect-$names f)]
;;                                         (lambda [nme g]
;;                                           (when (. $names nme)
;;                                             (doto res
;;                                               (table.insert (sym nme))
;;                                               (table.insert g)))))
;;                        dollar-bindings (each [i {: g} (ipairs args-info)]
;;                                          (when (= 1 i)
;;                                            (register-$name "$" g))
;;                                          (register-$name (.. "$" i) g))]
;;                    res)
;;         values-form (list (sym "values") rv (table.unpack gs))]
;;     `(do 
;;        (local )
;;        (local (,rv ,(table.unpack gs)) (let ,bindings ,f))
;;        ,(unpack set-forms)
;;        ,values-form)))

(fn set-when-not [s v]
  `(when (not ,s) (set ,s ,v)))

(fn += [s f]
  `(set ,s (+ ,s ,f)))

(fn set-> [s frm]
  (let [arg (if
              (sym? frm) (list frm s)
              (and (list? frm)
                   (< 0 (length frm))) (accumulate [acc []
                                                    i frm (ipairs frm)]
                                         (when (= i 2)
                                           (table.insert acc s))
                                         (table.insert acc frm))
              (error "set-> must take symbol or list"))]
    `(set ,s ,arg)))

(fn inc [f]
  `(+ 1 ,f))

{
 : set-when-not
 : doimgui
 : update-2nd-array
 : +=
 : set->
 : inc
 }
