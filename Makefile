all: artifacts/build/ScreenSharing.alfredworkflow

clean:
	$(RM) -r artifacts

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
	perl -MFile::Slurp -pe 'BEGIN {$$r = read_file("artifacts/escaped/script.sh"); chomp($$r)}; s/HTMLENTITY_BASH_SCRIPT/$$r/ge' "$(<)" > "$(@)"
