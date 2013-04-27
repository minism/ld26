require 'assets'
require 'math'

sprite = {}


function sprite.load()
    sprite.sheets = {}
    for i=1,1 do
        table.insert(sprite.sheets, sprite.newSheet(assets.gfx["sheet" .. i]))
    end
end

function sprite.newSheet(image)
    return {
        image = image,
        quads = build_quads(image, 16, 16),
    }
end

function sprite.drawSprite(idx, ...)
    local sheet_num = math.ceil(idx / 64)
    sheet_num = 1
    local quad_num = (idx - 1) % 64 + 1
    local sheet = sprite.sheets[sheet_num]
    lg.drawq(sheet.image, sheet.quads[quad_num], 0, 0)
end
