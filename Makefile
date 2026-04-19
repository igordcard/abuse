UNAME_S := $(shell uname -s)

BUILD_DIR ?= build
PREFIX    ?= $(HOME)/.local
JOBS      ?= $(shell (command -v nproc >/dev/null && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Version string derived from git tags. Matches the format baked into the
# binary by CMake and shown on the title screen. Falls back to 0.0.0 if git
# or tags are not available.
VERSION := $(shell git describe --tags --long --match 'v*' 2>/dev/null | \
    awk -F- '{n=split($$1,p,"."); printf "%s.%s.%d-%s\n", p[1], p[2], p[3]+$$2, substr($$3,2)}' \
    | sed 's/^v//' 2>/dev/null || echo 0.0.0)

ifeq ($(UNAME_S),Darwin)
    OS       := macos
    APP_PATH := $(PREFIX)/abuse.app
    RUN_CMD  := open "$(APP_PATH)"
else ifeq ($(UNAME_S),Linux)
    OS       := linux
    APP_PATH := $(PREFIX)/bin/abuse
    RUN_CMD  := "$(APP_PATH)"
else
    $(error Unsupported platform: $(UNAME_S). Use the CMake build directly.)
endif

.PHONY: all help configure setup build install run version clean distclean

all: setup

help:
	@echo "Targets:"
	@echo "  setup     configure and build (default)"
	@echo "  install   build and install to PREFIX"
	@echo "  run       launch the installed game"
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
	@echo ""
	@echo "Installed to: $(APP_PATH)"
	@echo "Run with: make run   (or: $(RUN_CMD))"

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
