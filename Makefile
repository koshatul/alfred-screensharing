.PHONY: all
all: artifacts/build/ScreenSharing.alfredworkflow

.PHONY: docker-build
docker-build: docker-build-image
	docker run -ti --rm -v "$(shell pwd):/code" --workdir /code alfred-screensharing:build make inside-docker-build

.PHONY: clean
clean:
	$(RM) -r artifacts

.PHONY: docker-build-image
docker-build-image: build/Dockerfile
	docker build -t alfred-screensharing:build -f build/Dockerfile .

.PHONY: inside-docker-build
inside-docker-build:
	make artifacts/build/ScreenSharing.alfredworkflow

artifacts/escaped/script.sh.docker:
	mkdir -p "$(@D)"
	docker run -ti --rm -v "$(shell pwd):/code" --workdir /code perl:5 make inside-docker-build

artifacts/escaped/script.sh: src/script.sh
	mkdir -p "$(@D)"
	perl -p -e 'BEGIN { use CGI qw(escapeHTML); } $$_ = escapeHTML($$_);' src/script.sh > "$(@)"

artifacts/build/ScreenSharing.alfredworkflow: artifacts/src/icon.png artifacts/src/info.plist
	mkdir -p "$(@D)"
	zip -j9 --filesync "$(@)" artifacts/src/*

artifacts/src/icon.png:	assets/icon.png
	mkdir -p "$(@D)"
	cp "$(<)" "$(@)"

artifacts/src/info.plist: assets/info.plist artifacts/escaped/script.sh
	mkdir -p "$(@D)"
	perl -pe 'BEGIN {open(FH, "<", "artifacts/escaped/script.sh"); local $$/; $$r = <FH>; close(FH); chomp($$r)}; s/HTMLENTITY_BASH_SCRIPT/$$r/ge' "$(<)" > "$(@)"
