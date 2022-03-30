# -----------------------------------------------------------------------------
# description: General Python Makefile
# author: Daniel Kovacs <mondomhogynincsen@gmail.com>
# package: gpf-python
# package-note: This file is part of the Python General Package Format library
# package-url: github.com/ultralightweight/gpf
# licence: MIT <https://opensource.org/licenses/MIT>
# file-version: 3.5
# supported: virtualenv, pytest
# -----------------------------------------------------------------------------

SHELL=/bin/bash

# -----------------------------------------------------------------------------
# package config
# -----------------------------------------------------------------------------

PACKAGE_SOURCES=src
PACKAGE_TEST=test
PACKAGE_ENVIRONMENT_FILE=.environment


# -----------------------------------------------------------------------------
# build config
# -----------------------------------------------------------------------------

BUILD_DIR=build
BUILD_DIST_DIR=dist
BUILD_TARGET=sdist
BUILD_ARGS=
DIST_FILE=$(BUILD_DIST_DIR)/$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.gz
DIST_HANDLE=$(BUILD_DIST_DIR)/.dist
SOURCES := $(shell find $(PACKAGE_SOURCES) -name '*.py')


# -----------------------------------------------------------------------------
# python config
# -----------------------------------------------------------------------------

PYTHON_VERSION="python"


# -----------------------------------------------------------------------------
# virtualenv config
# -----------------------------------------------------------------------------

VIRTUALENV_DIR=.virtualenv
VIRTUALENV_HOME=$(VIRTUALENV_DIR)
VIRTUALENV_ACTIVATE=$(VIRTUALENV_HOME)/bin/activate


# -----------------------------------------------------------------------
# define checkenv-start-validation
# -----------------------------------------------------------------------

define checkenv-start-validation
	@echo "checking environment...."
	@rm -f $(PACKAGE_ENVIRONMENT_FILE)
endef


# -----------------------------------------------------------------------
# define checkenv-command
# -----------------------------------------------------------------------

define checkenv-command
	@printf "checking $(1)..." && (type $(1) >> $(PACKAGE_ENVIRONMENT_FILE) 2>&1 && echo "ok") || (echo "error: $(1) not found" >> $(PACKAGE_ENVIRONMENT_FILE) && echo "NOT FOUND" && true)
endef


# -----------------------------------------------------------------------
# define checkenv-validate
# -----------------------------------------------------------------------

define checkenv-validate
	@(grep error $(PACKAGE_ENVIRONMENT_FILE) > /dev/null 2>&1 && rm -f $(PACKAGE_ENVIRONMENT_FILE) || true)
	@( [ -f $(PACKAGE_ENVIRONMENT_FILE) ] || (echo "error: invalid environment configuration.\n\nPlease install the missing packages listed above.\n" && false) )
endef


# -----------------------------------------------------------------------
# target: _recheckenv
# -----------------------------------------------------------------------

_recheckenv::
	@rm -f $(PACKAGE_ENVIRONMENT_FILE)


# -----------------------------------------------------------------------
# target: checkenv
# -----------------------------------------------------------------------

.PHONY: checkenv
checkenv:: _recheckenv $(PACKAGE_ENVIRONMENT_FILE)


# -----------------------------------------------------------------------
# target: $(PACKAGE_ENVIRONMENT_FILE)
# -----------------------------------------------------------------------

$(PACKAGE_ENVIRONMENT_FILE):: Makefile
	$(call checkenv-start-validation)
	$(call checkenv-command,git)
	$(call checkenv-command,python)
	$(call checkenv-command,pip)
	$(call checkenv-command,virtualenv)
#	# $(call checkenv-command,wget)
#	# $(call checkenv-command,docker)
	$(call checkenv-validate)


# -----------------------------------------------------------------------------
# cleanup
# -----------------------------------------------------------------------------

.PHONY:cleanup
cleanup::
	find . -name "*.pyc" -exec rm -rf {} \; 2>&1 > /dev/null || true
	find . -name "__pycache__" -exec rm -rf {} \; 2>&1 > /dev/null || true
	find . -name "._*" -exec rm -rf {} \; 2>&1 > /dev/null || true
	find . -name ".DS_Store" -exec rm -rf {} \; 2>&1 > /dev/null || true


# -----------------------------------------------------------------------------
# clean
# -----------------------------------------------------------------------------

