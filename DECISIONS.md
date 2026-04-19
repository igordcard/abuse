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
- Default install layout is an `abuse.app` bundle at the install prefix.
  Running from the shell uses `open $(PREFIX)/abuse.app`; the Makefile
  `make run` wraps this.
