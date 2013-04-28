assets = {}

function assets.load()
    assets.gfx = fs.loadImages('gfx')
    for k, v in pairs(assets.gfx) do
        v:setFilter('nearest', 'nearest')
        if k:find('bg') then
            v:setWrap('repeat', 'repeat')
        end
    end

    assets.sfx = fs.loadSounds('sfx')
end

