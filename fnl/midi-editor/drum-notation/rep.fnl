(local midi-names ["C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B"])
(local midi-names-set
  (let [h {}]
    (each [_ v (ipairs midi-names)]
      (tset h v v))
    h))
(local midi-name->pos
  (let [h {}]
    (each [k v (ipairs midi-names)]
      (tset h v k))
    h))
(fn midi-name? [n]
  (not (= nil (. midi-names-set n))))
(fn c-major-midi-name? [n]
  (assert (midi-name? n) (.. "c-major-midi-name?: " n (type n)))
  (= 1 (length n)))

;(assert (apply distinct? midi-names))
(assert (= 12 (length midi-names)) (length midi-names))

;; 0 => C-1
(local lowest-midi-name (. midi-names 1))
(local lowest-midi-octave -1)
(local highest-midi-octave 9)
(local lowest-midi-note 0)
(local highest-midi-note 127)

(fn midi-number? [n]
  (and (= :number (type n))
       (= n (math.floor n))
       (<= lowest-midi-note n)
       (<= n highest-midi-note)))

(fn midi-octave? [o]
  (and (<= lowest-midi-octave o)
       (<= o highest-midi-octave)))

(fn midi-coord? [v]
  (and (= :table (type v))
       (let [{: midi-name : octave} v]
         (and ;(= 2 (count v))
              (midi-name? midi-name)
              (midi-octave? octave)))))
   
(fn ->midi-coord [midi-name octave]
  (assert (midi-name? midi-name) midi-name)
  (assert (midi-octave? octave) octave)
  (let [res {: midi-name
             : octave}]
    (assert (midi-coord? res) res)
    res))

(fn midi-coord-str [v]
  (assert (midi-coord? v))
  (let [{: midi-name : octave} v]
    (.. midi-name octave)))

(fn parse-midi-coord [s]
  (assert (= :string (type s)))
  (let [trailing (tonumber (string.sub s (length s) (length s)))
        negative? (= "-" (string.sub s (- (length s) 1) (- (length s) 1)))
        octave (if negative?
                 (- trailing)
                 trailing)
        nme (string.sub s 1 (if negative?
                              (- (length s) 2)
                              (- (length s) 1)))
        res (->midi-coord nme octave)]
    (assert (midi-coord? res))
    res))

(fn midi-number->coord [n]
  (assert (midi-number? n) (.. "midi-number->coord: " n " " (type n)))
  (let [res (->midi-coord (. midi-names (+ 1 (% n (length midi-names))))
                          (+ lowest-midi-octave
                             (// n (length midi-names))))]
    (assert (midi-coord? res))
    res))

(fn c-major-midi-number? [n]
  (assert (midi-number? n) (.. "c-major-midi-number?: " (type n)))
  (-> n midi-number->coord (. :midi-name) c-major-midi-name?))

;; 0 => C-1
;; 12 => C-1
;; 24 => C-1
(fn midi-coord->number [c]
  (assert (midi-coord? c) (.. "midi-coord->number: " (type c)))
  (let [{: midi-name : octave} c]
    (let [res (+ (. midi-name->pos midi-name)
                 -1
                 (* 12 (+ octave 1)))]
      (assert (midi-number? res))
      res)))

;   ;; TODO assert alphanumeric, no unicode
;   (defn instrument-id? [id]
;     (and (string? id)
;          (= 2 (count id))))
;   
;   (def reaper-accidental->string
;     {"flat" "♭"
;      "doubleflat" "𝄫"
;      "natural" "♮"
;      "sharp" "♯"
;      "doublesharp" "𝄪"})
;   
;   (defn reaper-accidental? [r]
;     (contains? reaper-accidental->string r))
;   
;   (defn instruments-map? [m]
;     (and (map? m)
;          (every? instrument-id? (keys m))
;          (every? (every-pred map? (comp string? :name))
;                  (vals m))))
;   
;   (defn midi-number-constraints? [m]
;     (and (map? m)
;          (sorted? m)
;          ;;TODO assert C major midi number
;          (every? midi-number? (keys m))
;          (every? (every-pred vector?
;                              #(every? instrument-id? %))
;                  (vals m))))
;   
;   (defn notation-constraints? [m]
;     (and (map? m)
;          (every? (comp c-major-midi-name?
;                        :midi-name
;                        parse-midi-coord)
;                  (keys m))
;          (every? (every-pred vector?
;                              ;; up to 5 instruments on one staff line
;                              #(<= 1 (count %) 5)
;                              #(every? instrument-id? %))
;                  (vals m))))
;   
;   (defn notation-spec? [m]
;     (and (map? m)
;          (string? (:name m))
;          (midi-coord? (:root m))
;          (instruments-map? (:instruments m))
;          (notation-constraints? (:notation-map m))))
;   
;   (defn solution? [m]
;     (and (map? m)
;          (sorted? m)
;          (pos? (count m))
;          (every? midi-number? (keys m))
;          (apply distinct? (map :instrument-id (vals m)))
;          ;; TODO stronger consistency check by combining midi note number + accidental
;          ;(apply distinct? (map :printed-note (vals m)))
;          (every? (every-pred map?
;                              (comp instrument-id? :instrument-id)
;                              (comp reaper-accidental? :accidental))
;                  (vals m))))
;   
;   (defn coord-str-constraints->midi-number-constraints [cs]
;     {:pre [(notation-constraints? cs)]
;      :post [(midi-number-constraints? %)]}
;     (into (sorted-map)
;           (map (fn [[midi-coord-str v]]
;                  {(-> midi-coord-str parse-midi-coord midi-coord->number)
;                   v}))
;           cs))
;   
;   (def accidental->semitones
;     {"doubleflat" -2
;      "flat" -1 
;      "natural" 0 
;      "sharp" 1 
;      "doublesharp" 2})
;   
;   (def semitones->accidental
;     (set/map-invert accidental->semitones))
;   
;   (defn accidental-relative-to [note respell]
;     {:pre [(c-major-midi-number? note)
;            (midi-number? respell)]
;      :post [(reaper-accidental? %)]}
;     (semitones->accidental (- respell note)))
;   
;   (defn notated-midi-num-for [midi-num accidental]
;     {:pre [(midi-number? midi-num)
;            (reaper-accidental? accidental)]
;      :post [(c-major-midi-number? %)]}
;     (- midi-num (accidental->semitones accidental)))
;   
;   (defn solution-or-error? [m]
;     (and (map? m)
;          (case (:type m)
;            :solution (and (= 2 (count m))
;                           (solution? (:solution m)))
;            :error (and (string? (:message m))
;                        (map? (:data m))
;                        (= 3 (count m)))
;            false)))
;   
;   (defn enharmonically-respellable?
;     [notated-num candidate]
;     {:pre [((every-pred midi-number?) notated-num candidate)]
;      :post [(boolean? %)]}
;     (boolean
;       (some #(= (+ % candidate) notated-num)
;             (vals accidental->semitones))))

{
 : ->midi-coord
 : c-major-midi-name?
 : c-major-midi-number?
 : midi-coord->number
 : midi-coord-str
 : midi-name?
 : midi-names
 : midi-number->coord
 : parse-midi-coord
 ;: midi-name->pos
 }
