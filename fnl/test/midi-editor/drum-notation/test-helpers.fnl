(require-macros :fennel-test)
(local json (require :json-lua/json))
(lambda slurp-json [file]
  (match (io.open file)
    ;; when io.open succeeds, it will return a file, but if it fails it will
    ;; return nil and an err-msg string describing why
    f (let [j (json.decode (f:read :*all))
            _ (f:close)]
        j)
    (nil err-msg) (error (.. "Could not open file:" err-msg))))

(var common-json (slurp-json "../common/test-cases.json"))
(lambda test-common-cases [tests-id f]
  (let [cases (. common-json tests-id)]
    (assert cases (.. "Bad tests id: " tests-id))
    (each [i {: id : result : args} (ipairs cases)]
      (assert id)
      (assert result)
      (assert args)
      (assert-eq result (f (table.unpack args))
                 (.. tests-id " " id)))))
