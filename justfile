alias b := build
alias c := clean
alias f := format
alias s := serve

dist := "./dist"
purescript-module := "RspRood"
port := "8000"

# list available recipes
default:
    just --list

# build the project
[group("build")]
build: build-index (build-template "aankondiging") (build-template "evenement") (build-template "tekst")

# make the build directory
[group("build")]
_build-dir:
    mkdir -p {{dist}}

# build the index page
[group("build")]
build-index: _build-dir build-style build-images
    cp html/index.html {{dist}}/index.html

# build the specified template
[group("build")]
build-template template: _build-dir build-style build-images
    @echo "Building template {{template}}…"
    spago bundle --minify --module "{{purescript-module}}.{{uppercamelcase(template)}}" --outfile "{{dist}}/{{uppercamelcase(template)}}.js"
    cp "html/{{lowercase(template)}}.html" "{{dist}}/{{lowercase(template)}}.html"

# move style to build directory
[group("build")]
build-style: _build-dir
    cp style/style.css {{dist}}/style.css
    cp -r style/fonts {{dist}}/fonts

# move images to build directory
[group("build")]
build-images: _build-dir
    cp -r img/ {{dist}}

# clean the build directory
[group("build")]
clean: _build-dir
    rm -r {{dist}}

# install to given directory
[group("install")]
install prefix: build
    mkdir -p "{{prefix}}"
    cp -r "{{dist}}" "{{prefix}}"

# generate .tidyoperators file for formatting
[group("format")]
_format-generate-operators:
	spago sources | xargs purs-tidy generate-operators > .tidyoperators

# format PureScript source
[group("format")]
format: _format-generate-operators
	purs-tidy format-in-place "src/**/*.purs"

# check if formatting is needed
[group("format")]
format-check: _format-generate-operators
	purs-tidy check "src/**/*.purs"

# start a HTTP server of the built project
[group("test")]
serve:
    python -m http.server -d {{dist}} -b 127.0.0.1 {{port}}
