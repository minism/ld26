assets = {}

function assets.load()
    assets.gfx = fs.loadImages('gfx')
    for k, v in pairs(assets.gfx) do
        v:setFilter('nearest', 'nearest')
        if k:find('bg') then
            v:setWrap('repeat', 'repeat')
        end
    end


    assets.sfx = fs.loadSounds('sfx', 'static')
    assets.mus = fs.loadSounds('mus', 'streaming')

    for k, v in pairs(assets.sfx) do
        v:setVolume(0.5)
    end


    assets.font = lg.newFont('font/font.ttf', 36)
end

