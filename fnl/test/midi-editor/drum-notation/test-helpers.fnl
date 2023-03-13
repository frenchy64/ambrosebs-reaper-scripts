(require-macros :fennel-test)
(local clj (require :cljlib))
(local json (require :json))
(local fennel (require :fennel))

(lambda deep-coerce-keys [t]
  (if (= :table (type t))
    (do
      (var newt {})
      (each [k v (pairs t)]
        (let [k (or (when (= :string (type k))
                      (tonumber k 10))
                    k)]
          (tset newt k (deep-coerce-keys v))))
      newt)
    t))

(lambda slurp-json [file]
  (match (io.open file)
    ;; when io.open succeeds, it will return a file, but if it fails it will
    ;; return nil and an err-msg string describing why
    f (let [j (deep-coerce-keys (json.decode (f:read :*all)))
            _ (f:close)]
        j)
    (nil err-msg) (error (.. "Could not open file:" err-msg))))

(local common-json (slurp-json "../common/test-cases.json"))
(lambda test-common-cases [tests-id f]
  (let [cases (. common-json tests-id)]
    (assert cases (.. "Bad tests id: " tests-id))
    (each [i {: id : result : args} (ipairs cases)]
      (assert id)
      (assert result)
      (assert args)
      (assert-eq result (f (table.unpack args))
                 (string.format "%s (%s (table.unpack %s))"
                                id
                                tests-id
                                (fennel.view args))))))

{
 : test-common-cases
 : deep-coerce-keys
}
