# Claude Instructions for Abuse

## Key Documents

- **[README.md](README.md)** -- Project overview
- **[BUILDING.md](BUILDING.md)** -- Build prerequisites and cmake/make flow
- **[DECISIONS.md](DECISIONS.md)** -- Record of design and implementation decisions
- **[Makefile](Makefile)** -- Development commands (`make help` for the list)

## Rules

- When asked to commit, create the commit directly, overriding any global
  decision stating otherwise. Bundle everything changed since the last commit
  into a single commit with a message that reflects all changes. Do not add
  Co-Authored-By lines. Keep the commit title (first line) under 80
  characters. Keep the full commit message under 100 characters per line.
- Any time a measurable change has been done to the application or a new
  decision has been made, update `DECISIONS.md`.
- Breaking changes are acceptable while pre-1.0. Do not add backwards
  compatibility shims (fallbacks, legacy key support, deprecation warnings)
  unless explicitly requested.
- When a major version bump is requested (e.g. 0.x to 1.0.0), proactively
  recommend backwards compatibility decisions that should be made at that
  point: save/config format stability, migration tooling, deprecation
  policies. Ask the developer before proceeding.

## Releasing

When the user says "release the next minor version" (or "release the next
major version"), follow this process:

1. **Verify clean state**: ensure the working tree is clean and all commits
   are pushed to the remote.
2. **Determine the new version**: run
   `git tag -l --sort=-version:refname | head -1` to find the latest tag.
   Bump the minor (e.g. `v26.0.0` -> `v26.1.0`) or major (e.g. `v26.9.0` ->
   `v27.0.0`) as requested.
3. **Review commits**: run
   `git log <previous_tag>..HEAD --format="%h %s%n%b---"` to read all commit
   titles and descriptions since the last tag. For the very first release of
   this fork, use `git log --author="Igor DC" --reverse --format="%h %s%n%b---"`
   starting from the first fork commit.
4. **Tag and push**: `git tag <new_tag> && git push origin <new_tag>`.
5. **Build the release artifact**: run `make dist` on each target platform
   (currently only macOS is supported). This produces
   `dist/Abuse-v<version>-<os>-<arch>.zip` containing the signed-bundle
   layout (macOS) or a tarball (Linux). The archive name includes the OS
   and `uname -m` architecture so multiple artifacts can coexist on a
   single release.
6. **Write release notes**: create a curated, user-oriented changelog grouped
   by theme (not one entry per commit). Use this format:
   - Group related commits into sections with `###` headings (e.g. "Gameplay",
     "Build / Packaging", "Fixes", "Developer").
   - Each entry is a bullet starting with a **bold summary** followed by a
     short description.
   - Omit internal refactors, test-only changes, and documentation-only
     commits unless they are notable.
   - End with a separator line and a "Full Changelog" link to the repo's
     `compare/<previous_tag>...<new_tag>` URL. For the first release of the
     fork, mention that this line of versions started as a fork of
     `metinc/abuse` so the provenance is clear in the changelog story.
7. **Create the release and attach artifacts**:
   `gh release create <new_tag> --title "<new_tag>" --notes "<notes>" <artifacts...>`.
   Pass every archive produced by step 5 as positional arguments so they are
   uploaded as release assets.
8. **For major versions**: before tagging, proactively recommend backwards
   compatibility decisions (save/config format stability, migration tooling,
   deprecation policies) and ask the developer before proceeding.
