# quarto-nvim

Quarto-nvim provides tools for working on [quarto](https://quarto.org/) manuscripts in Neovim.

Quarto-nvim requires Neovim >= **v0.9.0** (https://github.com/neovim/neovim/releases/tag/stable).

## Setup

You can install `quarto-nvim` from GitHub with your favourite Neovim plugin manager
like [lazy.nvim](https://github.com/folke/lazy.nvim), [packer.nvim](https://github.com/wbthomason/packer.nvim) or [VimPlug](https://github.com/junegunn/vim-plug).

Because Quarto provides a lot of functionality through integration with existing plugins,
some of those have to be told about the existence of `quarto-nvim` (like e.g. registering
it as a source for the autocompletion plugin `nvim-cmp`).

As such, we recommend you to experiment with the [quarto-nvim kickstarter configuration](https://github.com/jmbuhr/quarto-nvim-kickstarter)
and then pick the relevant parts from the
[`lua/plugins/quarto.lua`](https://github.com/jmbuhr/quarto-nvim-kickstarter/blob/main/lua/plugins/quarto.lua) file
to integrate it into your own existing configuration.

Plugins and their configuration to look out for in this file are:

```lua
{
    'quarto-dev/quarto-nvim',
    'jmbuhr/otter.nvim',
    'hrsh7th/nvim-cmp',
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter'
}
```

## Usage

### Configure

You can pass a lua table with options to the setup function
as shown in [quarto-nvim-kickstarter/..quarto.lua](https://github.com/jmbuhr/quarto-nvim-kickstarter/blob/main/lua/plugins/quarto.lua)

It will be merged with the default options, which are shown below in the example.
If you want to use the defaults, simply call `setup` without arguments or with an empty table.

```lua
require'quarto'.setup{
  debug = false,
  closePreviewOnExit = true,
  lspFeatures = {
    enabled = true,
    languages = { 'r', 'python', 'julia', 'bash' },
    chunks = 'curly', -- 'curly' or 'all'
    diagnostics = {
      enabled = true,
      triggers = { "BufWritePost" }
    },
    completion = {
      enabled = true,
    },
  },
  keymap = {
    hover = 'K',
    definition = 'gd'
  }
}
```

### Preview

Use the command

```vim
QuartoPreview
```

or access the function from lua, e.g. to create a keybinding:

```lua
local quarto = require'quarto'
vim.keymap.set('n', '<leader>qp', quarto.quartoPreview, {silent = true, noremap = true})
```

Then use the keyboard shortcut to open `quarto preview` for the current file or project in the active working directory in the neovim integrated terminal in a new tab.

## Language support

### Demo

https://user-images.githubusercontent.com/17450586/209436101-4dd560f4-c876-4dbc-a0f4-b3a2cbff0748.mp4

### Usage

Enable quarto-nvim's lsp features by configuring it with

```lua
require'quarto'.setup{
  lspFeatures = {
    enabled = true,
  }
}
```

After enabling the language features, you can open the hover documentation
for R, python and julia code chunks with `K` (or configure a different shortcut).

### Autocompletion

`quarto-nvim` now comes with a completion source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) to deliver swift autocompletion for code in quarto code chunks.
With the quarto language features enabled, you can add the source in your `cmp` configuration:

```lua
-- ...
  sources = {
    { name = 'otter' },
  }
-- ...
```

### R diagnostics configuration

To make diagnostics work with R you have to configure the linter a bit, since the language
buffers in the background separate code with blank links, which we want to ignore.
Otherwise you get a lot more diagnostics than you probably want.
Add file `.lintr` to your home folder and fill it with:

```
linters: linters_with_defaults(
    trailing_blank_lines_linter = NULL,
    trailing_whitespace_linter = NULL
  )
```

You can now also enable other lsp features, such as the show hover function
and shortcut, independent of showing diagnostics by enabling lsp features
but not enabling diagnostics.

### Other edgecases

Other languages might have similar issues (e.g. I see a lot of warnings about whitespace when activating diagnostics with `lua`).
If you come across them and have a fix, I will be very happy about a pull request!
Or, what might ultimately be the cleaner way of documenting language specific issues, an entry in the [wiki](https://github.com/quarto-dev/quarto-nvim/wiki).

## Available Commnds

```vim
QuartoPreview
QuartoClosePreview
QuartoHelp <..>
QuartoActivate
QuartoDiagnostics
QuartoHover
```

## Recommended Plugins

Quarto works great with a number of existing plugins in the neovim ecosystem.
You can find semi-opinionated but still minimal
configurations for `nvim` and `tmux`,
for use with quarto, R and python in these two repositories:

- <https://github.com/jmbuhr/quarto-nvim-kickstarter>
- <https://github.com/jmbuhr/tmux-kickstarter>

