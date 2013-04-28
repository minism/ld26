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

function cr2idx(col, row)
    return row * WORLD_BLOCKS_X + col
end