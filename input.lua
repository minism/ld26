input = {
    keys = {
        left = {'a', 'left'},
        right = {'d', 'right'},
        jump = {'w', 'space', 'up'},
        grab = {'j', 'z'},


        debug = {'1',},
        showbb = {'2',},
        init = {'0',},
    }
}

local _fbuf = {{}, {}}
for cmd, v in pairs(input.keys) do
    _fbuf[1][cmd] = false
    _fbuf[2][cmd] = false
end

input.match = function(cmd, key)
    for k, v in pairs(input.keys[cmd]) do
        if v == key then
            return true
        end
    end
    return false
end

input.down = function(cmd)
    for k, v in pairs(input.keys[cmd]) do
        if love.keyboard.isDown(v) then
            return true
        end
    end
    return false
end

input.downFrame = function(cmd)
    return _fbuf[1][cmd] == false and _fbuf[2][cmd] == true
end


input.update = function(dt)
    for cmd, keys in pairs(input.keys) do
        _fbuf[1][cmd] = _fbuf[2][cmd]
        _fbuf[2][cmd] = input.down(cmd)
    end
end