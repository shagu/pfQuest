VERSION = $(shell git describe --abbrev=0 --tags)
GITREV = $(shell git describe --tags)

all: clean stripdb full enUS koKR frFR deDE zhCN esES ruRU full-tbc enUS-tbc koKR-tbc frFR-tbc deDE-tbc zhCN-tbc esES-tbc ruRU-tbc

clean:
	rm -rfv release

stripdb:
	toolbox/compressdb.sh

full:
	$(eval LOCALE := $(shell echo $@))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest/
	cp -rf compat db img init *.toc *.lua LICENSE README.md release/$@/pfQuest/

	# generate new toc file
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	echo $(GITREV) > release/$@/pfQuest/gitrev.txt

	# remove tbc data
	find release/$@/pfQuest -name "*-tbc*" -exec rm {} \;
	( cd release/$@; zip -qr ../pfQuest-$@.zip pfQuest )

full-tbc:
	$(eval LOCALE := $(shell echo $@))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest-tbc/
	cp -rf compat db img init *.toc *.lua LICENSE README.md release/$@/pfQuest-tbc/

	# generate new toc file
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest-tbc/pfQuest.toc
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest-tbc/pfQuest-tbc.toc
	echo $(GITREV) > release/$@/pfQuest-tbc/gitrev.txt
	( cd release/$@; zip -qr ../pfQuest-$@.zip pfQuest-tbc )

enUS koKR frFR deDE zhCN esES ruRU:
	$(eval LOCALE := $(shell echo $@))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest/init release/$@/pfQuest/db/enUS release/$@/pfQuest/db/${LOCALE}
	cp -rf compat img release/$@/pfQuest/

	cp -f $(shell ls db/*.lua | grep -v "\-tbc") release/$@/pfQuest/db
	cp -f $(shell ls db/enUS/*.lua | grep -v "\-tbc") release/$@/pfQuest/db/enUS
	cp -f $(shell ls db/${LOCALE}/*.lua | grep -v "\-tbc") release/$@/pfQuest/db/${LOCALE}
	cp -f *.lua LICENSE README.md release/$@/pfQuest/
	cp -f init/addon.xml init/data.xml init/enUS.xml init/${LOCALE}.xml release/$@/pfQuest/init
	cp -f pfQuest.toc release/$@/pfQuest/pfQuest.toc

	# generate new toc file
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest/pfQuest.toc
	sed -i '/init\\/d' release/$@/pfQuest/pfQuest.toc
	sed -i '/^[[:space:]]*$$/d' release/$@/pfQuest/pfQuest.toc
	/bin/echo 'init\data.xml' >> release/$@/pfQuest/pfQuest.toc
	/bin/echo 'init\enUS.xml' >> release/$@/pfQuest/pfQuest.toc
	/bin/echo 'init\$(LOCALE).xml' >> release/$@/pfQuest/pfQuest.toc
	/bin/echo 'init\addon.xml' >> release/$@/pfQuest/pfQuest.toc

	echo $(GITREV) > release/$@/pfQuest/gitrev.txt
	( cd release/$@; zip -qr ../pfQuest-$@.zip pfQuest )

enUS-tbc koKR-tbc frFR-tbc deDE-tbc zhCN-tbc esES-tbc ruRU-tbc:
	$(eval LOCALE := $(shell echo $@ | sed 's/-tbc//g'))
	@echo "===== building ${LOCALE} ====="
	mkdir -p release/$@/pfQuest-tbc/init release/$@/pfQuest-tbc/db/enUS release/$@/pfQuest-tbc/db/${LOCALE}
	cp -rf compat img release/$@/pfQuest-tbc/

	cp -f $(shell ls db/*.lua) release/$@/pfQuest-tbc/db
	cp -f $(shell ls db/enUS/*.lua) release/$@/pfQuest-tbc/db/enUS
	cp -f $(shell ls db/${LOCALE}/*.lua) release/$@/pfQuest-tbc/db/${LOCALE}
	cp -f *.lua LICENSE README.md release/$@/pfQuest-tbc/
	cp -f init/addon.xml init/data.xml init/data-tbc.xml init/enUS.xml init/enUS-tbc.xml init/${LOCALE}.xml init/${LOCALE}-tbc.xml release/$@/pfQuest-tbc/init
	cp -f pfQuest-tbc.toc release/$@/pfQuest-tbc/pfQuest-tbc.toc

	# generate new toc file
	sed -i "s/GIT/$(VERSION)/g" release/$@/pfQuest-tbc/pfQuest-tbc.toc
	sed -i '/init\\/d' release/$@/pfQuest-tbc/pfQuest-tbc.toc
	sed -i '/^[[:space:]]*$$/d' release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\data.xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\data-tbc.xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\enUS.xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\enUS-tbc.xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\$(LOCALE).xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\${LOCALE}-tbc.xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc
	/bin/echo 'init\addon.xml' >> release/$@/pfQuest-tbc/pfQuest-tbc.toc

	echo $(GITREV) > release/$@/pfQuest-tbc/gitrev.txt
	( cd release/$@; zip -qr ../pfQuest-$@.zip pfQuest-tbc )

database:
	$(MAKE) -C toolbox/ all

rebuild: database all

locales:
	toolbox/find_locales.sh
