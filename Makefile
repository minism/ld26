out=bin/puzzlebot.love
url=http://minornine.com/games/files/$(out)

all: build

build:
	zip -r $(out) * -x ./assets/\* ./bin/\* ./dist/\*
	@echo "Wrote $(out)"

dist: build
	mkdir -p dist
	rm -rf dist/*

	# OSX
	cp -RP bin/love.app dist/puzzlebot.app
	cp ${out} dist/puzzlebot.app/Contents/Resources

	# Win32
	rm -rf /tmp/win32 && mkdir -p /tmp/win32
	cat bin/love-0.8.0-win-x86/love.exe ${out} > /tmp/win32/puzzlebot-win32.exe
	cp bin/love-0.8.0-win-x86/*.dll /tmp/win32/
	cd /tmp/win32/ && zip -r puzzlebot-win32.zip *
	mv /tmp/win32/puzzlebot-win32.zip dist

	# Win64
	rm -rf /tmp/win64 && mkdir -p /tmp/win64
	cat bin/love-0.8.0-win-x86/love.exe ${out} > /tmp/win64/puzzlebot-win64.exe
	cp bin/love-0.8.0-win-x86/*.dll /tmp/win64/
	cd /tmp/win64/ && zip -r puzzlebot-win64.zip *
	mv /tmp/win64/puzzlebot-win64.zip dist


clean:
	rm -rf $(out)
	rm -rf dist

upload: all
	scp $(out) m:web/games/files/
	echo $(url) | pbcopy
	@echo "Copied $(url)"
