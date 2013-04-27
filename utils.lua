function overlaps(head, tail, head2, tail2)
    if head >= head2 then
        return head < tail2
    else
        return head2 < tail
    end
end
