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
(lambda midi-name? [n]
  (not (= nil (. midi-names-set n))))
(lambda c-major-midi-name? [n]
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

(lambda midi-number? [n]
  (and (= :number (type n))
       (= n (math.floor n))
       (<= lowest-midi-note n)
       (<= n highest-midi-note)))

(lambda midi-octave? [o]
  (and (<= lowest-midi-octave o)
       (<= o highest-midi-octave)))

(lambda midi-coord? [v]
  (and (= :table (type v))
       (let [{: midi-name : octave} v]
         (and ;(= 2 (count v))
              (midi-name? midi-name)
              (midi-octave? octave)))))
   
(lambda ->midi-coord [midi-name octave]
  (assert (midi-name? midi-name) midi-name)
  (assert (midi-octave? octave) octave)
  (let [res {: midi-name
             : octave}]
    (assert (midi-coord? res) res)
    res))

(lambda midi-coord-str [v]
  (assert (midi-coord? v))
  (let [{: midi-name : octave} v]
    (.. midi-name octave)))

(lambda parse-midi-coord [s]
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

(lambda midi-number->coord [n]
  (assert (midi-number? n) (.. "midi-number->coord: " n " " (type n)))
  (let [res (->midi-coord (. midi-names (+ 1 (% n (length midi-names))))
                          (+ lowest-midi-octave
                             (// n (length midi-names))))]
    (assert (midi-coord? res))
    res))

(lambda c-major-midi-number? [n]
  (assert (midi-number? n) (.. "c-major-midi-number?: " (type n)))
  (-> n midi-number->coord (. :midi-name) c-major-midi-name?))

;; 0 => C-1
;; 12 => C-1
;; 24 => C-1
(lambda midi-coord->number [c]
  (assert (midi-coord? c) (.. "midi-coord->number: " (type c)))
  (let [{: midi-name : octave} c]
    (let [res (+ (. midi-name->pos midi-name)
                 -1
                 (* 12 (+ octave 1)))]
      (assert (midi-number? res))
      res)))

;; TODO assert alphanumeric, no unicode
(lambda instrument-id? [id]
  (and (= :string (type id))
       (= 2 (length id))))

(local reaper-accidental->string
  {"flat" "♭"
   "doubleflat" "𝄫"
   "natural" "♮"
   "sharp" "♯"
   "doublesharp" "𝄪"})
   
(lambda reaper-accidental? [r]
  (not (= nil (. reaper-accidental->string r))))

(lambda ievery? [i-pred m]
  (and (= :table (type m))
       (do (var good? true)
         (each [_ i (ipairs m)]
           (set good? (and good?
                           (i-pred i))))
         good?)))

(lambda every-kv? [k-pred v-pred m]
  (and (= :table (type m))
       (do
         (var good? true)
         (each [k v (pairs m)]
           (set good? (and good?
                           (k-pred k)
                           (v-pred v))))
         good?)))
   
(lambda instruments-map? [m]
  (every-kv? instrument-id?
             (lambda [v]
               (and (= :table (type v))
                    (= :string (type (. v :name)))))
             m))

(lambda midi-number-constraints? [m]
  (and ;(sorted? m)
       ;;TODO assert C major midi number
       (every-kv? midi-number?
                  (lambda [v]
                    (ievery? instrument-id? v))
                  m)))

(lambda notation-constraints? [m]
  (every-kv? (lambda [k]
               (-> k parse-midi-coord (. :midi-name) c-major-midi-name?))
             (lambda [v]
               (and (ievery? instrument-id? v)
                    (<= 1 (length v) 5)))
             m))

(lambda notation-spec? [m]
  (and (= :table (type m))
       (= :string (type (. m :name)))
       (midi-coord? (. m :root))
       (instruments-map? (. m :instruments))
       (notation-constraints? (. m :notation-map))))

(lambda solution? [m]
  (and (every-kv? midi-number?
                  (lambda [v]
                    (and (= :table (type v))
                         (instrument-id? (. v :instrument-id))
                         (reaper-accidental? (. v :accidental))))
                  m)
       ;(sorted? m) ;;FIXME
       (do
         (var len 0)
         (each [_ (pairs m)]
           (set len (+ 1 len)))
         (> len 0))
       ;(apply distinct? (map :instrument-id (vals m)))
       ;; TODO stronger consistency check by combining midi note number + accidental
       ;(apply distinct? (map :printed-note (vals m)))
       ))

(lambda coord-str-constraints->midi-number-constraints [cs]
  (assert (notation-constraints? cs) "coord-str-constraints->midi-number-constraints: " (type cs))
  (var res {})
  (each [midi-coord-str v (pairs cs)]
    (tset res (-> midi-coord-str parse-midi-coord midi-coord->number)
          v))
  (assert (midi-number-constraints? res))
  res)

(local accidental->semitones
  {"doubleflat" -2
   "flat" -1 
   "natural" 0 
   "sharp" 1 
   "doublesharp" 2})

(local semitones->accidental
  (do
    (var h {})
    (each [k v (pairs accidental->semitones)]
      (tset h v k))
    h))

(lambda accidental-relative-to [note respell]
  (assert (c-major-midi-number? note) "accidental-relative-to")
  (assert (midi-number? respell) "accidental-relative-to")
  (let [res (. semitones->accidental (- respell note))]
    (assert (reaper-accidental? res))
    res))

(lambda notated-midi-num-for [midi-num accidental]
  (assert (midi-number? midi-num) "notated-midi-num-for")
  (assert (reaper-accidental? accidental) "notated-midi-num-for")
  (let [res (- midi-num (. accidental->semitones accidental))]
    (assert (c-major-midi-number? res))
    res))

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
(lambda enharmonically-respellable?
  [notated-num candidate]
  (assert (midi-number? notated-num) "enharmonically-respellable?")
  (assert (midi-number? candidate) "enharmonically-respellable?")
  (var respellable? false)
  (each [_ v (pairs accidental->semitones)]
    (set respellable? (or respellable?
                          (= (+ v candidate) notated-num))))
  (assert (= :boolean (type respellable?)))
  respellable?)

{
 : ->midi-coord
 : accidental-relative-to
 : c-major-midi-name?
 : c-major-midi-number?
 : coord-str-constraints->midi-number-constraints
 : enharmonically-respellable?
 : instrument-id?
 : instruments-map?
 : midi-coord->number
 : midi-coord-str
 : midi-name?
 : midi-names
 : midi-number->coord
 : midi-number?
 : notated-midi-num-for
 : notation-constraints?
 : notation-spec?
 : parse-midi-coord
 : reaper-accidental?
 : solution?
 ;: midi-name->pos
 }
