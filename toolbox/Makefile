all: clean enUS koKR frFR deDE zhCN esES ruRU

clean:
	rm -rf output

enUS koKR frFR deDE zhCN esES ruRU:
	@echo "===== building $@ ====="
	@mkdir -p output/$@
	php ./items.php $@
	php ./quests.php $@
	php ./vendors.php $@
	php ./spawns.php $@
	sh ./zones.sh $@

install:
	cp -rf output/* ../db/
	rm -rf output
