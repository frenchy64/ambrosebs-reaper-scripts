;; @description Notation: Next Staff ({◊bars◊} bar{◊bars|pluralize◊})
;; @author Ambrose Bonnaire-Sergeant
;; @version 1.6
;; @about
;;    Intended to be assigned to the Down arrow in the MIDI Editor to simulate pressing Down
;;    in musical notation software such as Dorico.
;;    Use this script if there are {◊bars◊} bar{◊bars|pluralize◊} per line in Notation view at the current zoom.
;;    In other MIDI editor modes, this script decreases the pitch cursor, which goes "down" in that view.

(local notation (require :midi-editor.notation))
(notation.go-down {◊bars◊})
