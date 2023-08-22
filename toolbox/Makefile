all: clean database install

clean:
	rm -rf output

database:
	lua ./extractor.lua

install:
	cp -rf output/* ../db/
	rm -rf output

turtle:
	cp -rf ../db/custom/* ../../pfQuest-turtle/db/
	rm -rf ../db/custom
