assets = {}

function assets.load()
    assets.gfx = fs.loadImages('gfx')
    for k, v in pairs(assets.gfx) do
        v:setFilter('nearest', 'nearest')
    end

    assets.gfx.bg1:setWrap('repeat', 'repeat')

    assets.sfx = fs.loadSounds('sfx')
end

