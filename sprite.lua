require 'assets'
require 'math'

sprite = {}


function sprite.load()
    sprite.sheets = {}
    for i=1,1 do
        table.insert(sprite.sheets, sprite.newSheet(assets.gfx["sheet" .. i]))
    end

    sprite.backgrounds = {}
    for i=1,3 do 
        table.insert(sprite.backgrounds, sprite.newBackground(assets.gfx["bg" .. i]))
    end
end

function sprite.newSheet(image)
    return {
        image = image,
        quads = build_quads(image, 16, 16, 1, 1),
    }
end

function sprite.newBackground(image)
    return {
        image = image,
        quad = lg.newQuad(0, 0, SCREEN_W, SCREEN_H, image:getWidth(), image:getHeight()),
        scrollable = lg.newQuad(0, 0, SCREEN_W * 2, SCREEN_H * 2, image:getWidth(), image:getHeight()),
        width = image:getWidth(),
        height = image:getHeight(),
    }
end

function sprite.drawSprite(idx, ...)
    local sheet_num = math.ceil(idx / 64)
    sheet_num = 1
    local quad_num = (idx - 1) % 64 + 1
    local sheet = sprite.sheets[sheet_num]
    lg.drawq(sheet.image, sheet.quads[quad_num], ...)
end


function sprite.drawBackground(idx, ...)
    local bg = sprite.backgrounds[idx]
    lg.drawq(bg.image, bg.quad, ...)
end

function sprite.drawScrollingBackground(idx, dx, dy, ...)
    local bg = sprite.backgrounds[idx]
    local x = -bg.width + (dx % bg.width)
    local y = -bg.height + (dy % bg.height)
    lg.drawq(bg.image, bg.scrollable, x, y, ...)
end

