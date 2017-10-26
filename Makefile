VERSION = $(shell git describe --abbrev=0 --tags)

all: clean enUS koKR frFR deDE zhCN esES ruRU

clean:
	rm -rfv release

enUS koKR frFR deDE zhCN esES ruRU:
	@echo "===== building $@ ====="
	mkdir -p release/$@/pfQuest/db
	cp -rf compat release/$@/pfQuest/
	cp -rf img release/$@/pfQuest/
	cp -rf db/init.lua release/$@/pfQuest/db
	cp -rf db/$@ release/$@/pfQuest/db
	cp -rf pfBrowser.lua pfDatabase.lua pfMap.lua pfQuest.lua pfQuestConfig.lua pfQuest.toc release/$@/pfQuest/
	sed -i "s/NORELEASE/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	cd release/$@ && zip -qr9 ../pfQuest-$(VERSION)-$@.zip pfQuest

database:
	$(MAKE) -C toolbox/ all
	$(MAKE) -C toolbox/ install

rebuild: database all
