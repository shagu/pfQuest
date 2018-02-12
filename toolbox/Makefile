all: clean zones database install

clean:
	rm -rf output

database:
	lua ./extractor.lua

zones:
	sh ./zones.sh

install:
	cp -rf output/* ../db/
	rm -rf output
