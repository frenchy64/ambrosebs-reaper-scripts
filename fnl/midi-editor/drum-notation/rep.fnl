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
  {:pre [(midi-name? n)]}
  (= 1 (length n)))

;(assert (apply distinct? midi-names))
(assert (= 12 (length midi-names)) (length midi-names))

;   ;; 0 => C-1
;   (def lowest-midi-name (first midi-names))
(local lowest-midi-octave -1)
(local highest-midi-octave 9)
;   (def lowest-midi-note 0)
;   (def highest-midi-note 127)
;   
;   (defn midi-number? [n]
;     (and (nat-int? n)
;          (<= lowest-midi-note n highest-midi-note)))
;   
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

;   (defn parse-midi-coord [s]
;     {:pre [(string? s)]
;      :post [(midi-coord? %)]}
;     (let [trailing (Integer/parseInt (str (nth s (dec (count s)))))
;           negative? (= \- (nth s (- (count s) 2)))
;           octave (cond-> trailing
;                    negative? -)
;           nme (subs s 0 (cond-> (dec (count s))
;                           negative? dec))]
;       (->midi-coord nme octave)))
;   
;   (defn midi-number->coord [n]
;     {:pre [(midi-number? n)]
;      :post [(midi-coord? %)]}
;     (->midi-coord (nth midi-names (mod n (count midi-names)))
;                   (+ lowest-midi-octave
;                      (quot n (count midi-names)))))
;   
;   (defn c-major-midi-number? [n]
;     {:pre [(midi-number? n)]}
;     (-> n midi-number->coord :midi-name c-major-midi-name?))
;   
;   ;; 0 => C-1
;   ;; 12 => C-1
;   ;; 24 => C-1
;   (defn midi-coord->number [{:keys [midi-name octave] :as c}]
;     {:pre [(midi-coord? c)]
;      :post [(midi-number? %)]}
;     (+ (midi-name->pos midi-name)
;        (* 12 (inc octave))))
;   
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

{: midi-names
 ;: midi-name->pos
 : midi-name?
 : ->midi-coord
 : c-major-midi-name?
 : midi-coord-str}
