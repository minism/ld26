input = {
    left = {'a', 'left'},
    right = {'d', 'right'},
    jump = {'w', 'space', 'up'},
}

input.down = function(cmd)
    for k, v in pairs(input[cmd]) do
        if love.keyboard.isDown(v) then
            return true
        end
    end
    return false
end
