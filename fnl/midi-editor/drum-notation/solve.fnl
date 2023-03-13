(local rep (require :midi-editor.drum-notation.rep))

(lambda enharmonic-midi-numbers
  ;"Return the possible midi numbers representing enharmonic
  ;respellings for the given C major note."
  [root notated]
  (assert (rep.midi-number? root))
  ;;TODO what does the root-num mean? is it the lowest note
  ;; than can be written on the staff, the lowest note allocatable
  ;; to an instrument, or both?
  (assert (<= root notated))
  (assert (rep.c-major-midi-number? notated))
  (var ns [])
  (for [i
        (math.max root (- notated 2))
        (+ notated 2)]
    (assert (rep.midi-number? i))
    (table.insert ns i))
  ns)

(lambda find-solution [root-coord str-cs]
  (assert (rep.midi-coord? root-coord) "find-solution")
  (assert (rep.notation-constraints? str-cs) "find-solution")
  (let [root-num (rep.midi-coord->number root-coord)
        num-cs (rep.coord-str-constraints->midi-number-constraints str-cs)
        instrument->notated-num (let [ordered-cs (do (var a [])
                                                     (each [n (pairs num-cs)]
                                                           (table.insert a n))
                                                     (table.sort a)
                                                     a)]
                                  (var a [])
                                  (each [_ n (ipairs ordered-cs)]
                                        (let [is (. num-cs n)]
                                          (assert is)
                                          (each [_ i (ipairs is)]
                                                (table.insert a [i n]))))
                                  a)
        solution {}
        doloop (lambda doloop [instrument->notated-num-idx
                               next-free-midi-num]
                 (let [[id notated-num] (. instrument->notated-num instrument->notated-num-idx)
                       _ (assert (rep.instrument-id? id) id)
                       _ (assert (rep.midi-number? notated-num))]
                   (if (not (rep.midi-number? next-free-midi-num))
                     {:type :error
                      :data {:instrument-clashes [id]}
                      :message "Could not fit instrument into MIDI range"}
                     (let [allocated-midi-num (do
                                                (var allocated-midi-num nil)
                                                (each [_ n (ipairs (enharmonic-midi-numbers root-num notated-num))]
                                                      (set allocated-midi-num (or allocated-midi-num
                                                                                  (if (<= next-free-midi-num n)
                                                                                    n
                                                                                    nil))))
                                                allocated-midi-num)]
                       (if (not allocated-midi-num)
                         {:type :error
                          :data {:instrument-clashes [id ;(-> solution rseq first val :instrument-id) ;TODO
                                                      ]}
                          :message "Insufficient room for instruments"})
                       (let [_ (tset solution allocated-midi-num
                                     {:instrument-id id
                                      :accidental (rep.accidental-relative-to notated-num allocated-midi-num)})
                             instrument->notated-num-idx (+ 1 instrument->notated-num-idx)]
                         (if (not (= nil (. instrument->notated-num instrument->notated-num-idx)))
                           (doloop instrument->notated-num-idx
                                   (+ 1 next-free-midi-num))
                           {:type :solution
                            :solution solution}))))))
        res (doloop 1 root-num)]
    (assert (rep.solution-or-error? res))
    res))

{
 : enharmonic-midi-numbers
 : find-solution
}
