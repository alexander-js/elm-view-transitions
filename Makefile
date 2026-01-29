.PHONY: check example clean

check:
	elm make src/ViewTransition.elm --output /dev/null

example: build/index.html
	@echo "Open build/index.html in your browser."

build/index.html: example/Main.elm example/index.template.html src/ViewTransition.elm src/ViewTransition.js | build
	elm make example/Main.elm --output build/_elm.js
	awk '/\{\{APP_JS\}\}/{system("sed \"s/^export //\" src/ViewTransition.js; cat build/_elm.js");next}1' \
	  example/index.template.html > build/index.html
	rm build/_elm.js

build:
	mkdir -p build

clean:
	rm -rf build
