SELFPKG := github.com/carnivalmobile/drone
VERSION := 0.2
SHA := $(shell git rev-parse --short HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
.PHONY := test

all: embed build

build:
	go build -o bin/drone -ldflags "-X main.version $(VERSION)dev-$(SHA)" $(SELFPKG)/drone
	go build -o bin/droned -ldflags "-X main.version $(VERSION)dev-$(SHA)" $(SELFPKG)/droned

build-dist: godep
	godep go build -o bin/drone -ldflags "-X main.version $(VERSION)-$(SHA)" $(SELFPKG)/drone
	godep go build -o bin/droned -ldflags "-X main.version $(VERSION)-$(SHA)" $(SELFPKG)/droned

bump-deps: deps vendor

deps:
	go get -u -t -v ./...

vendor: godep
	godep save ./...

# Embed static assets
embed: js rice
	cd droned   && rice embed
	cd template && rice embed

js:
	cd droned/assets && find js -name "*.js" ! -name '.*' ! -name "main.js" -exec cat {} \; > js/main.js

test:
	godep go test -v ./...

install:
	cp deb/drone/etc/init/drone.conf /etc/init/drone.conf
	test -f /etc/default/drone || cp deb/drone/etc/default/drone /etc/default/drone
	cd bin && install -t /usr/local/bin drone
	cd bin && install -t /usr/local/bin droned
	mkdir -p /var/lib/drone

clean: rice
	cd droned   && rice clean
	cd template && rice clean
	rm -rf drone/drone
	rm -rf droned/droned
	rm -rf droned/drone.sqlite
	rm -rf bin/drone
	rm -rf bin/droned
	rm -rf deb/drone.deb
	rm -rf usr/local/bin/drone
	rm -rf usr/local/bin/droned
	rm -rf drone.sqlite
	rm -rf /tmp/drone.sqlite

# creates a debian package for drone
# to install `sudo dpkg -i drone.deb`
dpkg:
	mkdir -p deb/drone/usr/local/bin
	mkdir -p deb/drone/var/lib/drone
	mkdir -p deb/drone/var/cache/drone
	cp bin/drone  deb/drone/usr/local/bin
	cp bin/droned deb/drone/usr/local/bin
	-dpkg-deb --build deb/drone

run:
	bin/droned --port=":8080" --datasource="drone.sqlite"

godep:
	go get github.com/tools/godep

rice:
	go get github.com/GeertJohan/go.rice/rice
	go build github.com/GeertJohan/go.rice/rice
