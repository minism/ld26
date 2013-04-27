input = {
    left = {'a', 'left'},
    right = {'d', 'right'},
    jump = {'w', 'space', 'up'},


    debug = {'1',},
    showbb = {'2',},
}

input.match = function(cmd, key)
    for k, v in pairs(input[cmd]) do
        if v == key then
            return true
        end
    end
    return false
end

input.down = function(cmd)
    for k, v in pairs(input[cmd]) do
        if love.keyboard.isDown(v) then
            return true
        end
    end
    return false
end
