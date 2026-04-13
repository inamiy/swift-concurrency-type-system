DIAGRAMS_DIR = docs/diagrams
GENERATED_DIR = docs/generated
SPLIT_MMD_SH = docs/scripts/split-func-conversion-mmd.sh
FULL_MMD = $(DIAGRAMS_DIR)/func-conversion-rules.mmd
REGION_MMD = $(DIAGRAMS_DIR)/region-merge.mmd
MMDC = slide/node_modules/.bin/mmdc -p puppeteer-config.json

DIAGRAM_FILES = func-conversion-sync func-conversion-async func-conversion region-merge-semilattice

# Install dependencies and generate assets needed for slide build
.PHONY: setup
setup:
	npm ci --prefix slide
	$(MAKE) diagrams

# Split .mmd sources, render SVG/PNG into docs/generated/, and create symlinks
.PHONY: diagrams
diagrams: $(FULL_MMD) $(REGION_MMD)
	@mkdir -p $(GENERATED_DIR)
	@# Split full .mmd into sync/async variants
	$(SPLIT_MMD_SH) $(FULL_MMD) $(GENERATED_DIR)
	@# Render SVG and PNG
	$(MMDC) -i $(GENERATED_DIR)/func-conversion-sync.mmd -o $(GENERATED_DIR)/func-conversion-sync.svg -t default -b transparent
	$(MMDC) -i $(GENERATED_DIR)/func-conversion-sync.mmd -o $(GENERATED_DIR)/func-conversion-sync.png -t default -b transparent -s 3
	$(MMDC) -i $(GENERATED_DIR)/func-conversion-async.mmd -o $(GENERATED_DIR)/func-conversion-async.svg -t default -b transparent
	$(MMDC) -i $(GENERATED_DIR)/func-conversion-async.mmd -o $(GENERATED_DIR)/func-conversion-async.png -t default -b transparent -s 3
	$(MMDC) -i $(FULL_MMD) -o $(GENERATED_DIR)/func-conversion.svg -t default -b transparent
	$(MMDC) -i $(FULL_MMD) -o $(GENERATED_DIR)/func-conversion.png -t default -b transparent -s 3
	$(MMDC) -i $(REGION_MMD) -o $(GENERATED_DIR)/region-merge-semilattice.svg -t dark -b transparent
	$(MMDC) -i $(REGION_MMD) -o $(GENERATED_DIR)/region-merge-semilattice.png -t dark -b transparent -s 3
	@# Symlink: paper/figures → docs/generated
	@ln -sfn "../$(GENERATED_DIR)" paper/figures
	@# Symlink: slide/src/assets → only SVGs used by slides
	@for f in $(DIAGRAM_FILES); do \
		ln -sf "../../../$(GENERATED_DIR)/$$f.svg" "slide/src/assets/$$f.svg"; \
	done
	@echo "Diagrams generated and symlinked."

.PHONY: outputs
outputs:
	$(MAKE) -C slide html
	$(MAKE) -C slide pdf
	$(MAKE) -C paper pdf

.PHONY: markdown-toc
markdown-toc:
	cd docs/scripts && swift run markdown-toc ../typing-rules-ja.md ../typing-rules-en.md --minlevel 2 --fix-anchors

.PHONY: clean
clean:
	fd --hidden "^\.build$$" | xargs -I{} rm -rf  {}
	fd --hidden "^\.swiftpm$$" | xargs -I{} rm -rf  {}
	rm -rf docs/generated
	$(MAKE) -C slide clean
	$(MAKE) -C paper clean
