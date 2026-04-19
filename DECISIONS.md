# Decisions

A running record of design and implementation decisions for this fork of
Abuse. Add entries as changes are made.

## Versioning

- Version is derived from git tags at build time using
  `git describe --tags --long --match 'v*'`.
- Format: `major.minor.patch-shorthash` where `patch` is the tag's patch
  number plus the number of commits since the tag, and `shorthash` is the
  7-character commit hash. For example, tag `v26.0.0` with 3 commits on top
  produces `26.0.3-abc1234`.
- Tags can use any patch number (e.g. `v26.0.0`, `v26.0.16`). Commits since
  the tag are added to the tag's patch so the version always increases.
- Falls back to `0.0.0` (or the CMake `project()` version) if git or tags
  are not available.
- Computed in `CMakeLists.txt` and baked into the binary as
  `PACKAGE_VERSION`. The `Makefile` `VERSION` variable uses the same
  `git describe` pipeline so `make version` matches the runtime value.
- Displayed on the title / main menu screen in the bottom-left corner as
  `v{version}` using `console_font`, drawn with a 1-pixel black shadow for
  legibility over the background art. See `Game::draw_map` in `src/game.cpp`.
- First tag on this fork is `v26.0.0`. The major number was chosen
  deliberately to mark this as a distinct line from the upstream
  `v1.0.x` series; `git describe` picks the tag closest to HEAD by
  topological distance, so the new tag takes over from the older upstream
  ones for version reporting.

## Build System

- Build is driven by CMake (`CMakeLists.txt`). A convenience `Makefile`
  wraps configure + build + install + run.
- `CMAKE_CXX_STANDARD` is set to 17. `std::string::data()` returning
  non-const `char*` is relied on, and `-Wregister` / `-Wdeprecated-register`
  are silenced because legacy sources still use the `register` keyword.
- `CMAKE_INSTALL_PREFIX` is baked into the binary via the `ASSETDIR` define,
  so changing the prefix requires reconfiguring. The `Makefile`'s
  `configure` target is phony so any `PREFIX` change takes effect on the
  next invocation.
- `install(DIRECTORY ...)` is used for data, not configure-time
  `file(COPY ...)`, so a plain `cmake -B build` never tries to write to the
  install prefix.
- Bundle / binary install destinations are relative paths so
  `cmake --install --prefix ...` works without reconfiguration of the
  destination itself.

## macOS

- Homebrew packages required: `cmake sdl2 sdl2_mixer opencv glew`. OpenGL is
  provided by the system SDK. The historic `sdl` / `sdl_mixer` names refer
  to SDL 1.x and are not compatible.
- `SDL2_mixer::SDL2_mixer` from Homebrew does not declare SDL2 as a
  transitive dependency. Targets that include `SDL_mixer.h` also link
  `SDL2::SDL2` explicitly so `SDL_stdinc.h` resolves.
- `GLEW::GLEW` is the imported target from the Homebrew `glew` config; the
  legacy `${GLEW_LIBRARIES}` / `${GLEW_INCLUDE_DIRS}` variables are not
  populated by that config and must not be used.
- Default install prefix on macOS is `$HOME/Applications`, which is scanned
  by Launchpad and Spotlight. `$HOME/.local` is not scanned by either, so
  installing there hides the app from the launcher. `/Applications` is also
  valid but requires `sudo make install PREFIX=/Applications`.
- `Info.plist` requires a non-empty `CFBundleIdentifier` for Launchpad /
  Spotlight / `open -a` to index the bundle. Set via
  `MACOSX_BUNDLE_GUI_IDENTIFIER` to `com.github.igordcard.abuse`.
  `MACOSX_BUNDLE_SHORT_VERSION_STRING` and `MACOSX_BUNDLE_BUNDLE_VERSION`
  use the full `ABUSE_VERSION` string (including the commit short hash)
  so `mdls` and the Finder Info panel show the exact build.
- After installing, the Makefile runs `lsregister -f "$APP_PATH"` to force
  Launch Services to re-index the bundle so Launchpad picks up the new or
  updated app without requiring a logout / `killall Dock`.
- Data files are discovered at runtime via `CFBundleCopyBundleURL`
  (`src/sdlport/setup.cpp`) rather than the compile-time `ASSETDIR` define,
  which means the `.app` is relocatable — a user can drag it to
  `/Applications` after installing and the game still finds its data. The
  dist archive relies on this.

## Release Artifacts

- `make dist` produces a self-contained archive under `dist/` named
  `Abuse-v<version>-<os>-<arch>.<ext>` where `<arch>` is `uname -m` and
  `<ext>` is `zip` on macOS, `tar.gz` on Linux.
- On macOS the archive is built with `ditto -c -k --sequesterRsrc
  --keepParent` so extended attributes, resource forks, and the bundle
  layout survive a round-trip through unzip on other macOS machines.
- The archive name encodes OS and architecture so a single GitHub release
  can carry multiple binaries (e.g. `macos-arm64` and `macos-x86_64`)
  without collision.
