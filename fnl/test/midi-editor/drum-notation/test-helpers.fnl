(local json (require :json.lua/json))
(lambda slurp-json [file]
  (match (io.open file)
    ;; when io.open succeeds, it will return a file, but if it fails it will
    ;; return nil and an err-msg string describing why
    f (let [j (json.decode (f:read :*all))
            _ (f:close)]
        j)
    (nil err-msg) (assert nil (.. "Could not open file:" err-msg))))
