UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

BUILD_DIR ?= build
JOBS      ?= $(shell (command -v nproc >/dev/null && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4)
DIST_DIR  ?= dist

# Version string derived from git tags. Matches the format baked into the
# binary by CMake and shown on the title screen. Falls back to 0.0.0 if git
# or tags are not available.
VERSION := $(shell git describe --tags --long --match 'v*' 2>/dev/null | \
    awk -F- '{n=split($$1,p,"."); printf "%s.%s.%d-%s\n", p[1], p[2], p[3]+$$2, substr($$3,2)}' \
    | sed 's/^v//' 2>/dev/null || echo 0.0.0)

ifeq ($(UNAME_S),Darwin)
    OS           := macos
    # ~/Applications is scanned by Launchpad / Spotlight; /Applications would
    # require sudo. `$(HOME)/.local` is not scanned, so installing there
    # hides the app from the macOS launcher.
    PREFIX       ?= $(HOME)/Applications
    APP_PATH     := $(PREFIX)/abuse.app
    RUN_CMD      := open "$(APP_PATH)"
    DIST_ARCHIVE := $(DIST_DIR)/Abuse-v$(VERSION)-macos-$(UNAME_M).zip
else ifeq ($(UNAME_S),Linux)
    OS           := linux
    PREFIX       ?= $(HOME)/.local
    APP_PATH     := $(PREFIX)/bin/abuse
    RUN_CMD      := "$(APP_PATH)"
    DIST_ARCHIVE := $(DIST_DIR)/Abuse-v$(VERSION)-linux-$(UNAME_M).tar.gz
else
    $(error Unsupported platform: $(UNAME_S). Use the CMake build directly.)
endif

.PHONY: all help configure setup build install run version dist clean distclean

all: setup

help:
	@echo "Targets:"
	@echo "  setup     configure and build (default)"
	@echo "  install   build and install to PREFIX"
	@echo "  run       launch the installed game"
	@echo "  dist      build a redistributable archive in $(DIST_DIR)/"
	@echo "  version   print the version derived from git tags"
	@echo "  clean     remove the build directory"
	@echo "  distclean alias for clean"
	@echo ""
	@echo "Variables (override on command line):"
	@echo "  PREFIX    install prefix       [default: $(PREFIX)]"
	@echo "  BUILD_DIR cmake build dir      [default: $(BUILD_DIR)]"
	@echo "  JOBS      parallel build jobs  [default: $(JOBS)]"
	@echo ""
	@echo "Detected OS: $(OS)"
	@echo "Install target: $(APP_PATH)"

# Always invoke cmake so PREFIX changes take effect. The install prefix is
# baked into the binary (ASSETDIR), so we cannot just override it at install
# time — we must reconfigure whenever it changes. CMake itself no-ops when
# nothing has changed, so this stays cheap.
configure:
	cmake -B "$(BUILD_DIR)" -DCMAKE_INSTALL_PREFIX="$(PREFIX)"

setup: configure
	cmake --build "$(BUILD_DIR)" -j $(JOBS)

build: setup

install: setup
	cmake --install "$(BUILD_DIR)"
ifeq ($(OS),macos)
	@# Force Launch Services to re-scan the bundle so Launchpad and
	@# Spotlight pick up the newly installed / updated app immediately.
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
	    -f "$(APP_PATH)" >/dev/null 2>&1 || true
endif
	@echo ""
	@echo "Installed to: $(APP_PATH)"
	@echo "Run with: make run   (or: $(RUN_CMD))"

# Build a redistributable archive for the current host. On macOS we use
# `ditto` with the sequester-resources flag so extended attributes, code
# signatures and the bundle layout survive a round-trip through unzip.
# The archive is self-contained — it includes the .app bundle with all
# game data under Contents/Resources/data.
dist: setup
	@mkdir -p "$(DIST_DIR)"
	@rm -rf "$(DIST_DIR)/stage" && mkdir -p "$(DIST_DIR)/stage"
	cmake --install "$(BUILD_DIR)" --prefix "$(DIST_DIR)/stage"
ifeq ($(OS),macos)
	@rm -f "$(DIST_ARCHIVE)"
	ditto -c -k --sequesterRsrc --keepParent \
	    "$(DIST_DIR)/stage/abuse.app" "$(DIST_ARCHIVE)"
else
	@rm -f "$(DIST_ARCHIVE)"
	tar -czf "$(DIST_ARCHIVE)" -C "$(DIST_DIR)/stage" .
endif
	@rm -rf "$(DIST_DIR)/stage"
	@echo ""
	@echo "Archive: $(DIST_ARCHIVE)"

run:
	@test -e "$(APP_PATH)" || { \
	    echo "Not installed at $(APP_PATH). Run 'make install' first."; \
	    exit 1; \
	}
	$(RUN_CMD)

version:
	@echo "$(VERSION)"

clean:
	rm -rf "$(BUILD_DIR)"

distclean: clean