.PHONY:clean
clean:: cleanup
	rm -rf $(PACKAGE_ENVIRONMENT_FILE) $(VIRTUALENV_HOME) $(ASSETS_HOME) activate build dist .cache .eggs .tmp *.egg-info src/*.egg-info


# -----------------------------------------------------------------------------
# $(VIRTUALENV_HOME)
# -----------------------------------------------------------------------------

$(VIRTUALENV_HOME):: $(PACKAGE_ENVIRONMENT_FILE)
	virtualenv --python $(PYTHON_VERSION) $@
	ln -sf $(VIRTUALENV_ACTIVATE) activate
	touch $@


# -----------------------------------------------------------------------------
# virtualenv
# -----------------------------------------------------------------------------

.PHONY: virtualenv
virtualenv: $(VIRTUALENV_HOME)


# -----------------------------------------------------------------------------
# $(VIRTUALENV_HOME)/deps
# -----------------------------------------------------------------------------

$(VIRTUALENV_HOME)/deps:: requirements.txt $(VIRTUALENV_HOME)
	source activate && pip install -r $<
	source activate && pip install -e .
	touch $@


# -----------------------------------------------------------------------------
# $(VIRTUALENV_HOME)/deps-%
# -----------------------------------------------------------------------------

$(VIRTUALENV_HOME)/deps-%:: requirements-%.txt $(VIRTUALENV_HOME)/deps
	source activate && pip install -r $<
	touch $@


# -----------------------------------------------------------------------------
# deps
# -----------------------------------------------------------------------------

deps:: $(VIRTUALENV_HOME)/deps


# -----------------------------------------------------------------------------
# deps-build
# -----------------------------------------------------------------------------

deps-build:: $(VIRTUALENV_HOME)/deps-build


# -----------------------------------------------------------------------------
# deps-test
# -----------------------------------------------------------------------------

deps-test:: $(VIRTUALENV_HOME)/deps-test


# -----------------------------------------------------------------------------
# deps-docs
# -----------------------------------------------------------------------------

deps-docs:: $(VIRTUALENV_HOME)/deps-docs


# -----------------------------------------------------------------------
# lint
# -----------------------------------------------------------------------

.PHONY: lint
lint:: $(VIRTUALENV_HOME)/deps-test
	source activate && pylint $(PACKAGE_SOURCES)/


# -----------------------------------------------------------------------
# target: test-modules
# -----------------------------------------------------------------------

.PHONY: test-modules
test-modules:: $(VIRTUALENV_HOME)/deps-test lint
	source activate && pytest $(PACKAGE_SOURCES)/


# -----------------------------------------------------------------------
# target: test-e2e
# -----------------------------------------------------------------------

.PHONY: test-e2e
test-e2e:: $(VIRTUALENV_HOME)/deps-test
	source activate && pytest test/


# -----------------------------------------------------------------------
# target: test
# -----------------------------------------------------------------------

.PHONY: test
test:: $(VIRTUALENV_HOME)/deps-test
	source activate && pylint $(PACKAGE_SOURCES)/
	source activate && pytest --cov $(PACKAGE_SOURCES)/ $(PACKAGE_SOURCES)/ $(PACKAGE_TEST)/ docs/ README.rst


# -----------------------------------------------------------------------
# target: test-%
# -----------------------------------------------------------------------

test-%:: $(PACKAGE_TEST)/%_test.py $(VIRTUALENV_HOME)/deps-test
	source activate && pytest $<


# -----------------------------------------------------------------------------
# shell
# -----------------------------------------------------------------------------

shell: deps
	source activate && python -i shell.py


# -----------------------------------------------------------------------------
# shell-
# -----------------------------------------------------------------------------

shell-%:: ./prototypes/%.py
	source activate && python -i $<


# -----------------------------------------------------------------------------
# proto-
# -----------------------------------------------------------------------------

proto-%:: ./prototypes/%.py
	source activate && python $<


# -----------------------------------------------------------------------
# $(DIST_FILE)
# -----------------------------------------------------------------------

$(DIST_HANDLE):: requirements*.txt $(SOURCES) $(VIRTUALENV_HOME)/deps-build
	@echo "[gpf] Modified dependencies since last build: $?"
	source activate && python setup.py $(BUILD_TARGET) $(BUILD_ARGS)
	@echo "[gpf] Found distribution files:"
	@ls -la $(BUILD_DIST_DIR)
	@touch $@


# -----------------------------------------------------------------------
# dist
# -----------------------------------------------------------------------

dist:: $(DIST_HANDLE)


# -----------------------------------------------------------------------
# build
# -----------------------------------------------------------------------

build:: dist


# -----------------------------------------------------------------------
# docs
# -----------------------------------------------------------------------

.PHONY: docs
docs:: $(VIRTUALENV_HOME)/deps-docs
	source activate && sphinx-build -M html docs/ $(BUILD_DIR)/docs/
	# source activate && rstcheck README.rst

# -----------------------------------------------------------------------
# apidocs
# -----------------------------------------------------------------------

apidocs:: $(VIRTUALENV_HOME)/deps-docs
	rm -rf docs/apidoc
	source activate && sphinx-apidoc --tocfile index --separate --module-first --output-dir docs/apidoc $(PACKAGE_SOURCES)/$(PACKAGE_NAME)


# -----------------------------------------------------------------------------
# setup
# -----------------------------------------------------------------------------

setup:: $(VIRTUALENV_HOME)/deps-test $(VIRTUALENV_HOME)/deps-build $(VIRTUALENV_HOME)/deps-docs



# -----------------------------------------------------------------------
# install
# -----------------------------------------------------------------------

install:: $(SOURCES)
	./setup.py install


# -----------------------------------------------------------------------------
# bump-%
# -----------------------------------------------------------------------------

bump-%:: $(VIRTUALENV_HOME)/deps-build
	rm -rf dist
	source activate && bumpversion --list --commit --tag $(subst bump-,,$@)


# -----------------------------------------------------------------------------
# release-minor
# -----------------------------------------------------------------------------

release-minor: test bump-minor build


# -----------------------------------------------------------------------------
# release-patch
# -----------------------------------------------------------------------------

release-patch: test bump-patch build


# -----------------------------------------------------------------------------
# release-major
# -----------------------------------------------------------------------------

release-major: test bump-major build


# -----------------------------------------------------------------------------
# release
# -----------------------------------------------------------------------------

release:: test build


# -----------------------------------------------------------------------------
# release
# -----------------------------------------------------------------------------

publish:: dist
	source activate && twine upload dist/*

# -----------------------------------------------------------------------
# include package specific targets (if there is any)
# -----------------------------------------------------------------------

-include package.mk


$(VIRTUALENV_HOME)/notebook-setup:: $(VIRTUALENV_HOME)/deps-notebook
	source activate && \
	jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
	jupyter nbextension enable --py --sys-prefix qgrid 
#	jupyter nbextension enable --py --sys-prefix ipyaggrid
	touch $@

notebook:: $(VIRTUALENV_HOME)/notebook-setup
	source activate && jupyter notebook --notebook-dir prototypes/ --NotebookApp.token='' --no-browser



