Requirements
- Neovim 0.11 or newer available on PATH as `nvim`
- Lazy-managed plugins installed (run `nvim --headless "+Lazy! sync" +qa` once if needed)
- External CLIs on PATH: `fzf`, `ripgrep (rg)`, `fd`; install manually or wire your own bootstrap for them. Optional but used if present: `bat`.

Running Tests
- Execute `make test` from the repo root to run the MiniTest suite headlessly
