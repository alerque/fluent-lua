PACKAGE = fluent

SHELL := zsh
.SHELLFLAGS := +o nomatch -e -c

.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PRECIOUS:
.DELETE_ON_ERROR:
.SUFFIXES:

JOBS ?= $(shell nproc 2>- || sysctl -n hw.ncpu 2>- || echo 1)
MAKEFLAGS += -j$(JOBS) -Otarget

VERSION != git describe --tags --all --abbrev=7 | sed 's/-/-r/'
SEMVER != git describe --tags | sed 's/^v//;s/-.*//'
ROCKREV = 0
TAG = v$(SEMVER)

LUAROCKS_ARGS ?= --local --tree lua_modules

SCM_ROCK = $(PACKAGE)-dev-0.rockspec
REL_ROCK = rockspecs/$(PACKAGE)-$(SEMVER)-$(ROCKREV).rockspec
SCM_SRC = $(PACKAGE)-dev-0.src.rock
REL_SRC = $(PACKAGE)-$(SEMVER)-$(ROCKREV).src.rock

.PHONY: all
all: $(SCM_ROCK) $(SCM_SRC)

.PHONY: dist
dist: $(REL_ROCK) $(REL_SRC)

.PHONY: install
install:
	luarocks $(LUAROCKS_ARGS) make $(SCM_ROCK)

define rockpec_template =
	sed -e "s/@SEMVER@/$(SEMVER)/g" \
		-e "s/@ROCKREV@/$(ROCKREV)/g" \
		-e "s/@TAG@/$(TAG)/g" \
		$< > $@
endef

$(SCM_ROCK): SEMVER = dev
$(SCM_ROCK): TAG = master
$(SCM_ROCK): $(PACKAGE).rockspec.in
	$(rockpec_template)

rockspecs/$(PACKAGE)-%-0.rockspec: SEMVER = $*
rockspecs/$(PACKAGE)-%-0.rockspec: TAG = v$*
rockspecs/$(PACKAGE)-%-0.rockspec: $(PACKAGE).rockspec.in
	$(rockpec_template)

$(PACKAGE)-dev-0.src.rock: $(SCM_ROCK)
	luarocks $(LUAROCKS_ARGS) pack $<

$(PACKAGE)-%.src.rock: rockspecs/$(PACKAGE)-%.rockspec
	luarocks $(LUAROCKS_ARGS) pack $<

.PHONY: check
check:
	luacheck .

.PHONY: test
test:
	busted

.PHONY: force
force:;

$(MAKEFILE_LIST):;
