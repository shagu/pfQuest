VERSION = $(shell git describe --abbrev=0 --tags)

all: clean enUS koKR frFR deDE zhCN esES ruRU

clean:
	rm -rfv release

enUS koKR frFR deDE zhCN esES ruRU:
	@echo "===== building $@ ====="
	mkdir -p release/$@/pfQuest/db
	cp -rf compat release/$@/pfQuest/
	cp -rf img release/$@/pfQuest/
	cp -rf db/*.lua release/$@/pfQuest/db
	cp -rf db/$@ release/$@/pfQuest/db
	cp -rf browser.lua database.lua map.lua quest.lua config.lua slashcmd.lua pfQuest.toc LICENSE README.md release/$@/pfQuest/
	sed -i "s/NORELEASE/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	cd release/$@ && zip -qr9 ../pfQuest-$(VERSION)-$@.zip pfQuest

database:
	$(MAKE) -C toolbox/ all

rebuild: database all
