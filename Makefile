DOCKER_TAG = dev

GULP := node_modules/.bin/gulp

# Unless the user has specified otherwise in their environment, it's probably a
# good idea to refuse to install unless we're in an activated virtualenv.
ifndef PIP_REQUIRE_VIRTUALENV
PIP_REQUIRE_VIRTUALENV = 1
endif
export PIP_REQUIRE_VIRTUALENV

.PHONY: default
default: test

build/manifest.json: node_modules/.uptodate
	$(GULP) build

## Clean up runtime artifacts (needed after a version update)
.PHONY: clean
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	rm -f node_modules/.uptodate .pydeps
	rm -rf build

## Run the development H server locally
.PHONY: dev
dev: build/manifest.json .pydeps
	@bin/hypothesis --dev init
	@bin/hypothesis devserver

## Build hypothesis/hypothesis docker image
.PHONY: docker
docker:
	git archive HEAD | docker build -t hypothesis/hypothesis:$(DOCKER_TAG) -

## Run test suite
.PHONY: test
test: node_modules/.uptodate
	@pip install -q tox
	tox
	$(GULP) test

################################################################################

# Fake targets to aid with deps installation
.pydeps: requirements.txt
	@echo installing python dependencies
	@pip install --use-wheel -r requirements-dev.in tox
	@touch $@

node_modules/.uptodate: package.json
	@echo installing javascript dependencies
	@node_modules/.bin/check-dependencies 2>/dev/null || npm install
	@touch $@

# i18n
PY_FILES = $(shell find h/ -type f -name '*.py')
JINJA2_FILES = $(shell find h/templates -type f -name '*.jinja2')
LOCALE_DOMAIN = h
LOCALE_PATH = h/locale
PO_FILES = $(shell find $(LOCALE_PATH) -type f -name '*.po')
MO_FILES = $(patsubst %.po, %.mo, $(PO_FILES))

i18n: $(MO_FILES)

i18n-zh_TW: $(LOCALE_PATH)/zh_TW/LC_MESSAGES/$(LOCALE_DOMAIN).po

$(LOCALE_PATH)/zh_TW/LC_MESSAGES/$(LOCALE_DOMAIN).po: $(LOCALE_PATH)/$(LOCALE_DOMAIN).pot
	@pybabel update -l zh_TW -D $(LOCALE_DOMAIN) -d $(LOCALE_PATH) -i $(LOCALE_PATH)/$(LOCALE_DOMAIN).pot

$(LOCALE_PATH)/%/LC_MESSAGES/$(LOCALE_DOMAIN).mo: $(LOCALE_PATH)/%/LC_MESSAGES/$(LOCALE_DOMAIN).po
	@pybabel compile -f -D $(LOCALE_DOMAIN) -d $(LOCALE_PATH)

$(LOCALE_PATH)/$(LOCALE_DOMAIN).pot: $(PY_FILES) $(JINJA2_FILES)
	@pybabel extract -F babel.cfg h -o $(LOCALE_PATH)/$(LOCALE_DOMAIN).pot

# Self documenting Makefile
.PHONY: help
help:
	@echo "The following targets are available:"
	@echo " clean      Clean up runtime artifacts (needed after a version update)"
	@echo " dev        Run the development H server locally"
	@echo " docker     Build hypothesis/hypothesis docker image"
	@echo " test       Run the test suite (default)"
	@echo " i18n-zh_TW Update the zh_TW language file"
	@echo " i18n       Compile language files"
