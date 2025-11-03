


https://github.com/user-attachments/assets/835d7d6e-80fb-4d4e-ab8d-cbbadfa78f69


A tribute to the era before bloat. Vim, reinterpreted.

<img width="321" height="79" alt="Banner" align="right" src="https://github.com/user-attachments/assets/e011a56b-4d03-4a18-b73b-e572e8064956" />



### Features

- Written entirely in [Lua][lua] - the language that stays out of your way.
- Uncomplicated. No lazy-loading nonsense or dependency pyramids that break on edit. In modern "Vim frameworks", even the smallest change can trigger an avalanche.
- Built on NeoVim v0.11 and the [`mini.nvim`](https://github.com/echasnovski/mini.nvim) ecosystem. Because oldschool doesn't mean outdated.
- Enhanced with [LuaFun][luafun] - for `.map()`, `.filter()`, and other table operations, familiar to anyone fluent in functional programming or JavaScript.
- No dopamine-driven plugins. Only what matters for daily work.
- Uses the classic `murphy` theme - already included in Vim and Neovim. Old colors, new context.
- Straightforward, top-to-bottom configuration. No maze of directories or 999 files for 999 plugins.
- Relies on proven tools that already do the job (`rg`, `fzf`, `bat`, and friends). No pointless Lua re-implementations "just because".
- Smart, but never intrusive - LSPs, diagnostics, formatters, Git integration.
- Packed with QoL features: enhanced `:Bdelete` commands, synced terminal colors (`MiniMisc.sync_termbg`), scoped live [`ripgrep`][ripgrep] with [`fzf`][fzf],[`oil.nvim`][oil]-like keybindings for [Mini.files][minifiles] filesystem buffers, and more.
- No attempts to imitate a GUI IDE. No file tree, no icons, no floating clutter.
- Focused and reliable - works in any stack, any size. Tested inside large monorepos.

### Quality of life improvements

- Helix-style edits: yank once (`yiw`), then mutate freely—`dw`/`ciw`/`x` default to `"_` and visual `p` pastes without polluting the yank; explicit registers like `"adw` still capture text. Disabled for special buffers (help, prompt, terminal, grug-far) and can be turned off per-buffer with `vim.b.blackhole_disable = true`.
- Reliable MacOS system theme detection (dark, light) with adjusting the current Vim colors basing on built-in themes - `peachpuff` for light and `murphy` for dark. Including TextMate ports of these themes for `bat` (see [github.com/neg4n/murphy.tmTheme](https://github.com/neg4n/murphy.tmTheme) and [github.com/neg4n/peachpuff.tmTheme](https://github.com/neg4n/peachpuff.tmTheme)), made exclusively for The Golden Vim
- Easy copy of particular LSP/Linter diagnostics inside `fzf-lua` diagnostics window. Very useful for pointing external AI Agents (like OpenAI Codex) to a specific problems.

#### Customization

The codebase is small enough to understand in one sitting, and flexible enough to rebuild from scratch.  
Fork it, strip it down, or change it into something unrecognizable - it’s still yours.
If you wish to use different LSP servers or formatters, search codebase for `conform` and `blink` keywords.

## Installation

### NeoVim

If you're starting with Vim or you're getting back after the years, please install the `0.11` version through [`bob`][bob] _(a NeoVim version manager)_. This brilliant utility will save you a lot of time and struggle to get started.

Once you have [`bob`][bob] installed on your machine run `bob install 0.11` in a terminal of your choice.

### Cloning The Golden Vim

Clone the configuration into your NeoVim config directory

- Via `git`
    ```bash
    git clone https://github.com/neg4n/the-golden-vim ~/.config/nvim/ && cd ~/.config/nvim/
    ```
- Via [GitHub CLI][gh] (`gh`)
    ```bash
    gh repo clone neg4n/the-golden-vim ~/.config/nvim && cd ~/.config/nvim
    ```

> [!IMPORTANT]
> **It is strongly encouraged to back up your previous configuration to avoid data loss. If `~/.config/nvim/` is empty directory - you're safe to clone. Otherwise - do a backup.**

### Other prerequisities before running 

- [fzf][fzf] `0.60.3` 
- [ripgrep][ripgrep] `14.1.1`
- [bat][bat] `0.26.0`
- [fd][fd] `10.2.0`
- [lstr][lstr] `lstr 0.2.1`
- [lua][lua] `5.1 (LuaJIT 2.1.17x)` 

> [!NOTE]
> The version numbers near the packages do not mean that exactly one particular version is required. The Golden Vim was developed using the mentioned software with these versions and is guaranteed to work there properly. It is extremely likely it will work on other versions as well (depends on the semantic or any local versioning system).

### Optional enhancements

The Golden Vim was created with mind of [Ghostty][ghostty] terminal emulator and [Berkeley Mono][berkeleymono] typeface by [U.S. Graphics Company][usgraphics]. It'll work flawlessly in other setups but if you wish to replicate the look from the media resources - use these!

The ports of `murphy` and `peachpuff` themes for [bat][bat] (previews) can be found on the [`murphy.tmTheme`](https://github.com/neg4n/murphy.tmTheme) and [peachpuff.tmTheme](https://github.com/neg4n/peachpuff.tmTheme) repositories.

### Keymaps and bindings

#### Short intro

- Leader key is `Space`.
- Normal `<leader>n` – open MiniNotify history.
- Normal `-` – toggle the Oil file explorer in a float.
- Normal `gd` – jump to LSP definition.
- Normal `gra` - LSP code action.
- Normal `grn` - LSP rename.
- Normal `<leader>r` – format the current buffer asynchronously.
- Normal `<leader>ld` – fzf-lua diagnostics picker with yank support.
- Normal `<leader>f` – fzf-lua files.
- Normal `<leader>s` – fzf-lua document symbols.
- Normal `<leader>b` – fzf-lua buffers.
- Normal `<leader>/` – scoped live ripgrep.
- Normal `<leader>?` – pick directories, then live ripgrep.
- Normal `<leader>g` – fzf-lua Git diff view.
- Normal `<leader>vh` – fzf-lua help tags.
- Oil buffer `q` / `<Esc>` – close the floating Oil window.

#### More 

For the Git integration, type `:Git <any-command>` and explore by yourself. Refer to the [`mini.git`](https://github.com/nvim-mini/mini-git) docs eventually. The Golden Vim works best if you are used to manage Git via terminal _(it also respects your git aliases)_ and GitHub via [GitHub CLI](https://cli.github.com)

## Further customization

Here are some utilities that were in The Golden Vim originally but were removed due to clean up purposes. They may be useful if you want to customize the configuration.

<summary>

Smart path shortening function for better visual displays. 

<details>

```lua
F.path = (function()
  local FP = {}

  ---@class ShortenOpts
  ---@field keep_last integer?  -- how many last segments to keep unshortened (default 1)
  ---@field preserve_tilde boolean? -- keep leading "~" untouched (default true)
  ---@field preserve_dot_segments boolean? -- keep "." and ".." untouched (default true)

  ---@param path string
  ---@param opts ShortenOpts|nil
  ---@return string
  FP.shorten = function(path, opts)
    assert(type(path) == "string", "path must be a string")
    -- Add more validation here (opts)?

    opts = opts or {}
    local keep_last = opts.keep_last or 1
    local preserve_tilde = opts.preserve_tilde ~= false
    local preserve_dot_segments = opts.preserve_dot_segments ~= false

    if path == "" or path == "/" then
      return path
    end

    local is_abs = path:sub(1, 1) == "/"
    local has_trailing = path:sub(-1) == "/" and path ~= "/"

    local parts = {}
    for seg in path:gmatch "[^/]+" do
      table.insert(parts, seg)
    end
    local n = #parts
    if n == 0 then
      return is_abs and "/" or ""
    end

    local mapped = fun.iter(parts):enumerate():map(function(i, seg)
      if i > n - keep_last then
        return seg
      end

      if preserve_dot_segments and (seg == "." or seg == "..") then
        return seg
      end

      if preserve_tilde and i == 1 and seg == "~" then
        return seg
      end

      return seg:sub(1, 1)
    end)

    local joined = mapped:reduce(function(acc, seg)
      if acc == "" then
        return seg
      else
        return acc .. "/" .. seg
      end
    end, "")

    if is_abs then
      joined = "/" .. joined
    end
    if has_trailing then
      joined = joined .. "/"
    end
    return joined
  end

  return FP
end)()
```

</details>

</summary>

## Coming soon

- [ ] Detailed technical decisions breakdown
- [ ] More documentation (e.g. keymaps) and extended [**Further Customization**](#further-customization) section. 

# License

The MIT License.

[bob]: https://github.com/MordechaiHadad/bob 
[fzf]: https://github.com/junegunn/fzf
[ripgrep]: https://github.com/BurntSushi/ripgrep
[bat]: https://github.com/sharkdp/bat
[fd]: https://github.com/sharkdp/fd
[lstr]: https://github.com/bgreenwell/lstr
[lua]: https://lua.org/
[gh]: https://cli.github.com/
[luafun]: https://luafun.github.io/ 
[oil]: https://github.com/stevearc/oil.nvim 
[ghostty]: https://ghostty.org/
[berkeleymono]: https://usgraphics.com/products/berkeley-mono
[usgraphics]: https://usgraphics.com/
[minifiles]: https://github.com/nvim-mini/mini.files 
