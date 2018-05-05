all: clean zones professions database install

clean:
	rm -rf output

database:
	lua ./extractor.lua

zones:
	sh ./zones.sh

professions:
	sh ./professions.sh

install:
	cp -rf output/* ../db/
	rm -rf output
