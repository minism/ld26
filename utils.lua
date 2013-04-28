require 'math'


function constrain(value, low, high)
    return math.max(low, math.min(value, high))
end


function overlaps(head, tail, head2, tail2)
    if head >= head2 then
        return head < tail2
    else
        return head2 < tail
    end
end

function pos2cr(x, y)
    return math.floor(x / BLOCK_SIZE), math.floor(y / BLOCK_SIZE)
end

function cr2pos(col, row)
    local l,t = col * BLOCK_SIZE, row * BLOCK_SIZE
    local r,b = l + BLOCK_SIZE, t + BLOCK_SIZE
    return l,t,r,b
end


function cr2idx(col, row)
    return row * WORLD_BLOCKS_X + col
end