VERSION = $(shell git describe --abbrev=0 --tags)
GITREV = $(shell git describe --tags)

all: clean stripdb enUS koKR frFR deDE zhCN esES ruRU noLoc

clean:
	rm -rfv release

stripdb:
	toolbox/compressdb.sh

enUS koKR frFR deDE zhCN esES ruRU:
	@echo "===== building $@ ====="
	mkdir -p release/$@/pfQuest/db
	cp -rf compat release/$@/pfQuest/
	cp -rf img release/$@/pfQuest/
	cp -rf db/*.lua release/$@/pfQuest/db
	cp -rf db/$@ release/$@/pfQuest/db
	cp -rf browser.lua database.lua map.lua quest.lua config.lua slashcmd.lua pfQuest.toc LICENSE README.md release/$@/pfQuest/
	sed -i "s/NORELEASE/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	sed -i -r '/'"$@"'/!s/db\\.*\\.*\.lua/# N\/A/g' release/$@/pfQuest/pfQuest.toc
	echo $(GITREV) > release/$@/pfQuest/gitrev.txt

noLoc:
	@echo "===== building $@ ====="
	mkdir -p release/$@/pfQuest/db
	cp -rf compat release/$@/pfQuest/
	cp -rf img release/$@/pfQuest/
	cp -rf db/*.lua release/$@/pfQuest/db
	cp -rf db/enUS release/$@/pfQuest/db

	mkdir -p release/$@/pfQuest/db/koKR release/$@/pfQuest/db/frFR release/$@/pfQuest/db/deDE release/$@/pfQuest/db/zhCN release/$@/pfQuest/db/esES release/$@/pfQuest/db/ruRU

	cp -rf db/koKR/zones.lua release/$@/pfQuest/db/koKR/
	cp -rf db/frFR/zones.lua release/$@/pfQuest/db/frFR/
	cp -rf db/deDE/zones.lua release/$@/pfQuest/db/deDE/
	cp -rf db/zhCN/zones.lua release/$@/pfQuest/db/zhCN/
	cp -rf db/esES/zones.lua release/$@/pfQuest/db/esES/
	cp -rf db/ruRU/zones.lua release/$@/pfQuest/db/ruRU/

	cp -rf db/koKR/professions.lua release/$@/pfQuest/db/koKR/
	cp -rf db/frFR/professions.lua release/$@/pfQuest/db/frFR/
	cp -rf db/deDE/professions.lua release/$@/pfQuest/db/deDE/
	cp -rf db/zhCN/professions.lua release/$@/pfQuest/db/zhCN/
	cp -rf db/esES/professions.lua release/$@/pfQuest/db/esES/
	cp -rf db/ruRU/professions.lua release/$@/pfQuest/db/ruRU/

	cp -rf browser.lua database.lua map.lua quest.lua config.lua slashcmd.lua pfQuest.toc LICENSE README.md release/$@/pfQuest/
	sed -i "s/NORELEASE/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	sed -i -r '/enUS|professions|zones/!s/db\\.*\\.*\.lua/# N\/A/g' release/$@/pfQuest/pfQuest.toc
	echo $(GITREV) > release/$@/pfQuest/gitrev.txt

database:
	$(MAKE) -C toolbox/ all

rebuild: database all

locales:
	toolbox/find_locales.sh
