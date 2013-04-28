menu = Context()



function menu:lose()
    assets.mus.mus1:stop()
    app:swapContext(self)
    self.qtimer = 0
end

function menu:draw()
    local text = string.format([[
        You died on phase %s


        %s Blocks Cleared
        

        Press any key to play again, or escape to quit
    ]], game.phasen, game.total_clears)

    lg.clear()
    lg.setFont(assets.fontLarge)
    colors.score2()
    local padding = 25
    lg.printf(text, padding, 250, lg.getWidth() - padding * 2, 'center')
end

function menu:update(dt)
    self.qtimer = self.qtimer + dt
end

function menu:keypressed()
    if self.qtimer > 0.5 then
        if input.down('quit') then
            love.event.quit()
        else
            app:swapContext(game)
            game:init()
        end
    end
end
