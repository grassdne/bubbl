require "textrenderer"

title = "AAAAAAA"

on_update = function()
    local pos = Vector2(window_width/2, window_height/2);
    local text = "AAAAA??"
    local fontsize = 40
    local width = #text * fontsize
    pos.x = pos.x - width/2
    put_string(pos, text, fontsize)
end

package.loaded["test"] = false
