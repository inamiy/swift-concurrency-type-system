SHELL := /bin/bash
.DEFAULT_GOAL := help

MAIN := main
BUILD_DIR := build

PAPER_PDF := ../swift-concurrency-type-system-paper.pdf

.PHONY: help pdf clean

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make pdf    Build the paper PDF via tectonic' \
		'  make clean  Remove all build artifacts'

pdf: | $(BUILD_DIR)
	@# First pass: generate .bbl in build/
	tectonic -o $(BUILD_DIR) --keep-intermediates --reruns 0 $(MAIN).tex 2>/dev/null || true

	@# Copy .bbl to source dir so tectonic can resolve citations
	cp -f $(BUILD_DIR)/$(MAIN).bbl $(MAIN).bbl 2>/dev/null || true

	@# Full build with citations resolved
	tectonic -o $(BUILD_DIR) --reruns 10 $(MAIN).tex

	cp -f $(BUILD_DIR)/$(MAIN).pdf $(PAPER_PDF)

$(BUILD_DIR):
	@mkdir -p $@

clean:
	rm -rf $(BUILD_DIR) $(MAIN).bbl

	# Remove symlinks
	find figures -type l -delete 2>/dev/null || true

	@echo 'removed generated build artifacts'
