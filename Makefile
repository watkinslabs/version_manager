# Makefile for wl_version_manager
# BSD 3-Clause License

PYTHON := python3
PIP := pip3
MODULE_NAME := wl_version_manager
VERSION := $(shell cat VERSION)
PKG_MGR := dnf

.PHONY: help clean build test install uninstall upload-test upload-prod deps-dev deps

help:
	@echo "Available targets:"
	@echo "  clean         - Remove build artifacts"
	@echo "  build         - Build the package"
	@echo "  test          - Run tests"
	@echo "  install       - Install package locally"
	@echo "  uninstall     - Remove package"
	@echo "  upload-test   - Upload to PyPI test"
	@echo "  upload-prod   - Upload to PyPI production"
	@echo "  deps-dev      - Install development dependencies"
	@echo "  deps          - Install system dependencies"
	@echo "  current-version - Show current version"
	@echo "  set-version   - Set specific version"
	@echo "  init-version  - Initialize VERSION file"

# System dependencies (Fedora/CentOS)
deps:
	sudo $(PKG_MGR) install -y python3-pip python3-wheel python3-setuptools

# Development dependencies
deps-dev: deps
	$(PIP) install --user twine pytest

# Clean build artifacts
clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	rm -rf .pytest_cache/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# Build the package
build: clean increment-version
	$(PYTHON) setup.py sdist

# Version management using self (bootstrapped)
increment-version:
	@if [ ! -f VERSION ]; then $(PYTHON) -m ${MODULE_NAME}.cli init; fi
	$(PYTHON) -m ${MODULE_NAME}.cli patch

bump-minor:
	$(PYTHON) -m ${MODULE_NAME}.cli minor

bump-major:
	$(PYTHON) -m ${MODULE_NAME}.cli major

set-version:
	@read -p "Enter version (e.g., 1.2.3): " version; \
	$(PYTHON) -m ${MODULE_NAME}.cli set $version

current-version:
	$(PYTHON) -m ${MODULE_NAME}.cli current

init-version:
	$(PYTHON) -m ${MODULE_NAME}.cli init

# Run tests
test:
	$(PYTHON) -m pytest -v

# Install package locally
install: build
	$(PIP) install --user dist/$(MODULE_NAME)-$(VERSION).tar.gz

# Uninstall package
uninstall:
	$(PIP) uninstall -y $(MODULE_NAME)

# Install in development mode
install-dev:
	$(PIP) install --user -e .

# Upload to PyPI test
upload-test: build
	$(PYTHON) -m twine upload --repository testpypi dist/*

# Upload to PyPI production
upload-prod: build
	$(PYTHON) -m twine upload dist/*

# Pipenv workflow targets
pipenv-install:
	pipenv install $(MODULE_NAME)==$(VERSION)

pipenv-install-test:
	pipenv install -i https://test.pypi.org/simple/ $(MODULE_NAME)==$(VERSION)

pipenv-remove:
	pipenv uninstall $(MODULE_NAME)

# Development workflow
dev-setup: deps-dev install-dev

# Test workflow
test-all: test

# Release workflow
release-test: test-all upload-test
release-prod: test-all upload-prod

# Quick check
check: test

# Show package info
info:
	@echo "Package: $(MODULE_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Python: $(shell $(PYTHON) --version)"
	@echo "Pip: $(shell $(PIP) --version)"