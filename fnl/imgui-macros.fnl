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
                                          {:outer-g (gensym (.. "arg" i))
                                           :inner-g (gensym (.. "arg" i))
                                           :form arg}))]
                        (values args-info f))
        rv (gensym "rv")
        outer-gs (icollect [_ {: outer-g} (ipairs args-info)] outer-g)
        set-forms (icollect [i {: outer-g : form} (ipairs args-info)]
                    (if
                      (sym? form) (list (sym "set") form outer-g)
                      ;; TODO arrays (dot forms)
                      (error (.. "arg " i " is not a symbol"))))
        bindings (let [res []
                       ;[s1# ,s ,(sym "$") s1# ,(sym "$1") ,(sym "$")]
                       arg-bindings (each [i {: inner-g : form} (ipairs args-info)]
                                      (assert (sym? form))
                                      (doto res
                                        (table.insert inner-g)
                                        (table.insert form)))
                       dollar-bindings (each [i {: inner-g} (ipairs args-info)]
                                         (when (= 1 i)
                                           (doto res
                                             (table.insert (sym "$"))
                                             (table.insert inner-g)))
                                         (doto res
                                           (table.insert (sym (.. "$" i)))
                                           (table.insert inner-g)))]
                   res)
        values-form (list (sym "values") rv (table.unpack outer-gs))]
    `(let [(,rv ,(unpack outer-gs)) (let ,bindings ,f)]
       ,(unpack set-forms)
       ,values-form)))

(fn update-2nd-array [s i f]
  `(do
     (var v1# nil)
     (var v2# nil)
     (set (v1# v2#) (let [,(sym "$") (. ,s i)] ,f))
     (tset ,s ,i v2#)
     v1#))

(fn set-when-not [s v]
  `(when (not ,s) (set ,s ,v)))

{
 : set-when-not
 : doimgui
 : update-2nd-array
 }
