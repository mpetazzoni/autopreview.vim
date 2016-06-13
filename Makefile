GB_PKG="github.com/constabulary/gb/..."

all: server/bin/server
	@echo "\033[32;1mAutopreview server built; plugin is ready.\033[;0m"

server/src/server/static.go: static/index.html
	@echo " [STATIC] $< -> $@"
	@static/encode.py index < $< > $@

server/bin/server: server/src/server/static.go | gb
	@echo " [GO    ] $@"
	@cd server && gb build > /dev/null

gb:
	@echo " [GO GET] ${GB_PKG}"
	@go get ${GB_PKG}

clean:
	@rm -f server/bin/server server/src/server/static.go
