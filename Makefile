out=bin/puzzlebot.love
url=http://minornine.com/games/files/$(out)

all: build

build:
	zip -r $(out) * -x ./assets/\* ./bin/\* ./dist/\*
	@echo "Wrote $(out)"

dist: build
	# OSX
	cp -RP bin/love.app dist/puzzlebot.app
	cp ${out} dist/puzzlebot.app/Contents/Resources


clean:
	rm -rf $(out)

upload: all
	scp $(out) m:web/games/files/
	echo $(url) | pbcopy
	@echo "Copied $(url)"
