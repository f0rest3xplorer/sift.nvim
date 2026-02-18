# sift.nvim

A lightweight, asynchronous security scanner for Neovim powered by [Opengrep](https://github.com/opengrep/opengrep). 

`sift.nvim` allows you to run static analysis security scans on your files or entire projects directly from your editor, displaying results in a searchable [Snacks.picker](https://github.com/folke/snacks.nvim).

## Features

- **Async Scanning**: Non-blocking `vim.system` calls so your UI doesn't freeze during a scan.
- **Snacks Integration**: Leverages the Snacks.nvim picker for results, including code previews and finding details.
- **Resume Support**: Instantly reopen your last scan results without re-running the tool.
- **Severity Filtering**: Dedicated hotkeys to filter between Errors and Warnings within the picker.
- **Health Checks**: Built-in diagnostics via `:checkhealth sift`.

## Requirements

- **Neovim** 0.10+
- **[Opengrep](https://github.com/opengrep/opengrep)**: Must be installed and available in your `$PATH`.
- **[Snacks.nvim](https://github.com/folke/snacks.nvim)**: Used for the results UI and notifications.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "f0rest3xplorer/sift.nvim",
  dependencies = { "folke/snacks.nvim" },
  keys = {
    { "<leader>Sp", "<cmd>SiftProject<cr>", desc = "Sift Project" },
    { "<leader>Sf", "<cmd>SiftFile<cr>", desc = "Sift File" },
    { "<leader>Sr", "<cmd>SiftResume<cr>", desc = "Sift Resume Last" },
  },
  config = function()
    -- Optional: Setup which-key labels if using WhichKey
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>S", group = "Sift", icon = "󰭎 " },
      })
    end
  end,
}
```

## Usage

### Commands
- `:SiftProject` — Scans the current working directory.
- `:SiftFile` — Scans the currently active buffer.
- `:SiftResume` — Reopens the picker with the results from the most recent scan.

### Picker Navigation
When the Sift picker is open:
- `<C-e>`: Filter the list to show **ERROR** severity only.
- `<C-w>`: Filter the list to show **WARNING** severity only.
- `<Enter>`: Jump to the file, line, and column of the finding.
- `<Esc>`: Close the picker.

## Troubleshooting

If the plugin isn't working as expected, run:
```vim
:checkhealth sift
