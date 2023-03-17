(fn returns-2 [...]
  (let [g (gensym)]
    `(let [,g (let [,g 1]
                2)]
       ,g)))
(fn good-returns-2 [...]
  `(let [g# (let [g# 1]
              2)]
     g#))
{:returns-2 good-returns-2}
