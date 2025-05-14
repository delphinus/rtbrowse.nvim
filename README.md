# nvim-browse.nvim

Browse Neovim runtime files on GitHub directly from your editor.

https://github.com/user-attachments/assets/ccad5b02-26a1-46bb-bdbb-a0b1df697b36

## Introduction

**nvim-browse.nvim** is a Neovim plugin that lets you open the corresponding GitHub source page for any Neovim runtime file and line(s) directly from your editor. It is useful for exploring Neovim's source code, referencing documentation, or sharing links to specific lines.

If you use this plugin on files that are not Neovim runtime files, it fallbacks to another action (default: [`Snacks.gitbrowse()`](https://github.com/folke/snacks.nvim/blob/main/docs/gitbrowse.md)). So you can use this plugin without worrying about the file you are viewing.

## Installation

Use your favorite plugin manager. Example for [lazy.nvim](https://github.com/folke/lazy.nvi):

```lua
-- You need no `opts = {}`
{ "delphinus/nvim-browse.nvim" }
```

Or, setup with full configuration. See [doc](doc/nvim-browse.txt) for the detail.

```lua
{
  "delphinus/nvim-browse.nvim",
  -- You may use this plugin with keymaps.
  keys = {
    {
      "<Leader>gB",
      function() require("nvim-browse").browse() end,
      mode = { "n", "x", "o" },
    },
  },
  -- full configuration options
  opts = {
    fallback = function()
      -- custom fallback action
    end,
    get_commit = "curl", -- or "gh"
  },
}
```

## Usage

To open the current runtime file on GitHub:

```vim
:lua require("nvim-browse").browse()
```

- If you have a visual selection, the selected lines will be highlighted in the GitHub link.
- If not, the current line will be used.

Example key mappings:

```vim
nnoremap <Leader>gB :lua require("nvim-browse").browse()<CR>
vnoremap <Leader>gB :lua require("nvim-browse").browse()<CR>
```

If the file is not a Neovim runtime file, a fallback action is triggered.
