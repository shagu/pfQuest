VERSION = $(shell git describe --abbrev=0 --tags)
GITREV = $(shell git describe --tags)

all: clean stripdb enUS koKR frFR deDE zhCN esES ruRU noLoc enUS-tbc koKR-tbc frFR-tbc deDE-tbc zhCN-tbc esES-tbc ruRU-tbc noLoc-tbc

clean:
	rm -rfv release

stripdb:
	toolbox/compressdb.sh

enUS koKR frFR deDE zhCN esES ruRU:
	$(eval LOCALE := $(shell echo $@))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest/init release/$@/pfQuest/db/${LOCALE}

	cp -rf compat img release/$@/pfQuest/

	cp -f $(shell ls db/*.lua | grep -v "\-tbc") release/$@/pfQuest/db
	cp -f $(shell ls db/${LOCALE}/*.lua | grep -v "\-tbc") release/$@/pfQuest/db/${LOCALE}
	cp -f *.lua LICENSE README.md release/$@/pfQuest/
	cp -f init/addon.xml init/data.xml init/${LOCALE}.xml release/$@/pfQuest/init
	cp -f pfQuest.toc release/$@/pfQuest/pfQuest.toc

	# generate new toc file
	sed -i "s/NORELEASE/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	sed -i '/init\\/d' release/$@/pfQuest/pfQuest.toc
	sed -i '/^[[:space:]]*$$/d' release/$@/pfQuest/pfQuest.toc
	echo "init\data.xml" >> release/$@/pfQuest/pfQuest.toc
	echo "init\${LOCALE}.xml" >> release/$@/pfQuest/pfQuest.toc
	echo "init\addon.xml" >> release/$@/pfQuest/pfQuest.toc

	echo $(GITREV) > release/$@/pfQuest/gitrev.txt

noLoc:
	$(eval LOCALE := $(shell echo enUS))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest/init release/$@/pfQuest/db/${LOCALE}

	cp -rf compat img db init release/$@/pfQuest/
	cp -f *.lua *.toc LICENSE README.md release/$@/pfQuest/

	# skip loading of language databases
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest/init/deDE*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest/init/esES*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest/init/frFR*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest/init/koKR*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest/init/ruRU*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest/init/zhCN*.xml
	rm -f release/$@/pfQuest/db/{deDE,esES,frFR,koKR,ruRU,zhCN}/{items,units,objects,quests}*.lua

	# remove TBC
	find release/$@/pfQuest/ -iname "*-tbc*" -exec rm -rf {} \;

	# update toc file version
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	echo $(GITREV) > release/$@/pfQuest/gitrev.txt

enUS-tbc koKR-tbc frFR-tbc deDE-tbc zhCN-tbc esES-tbc ruRU-tbc:
	$(eval LOCALE := $(shell echo $@ | sed 's/-tbc//g'))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest-tbc/init release/$@/pfQuest-tbc/db/${LOCALE}

	cp -rf compat img release/$@/pfQuest-tbc/

	cp -f $(shell ls db/*.lua) release/$@/pfQuest-tbc/db
	cp -f $(shell ls db/${LOCALE}/*.lua) release/$@/pfQuest-tbc/db/${LOCALE}
	cp -f *.lua LICENSE README.md release/$@/pfQuest-tbc/
	cp -f init/addon.xml init/data.xml init/data-tbc.xml init/${LOCALE}.xml init/${LOCALE}-tbc.xml release/$@/pfQuest-tbc/init
	cp -f pfQuest-tbc.toc release/$@/pfQuest-tbc/pfQuest-tbc.toc

	# generate new toc file
	sed -i "s/NORELEASE/$(VERSION)/g" release/$@/pfQuest-tbc/pfQuest-tbc.toc
	sed -i '/init\\/d' release/$@/pfQuest-tbc/pfQuest-tbc.toc
	sed -i '/^[[:space:]]*$$/d' release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\data.xml" >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\${LOCALE}.xml" >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\data-tbc.xml" >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\${LOCALE}-tbc.xml" >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\addon.xml" >> release/$@/pfQuest-tbc/pfQuest-tbc.toc

	echo $(GITREV) > release/$@/pfQuest-tbc/gitrev.txt

noLoc-tbc:
	$(eval LOCALE := $(shell echo enUS))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest-tbc/init release/$@/pfQuest-tbc/db/${LOCALE}

	cp -rf compat img db init release/$@/pfQuest-tbc/
	cp -f *.lua *.toc LICENSE README.md release/$@/pfQuest-tbc/

	# skip loading of language databases
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest-tbc/init/deDE*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest-tbc/init/esES*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest-tbc/init/frFR*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest-tbc/init/koKR*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest-tbc/init/ruRU*.xml
	sed -i "/items\|units\|objects\|quests/d" release/$@/pfQuest-tbc/init/zhCN*.xml
	rm -f release/$@/pfQuest-tbc/db/{deDE,esES,frFR,koKR,ruRU,zhCN}/{items,units,objects,quests}*.lua

	# update toc file version
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo $(GITREV) > release/$@/pfQuest-tbc/gitrev.txt

database:
	$(MAKE) -C toolbox/ all

rebuild: database all

locales:
	toolbox/find_locales.sh
