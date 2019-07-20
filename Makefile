VERSION = $(shell git describe --abbrev=0 --tags)
GITREV = $(shell git describe --tags)

all: clean stripdb enUS koKR frFR deDE zhCN esES ruRU enUS-tbc koKR-tbc frFR-tbc deDE-tbc zhCN-tbc esES-tbc ruRU-tbc

clean:
	rm -rfv release

stripdb:
	toolbox/compressdb.sh

enUS koKR frFR deDE zhCN esES ruRU:
	$(eval LOCALE := $(shell echo $@))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/${LOCALE}/pfQuest/init release/${LOCALE}/pfQuest/db/${LOCALE}

	cp -rf compat img release/${LOCALE}/pfQuest/

	cp -f $(shell ls db/*.lua | grep -v "\-tbc") release/${LOCALE}/pfQuest/db
	cp -f $(shell ls db/${LOCALE}/*.lua | grep -v "\-tbc") release/${LOCALE}/pfQuest/db/${LOCALE}
	cp -f *.lua LICENSE README.md release/${LOCALE}/pfQuest/
	cp -f init/addon.xml init/data.xml init/${LOCALE}.xml release/${LOCALE}/pfQuest/init
	cp -f pfQuest.toc release/${LOCALE}/pfQuest/pfQuest.toc

	# generate new toc file
	sed -i "s/NORELEASE/$(VERSION)/g" release/${LOCALE}/pfQuest/pfQuest.toc
	sed -i '/init\\/d' release/${LOCALE}/pfQuest/pfQuest.toc
	sed -i '/^[[:space:]]*$$/d' release/${LOCALE}/pfQuest/pfQuest.toc
	echo "init\data.xml" >> release/${LOCALE}/pfQuest/pfQuest.toc
	echo "init\${LOCALE}.xml" >> release/${LOCALE}/pfQuest/pfQuest.toc
	echo "init\addon.xml" >> release/${LOCALE}/pfQuest/pfQuest.toc

	echo $(GITREV) > release/${LOCALE}/pfQuest/gitrev.txt

enUS-tbc koKR-tbc frFR-tbc deDE-tbc zhCN-tbc esES-tbc ruRU-tbc:
	$(eval LOCALE := $(shell echo $@ | sed 's/-tbc//g'))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/${LOCALE}/pfQuest-tbc/init release/${LOCALE}/pfQuest-tbc/db/${LOCALE}

	cp -rf compat img release/${LOCALE}/pfQuest-tbc/

	cp -f $(shell ls db/*.lua) release/${LOCALE}/pfQuest-tbc/db
	cp -f $(shell ls db/${LOCALE}/*.lua) release/${LOCALE}/pfQuest-tbc/db/${LOCALE}
	cp -f *.lua LICENSE README.md release/${LOCALE}/pfQuest-tbc/
	cp -f init/addon.xml init/data.xml init/data-tbc.xml init/${LOCALE}.xml init/${LOCALE}-tbc.xml release/${LOCALE}/pfQuest-tbc/init
	cp -f pfQuest-tbc.toc release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc

	# generate new toc file
	sed -i "s/NORELEASE/$(VERSION)/g" release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	sed -i '/init\\/d' release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	sed -i '/^[[:space:]]*$$/d' release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\data.xml" >> release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\${LOCALE}.xml" >> release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\data-tbc.xml" >> release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\${LOCALE}-tbc.xml" >> release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc
	echo "init\addon.xml" >> release/${LOCALE}/pfQuest-tbc/pfQuest-tbc.toc

	echo $(GITREV) > release/${LOCALE}/pfQuest-tbc/gitrev.txt

database:
	$(MAKE) -C toolbox/ all

rebuild: database all

locales:
	toolbox/find_locales.sh
