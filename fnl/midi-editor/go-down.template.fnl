;; @description Go forward {◊bars◊} bar{◊bars|pluralize◊} in Notation, otherwise decrease pitch cursor one semitone
;; @author Ambrose Bonnaire-Sergeant
;; @version 1.6
;; @about
;;    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
;;    in musical notation software such as Dorico. The user of this script must count how many
;;    bars are on a single line in Notation view, and choose this script if the number is {◊bars◊}.
;;    When the zoom level is changed, a different script will be needed.
;;    If in a different MIDI editor mode, decreases the pitch cursor, which goes "down" in that view.

(local notation (require :midi-editor.notation))
(notation.go-down {◊bars◊})
