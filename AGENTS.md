# Agents

This document exposes the guide with each separate section with its own rules starting as H2 and subsequent (e.g. H3) headers. When reading rules - maintain heading order to correctly classify subsections for the specific rules.

## Functional patterns

The codebase follows functional programming patterns but is not exactly functional programming as a paradagim. It uses fun.lua library that is contained within the source code of The Golden Vim.

## Utilities

The codebase implements loads of utilities for various purposes - filesystem, buffers, neovim specific utilities. Each of them is well-documented or self-explanatory - prefer using them when implementing features (utils.lua)

## Documentation & trusted sources

When asked to do X related to Y plugin, always execute `nvim --cmd 'set shada=' --cmd 'let g:skip_treesitter = 1' --headless -c 'help plugin-name' -c 'set nomore' -c '%print' -c 'qa!'` while `<plugin-name>` in this query corresponds to actual plugin name. This will print the vim docs for that plugin that may be useful for your context.

### Example

- `nvim --cmd 'set shada=' --cmd 'let g:skip_treesitter = 1' --headless -c 'help fzf-lua' -c 'set nomore' -c '%print' -c 'qa!'`

### Requirements

- The plugin docs may contain references to other parts of the docs in the table of contents. Browse them using the same command with replacing `<plugin-name>` with the source it points to. Example:

```
*fzf-lua.txt*         For Neovim >= 0.9.0         Last change: 2025 October 02

==============================================================================
Table of Contents                                  *fzf-lua-table-of-contents*

Quickstart .............................................. |fzf-lua-quickstart|
Installation .......................................... |fzf-lua-installation|
Dependencies .......................................... |fzf-lua-dependencies|
```

Wanting to browse the `fzf-lua-installation`, do `nvim --cmd 'set shada=' --cmd 'let g:skip_treesitter = 1' --headless -c 'help fzf-lua-installation' -c 'set nomore' -c '%print' -c 'qa!'`. 

- Always aim to use the latest features. The baseline version you're operating on is Neovim v0.11.
