.PHONY: all build test app dmg run clean

all: build

build:
	swift build

test:
	swift test

app:
	bash scripts/build_app.sh

dmg:
	bash scripts/build_dmg.sh

run:
	swift run MacXP

clean:
	rm -rf .build build
