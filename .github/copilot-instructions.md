# Repository instructions

## Setup and validation

This repository is the Doom user configuration (`$DOOMDIR`), normally checked out
at `~/.config/doom`. Doom itself lives separately at `~/.config/emacs`.

- New-machine setup: install the apt prerequisites in `README.md`, then run
  `./bootstrap.sh`. This builds Emacs 31 into `~/.local`, installs Doom, fonts,
  CLI tools and language servers, runs Doom sync, and builds tree-sitter grammars.
  It changes the local environment; use the targeted commands below for edits.
- Install Rust via rustup, Node 22.13+ via nvm, and JDK 21+ separately. Mermaid
  needs Node 22.13+, the TypeScript server needs Node 20+, and `copilot` must be
  on PATH for agent-shell.
- After changing `init.el` or `packages.el`, run
  `~/.config/emacs/bin/doom sync`, then restart Emacs. `config.el` edits do not
  require sync.
- Rebuild missing tree-sitter grammars with `emacs --batch -l ts-grammars.el`.
- Start a GUI session with `emacs --daemon && emacsclient -c`.

Run these syntax checks from the repository root:

```sh
bash -n bootstrap.sh
sh -n bin/typescript-language-server
sh -n bin/mmdc
emacs -Q --batch --eval '(dolist (file (append (directory-files default-directory t "\\.el$") (directory-files "themes" t "\\.el$"))) (with-temp-buffer (insert-file-contents file) (emacs-lisp-mode) (check-parens)))'
```

For a single Lisp file:

```sh
emacs -Q --batch --eval '(with-temp-buffer (insert-file-contents "config.el") (emacs-lisp-mode) (check-parens))'
```

These check syntax, not Doom runtime behavior. Validate UI changes in a graphical
Doom session, especially daemon-created frames, layout restoration, the Magit
sidebar, and opening/reusing/closing native diff windows.

## Architecture

- `init.el` selects Doom modules and flags; `packages.el` declares additional
  packages; `config.el` implements runtime behavior. Use Doom's package/module
  lifecycle rather than treating these as standalone Emacs startup files.
  Completion uses Corfu/Orderless and Vertico; language tooling uses Eglot with
  Java, JavaScript, and Rust modules configured for LSP and tree-sitter.
- `config.el` loads `magit-frame.el` via `load!`. Status occupies a left side
  window; a per-worktree `DOOM_COMMIT_DRAFT` pane appears beneath it and seeds
  empty new-commit editors. Keep native commit review, existing messages, and
  draft recovery on cancellation/failure; clear drafts only after success.
  Tracked-file `RET` and other Magit
  diff commands use a separate reusable native frame, with `q` restoring focus
  to the originating window. Terminal sessions use ordinary Emacs windows.
- `themes/doom-jetbrains-theme.el` is a local Doom theme, selected by `doom-theme`
  in `config.el`. Keep palette and face definitions there rather than adding
  competing runtime face overrides; tabs and Magit share the same palette.
- Session persistence combines eager desktop buffer restoration, Doom's
  workspace backend, and the main window state under `doom-cache-dir`. Save
  before frame/workspace teardown and restore after the first GUI frame settles.
  Do not save an uninitialized startup layout over the last good snapshot.
  Restore nested splits in consistent cell units and preserve explicit client
  file positions; Emacs 31's pixelwise restoration mixes units during recursion.
  Diff, daemon, and child frames must not overwrite the editor's window state.
  Supported tool panes are recreated; running process sessions are not resumed.
- The custom emacs-dashboard replaces Doom's dashboard module. Centaur tabs group
  buffers by Projectile project. Populate the dashboard without stealing windows
  from a restored layout. Agent-shell starts new Copilot sessions and adds its
  buffers to the current Doom workspace when `persp-mode` is active.
- Markdown previews use local Pandoc/SHR rendering. Mermaid fences use the
  tracked `bin/mmdc` wrapper and an installed Chrome/Chromium to produce cached
  SVGs with HTML labels disabled for librsvg compatibility. Do not upload
  Markdown to an external rendering service or disable the browser sandbox.
- `bootstrap.sh` provisions external dependencies. Its TypeScript server symlink
  points to the repository's `bin/typescript-language-server` wrapper, which
  selects a suitable Node from nvm when necessary and supports both server
  installation layouts under `~/.local/share/tsls`.

## Conventions and coupled changes

- Declare extra dependencies with `package!` in `packages.el`; configure them with
  `use-package!` or `after!` in `config.el`. Defer package-specific overrides until
  the package loads so Doom defaults do not overwrite them. Keep settings that
  must precede package loading in `:init` or at top level.
- Custom functions and state use the `my/` prefix and lexical binding. Load local
  extensions with `load!` and define keybindings with Doom's `map!`.
- Preserve Eglot integration rather than introducing lsp-mode-specific calls.
  Rust-specific bindings cover both `rust-mode-map` and `rust-ts-mode-map`.
- Keybindings are documented in both `README.md` and the dashboard's
  `my/dashboard-insert-keys` function; keep both aligned with binding changes.
- Register commit-editor placement with `set-popup-rule!`. Doom's popup manager
  rebuilds `display-buffer-alist`, dropping entries added directly to that list.
- Server-frame hooks must enable tabs with `(centaur-tabs-mode 1)` rather than
  toggling the global mode when another client frame opens.
- Tree-sitter grammar pins in `ts-grammars.el` address Emacs 31.1.50's ABI 13-14
  compatibility. Review grammar versions and the Emacs build together; TypeScript
  and TSX also require their distinct source subdirectories.
- Keep runtime state out of tracked configuration: `.agent-shell/` and `custom.el`
  are gitignored, while persisted layout data belongs in `doom-cache-dir`.
