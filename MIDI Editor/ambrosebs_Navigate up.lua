-- @noindex
-- @author frenchy64
-- @version 1.0
-- @about
--    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
--    in musical notation software such as Dorico by guessing how many bars the music
--    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
--    which goes "down" in that view.

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require "ambrosebs_Navigate lib"
GoUp()
