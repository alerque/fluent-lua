PACKAGE_NAME = fluent

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

VERSION != git describe --tags --always --abbrev=7 | sed 's/-/-r/'
SEMVER != git describe --tags | sed 's/^v//;s/-.*//'
ROCKREV = 0
TAG ?= v$(SEMVER)

LUAROCKS_ARGS ?= --local --tree lua_modules

DEV_SPEC = $(PACKAGE_NAME)-dev-$(ROCKREV).rockspec
DEV_ROCK = $(PACKAGE_NAME)-dev-$(ROCKREV).src.rock
REL_SPEC = rockspecs/$(PACKAGE_NAME)-$(SEMVER)-$(ROCKREV).rockspec
REL_ROCK = $(PACKAGE_NAME)-$(SEMVER)-$(ROCKREV).src.rock

.PHONY: all
all: rockspecs dist

.PHONY: rockspecs
rockspecs: $(DEV_SPEC) $(REL_SPEC)

.PHONY: dist
dist: $(DEV_ROCK) $(REL_ROCK)

.PHONY: install
install:
	luarocks $(LUAROCKS_ARGS) make $(DEV_SPEC)

define rockpec_template =
	sed -e "s/@SEMVER@/$(SEMVER)/g" \
		-e "s/@ROCKREV@/$(ROCKREV)/g" \
		-e "s/@TAG@/$(TAG)/g" \
		$< > $@
endef

$(DEV_SPEC): SEMVER = dev
$(DEV_SPEC): TAG = master
$(DEV_SPEC): $(PACKAGE_NAME).rockspec.in
	$(rockpec_template)
	sed -i \
		"1i -- DO NOT EDIT! Modify template $< and rebuild with \`make $@\`" \
		-e '/tag =/s/tag/branch/' \
		$@

rockspecs/$(PACKAGE_NAME)-%-$(ROCKREV).rockspec: SEMVER = $*
rockspecs/$(PACKAGE_NAME)-%-$(ROCKREV).rockspec: TAG = v$*
rockspecs/$(PACKAGE_NAME)-%-$(ROCKREV).rockspec: $(PACKAGE_NAME).rockspec.in
	$(rockpec_template)
	sed -i \
		-e '/rockspec_format/s/3.0/1.0/' \
		-e '/url = "git/a\   dir = "fluent-lua",' \
		-e '/issues_url/d' \
		-e '/maintainer/d' \
		-e '/labels/d' \
		$@

$(PACKAGE_NAME)-dev-$(ROCKREV).src.rock: $(DEV_SPEC)
	luarocks $(LUAROCKS_ARGS) pack $<

$(PACKAGE_NAME)-%.src.rock: rockspecs/$(PACKAGE_NAME)-%.rockspec
	luarocks $(LUAROCKS_ARGS) pack $<

.PHONY: check
check:
	luacheck .

.PHONY: test
test:
	busted

.PHONY: release
release: CHANGELOG.md rockspecs/fluent-$(SEMVER)-$(ROCKREV).rockspec
	git add $^
	git commit -m "chore(release): $(SEMVER)"
	git tag $(TAG)

CHANGELOG.md:
	git-cliff -p $@ -u $(if $(TAG),-t $(TAG))

.PHONY: force
force:;

$(MAKEFILE_LIST):;
