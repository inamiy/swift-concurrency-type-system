SLIDE_SRC_DIR = src
DIST_DIR = dist
SLIDE_MD = $(SLIDE_SRC_DIR)/swift-concurrency-type-system-slide.md
THEMES = $(SLIDE_SRC_DIR)/themes
ASSETS = $(SLIDE_SRC_DIR)/assets/

DIST_SLIDE_HTML = $(DIST_DIR)/swift-concurrency-type-system-slide.html

DIST_SLIDE_PDF = $(DIST_DIR)/swift-concurrency-type-system-slide.pdf
SLIDE_PDF = ../swift-concurrency-type-system-slide.pdf

# Use local node_modules binaries instead of npx
MARP = ./node_modules/.bin/marp --no-stdin

# Offline assets: KaTeX fonts copied from node_modules
KATEX_FONTS_SRC = ./node_modules/katex/dist/fonts

.PHONY: all html watch clean pngs pdf diagrams local-assets speaker-note install-tts-kokoro uninstall-tts-kokoro mp3

all: diagrams html pdf mp3

# Delegate diagram generation to root Makefile
diagrams:
	$(MAKE) -C .. diagrams

# Copy KaTeX fonts from node_modules for offline use
local-assets:
	@mkdir -p $(DIST_DIR)/assets/fonts
	@cp -n $(KATEX_FONTS_SRC)/* $(DIST_DIR)/assets/fonts/ 2>/dev/null || true

html:
	@mkdir -p $(DIST_DIR)
	@rm -rf $(DIST_DIR)/assets
	@cp -RL $(ASSETS) $(DIST_DIR)/assets
	@$(MAKE) local-assets
	$(MARP) $(SLIDE_MD) --html --theme-set $(THEMES) -o $(DIST_SLIDE_HTML)

# Watch mode: auto-rebuild HTML on .md file save
watch:
	@mkdir -p $(DIST_DIR)
	@rm -rf $(DIST_DIR)/assets
	@cp -RL $(ASSETS) $(DIST_DIR)/assets
	@$(MAKE) local-assets
	$(MARP) $(SLIDE_MD) --html --theme-set $(THEMES) --watch --preview -o $(DIST_SLIDE_HTML)

pngs:
	@mkdir -p $(DIST_DIR)/pngs
	$(MARP) $(SLIDE_MD) --html --theme-set $(THEMES) --allow-local-files -c .marprc-export.yml --images png -o $(DIST_DIR)/pngs/swift-concurrency-type-system-slide.png

pdf:
	@mkdir -p $(DIST_DIR)
	$(MARP) $(SLIDE_MD) --html --theme-set $(THEMES) --allow-local-files -c .marprc-export.yml --pdf -o $(DIST_SLIDE_PDF)
	cp -f $(DIST_SLIDE_PDF) $(SLIDE_PDF)

# Extract speaker notes from slide markdown
SPEAKER_NOTE_DIR = $(DIST_DIR)/speaker-note
speaker-note:
	@mkdir -p $(SPEAKER_NOTE_DIR)
	$(MARP) $(SLIDE_MD) --notes -o $(SPEAKER_NOTE_DIR)/speaker-note.txt

	@# Remove timestamp lines like "00:30 (+0.5 min)" or "2:30 (+1 min)"
	@sed -i '' -E '/^[0-9]{1,2}:[0-9]{2}/d' $(SPEAKER_NOTE_DIR)/speaker-note.txt

# Kokoro TTS
KOKORO_DIR = scripts/tts-kokoro
KOKORO_VENV = $(KOKORO_DIR)/.venv
KOKORO_PY = $(KOKORO_VENV)/bin/python3
VOICE ?= af_heart
SPEED ?= 1.0
KOKORO_LANG ?= a
PAUSE ?= 0.5

# Python 3.10–3.12 required (kokoro doesn't support 3.13+)
# Uses uv for venv creation with pinned Python 3.12

# Setup Kokoro TTS: install espeak-ng + create venv + install Python deps
install-tts-kokoro:
	@command -v espeak-ng >/dev/null 2>&1 || (echo "Installing espeak-ng..." && brew install espeak-ng)
	uv venv --python 3.12 --seed $(KOKORO_VENV)
	uv pip install --python $(KOKORO_PY) -r $(KOKORO_DIR)/requirements.txt
	$(KOKORO_PY) -m unidic download
	@echo "Kokoro TTS setup complete (using $$($(KOKORO_PY) --version))."

# Remove Kokoro TTS venv
uninstall-tts-kokoro:
	rm -rf $(KOKORO_VENV)
	@echo "Kokoro TTS venv removed."

# Generate audio (wav + mp3) from transcript using Kokoro TTS
# Usage: make mp3 [FILE=path/to/transcript.txt] [VOICE=af_heart] [SPEED=1.0] [KOKORO_LANG=a] [PAUSE=0.5] [OUTPUT=output.wav]
# If FILE is omitted, auto-generates speaker-note.txt first
SPEAKER_NOTE_TXT = $(SPEAKER_NOTE_DIR)/speaker-note.txt
FILE ?= $(SPEAKER_NOTE_TXT)
mp3: speaker-note
	@test -d $(KOKORO_VENV) || (echo "Run 'make install-tts-kokoro' first." && exit 1)
	@if [ ! -f "$(FILE)" ] && [ "$(FILE)" = "$(SPEAKER_NOTE_TXT)" ]; then \
		echo "Speaker note not found, generating..."; \
		$(MAKE) speaker-note; \
	fi
	PYTORCH_ENABLE_MPS_FALLBACK=1 \
	PHONEMIZER_ESPEAK_LIBRARY="$$(brew --prefix espeak-ng 2>/dev/null)/lib/libespeak-ng.dylib" \
	ESPEAK_DATA_PATH="$$(brew --prefix espeak-ng 2>/dev/null)/share" \
	$(KOKORO_PY) $(KOKORO_DIR)/generate.py "$(FILE)" $(if $(OUTPUT),"$(OUTPUT)") \
		--voice $(VOICE) --speed $(SPEED) --lang $(KOKORO_LANG) --pause $(PAUSE)
	@WAV="$(if $(OUTPUT),$(OUTPUT),$$(echo "$(FILE)" | sed 's/\.[^.]*$$/.wav/'))"; \
	MP3="$$(echo "$$WAV" | sed 's/\.wav$$/.mp3/')"; \
	echo "Converting $$WAV → $$MP3 ..."; \
	ffmpeg -y -i "$$WAV" -codec:a libmp3lame -qscale:a 2 "$$MP3" 2>/dev/null && \
	echo "Done: $$MP3"

clean:
	rm -rf $(DIST_DIR)

	# Remove symlinks
	find $(ASSETS) -type l -delete 2>/dev/null || true
