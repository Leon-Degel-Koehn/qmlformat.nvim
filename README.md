<h1 align="center"> qmlformat.nvim </h1>

### Introduction

If you are working with QML you have probably used `qmlformat` before.
However, when you run `qmlformat` you only get the options of immediately formatting the whole file according to best practices in-place or to some specified output.
If you're like me this can sometimes prove to be somewhat useless as a lot of the steps taken in this formatting process are not really wanted by you. Your team might have
their own take on the best practices slighty varying from the official best practices.
Using this plugin - and probably a keymapping of your liking - you can now handily preview the changes that qmlformat would introduce to the current file and even interactively edit the
diff of these changes. Meaning within seconds you can now hand pick the specific formatting steps you would like to take without doing tedeous switching between consoles and such only to end up omitting some changes you would like to make or including those you would not like to make.

Main features:

- Cycle quickly through different versions of the file
![qmlformat plugin demo](https://github.com/Leon-Degel-Koehn/qmlformat.nvim/assets/106671635/cddbda8e-5caa-480f-9ca3-7fc36244c97e)


- Preview diff of changes that would be introduced in formatting

- Edit diff and apply changes
![see video](https://github.com/Leon-Degel-Koehn/qmlformat.nvim/assets/106671635/2b72155e-de10-4626-8ccf-b0b8b0626c47)




### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

Add this in your `init.lua or plugins.lua`

```lua
{
    "Leon-Degel-Koehn/qmlformat.nvim",
}
```

Or with [Packer.nvim](https://github.com/wbthomason/packer.nvim):

Add this in your `init.lua or plugins.lua`

```lua
use({ "Leon-Degel-Koehn/qmlformat.nvim"})
```

Or by hand:

```lua
use {'Leon-Degel-Koehn/qmlformat.nvim'}
```

add plugin to the `~/.local/share/nvim/site/pack/packer/start/` directory:

```vim
cd ~/.local/share/nvim/site/pack/packer/start/
git clone https://github.com/Leon-Degel-Koehn/qmlformat.nvim
```

Open `nvim` and run `:PackerInstall` to make it workable

### Plugin Config:

Upon requiring the plugin module you are free to use the `preview_qmlformat_changes` function.
Calling it will open the corresponding picker etc. that you can also see in the previews above.
Me for example I like to use this feature using a keymapping on my qml files. To achieve this I have put the following into my config.

```lua
local qmlformat = require('qmlformat')
-- you can define this however you want
vim.keymap.set('n', '<leader>q', qmlformat.preview_qmlformat_changes, {})
```
### Diff editor usage

When you are in diff editing mode you can always `:q` to abort the changes.
If you want the changes to apply you need to first run `:W` in the diff editor and the exit.
This will apply the changes in you edited diff if you have produced a valid diff with your changes.

### Dependencies

Make sure to have telescope.nvim installed to your neovim instance.
Also of course qmlformat is required, so make sure it is available on your system path.
The plugin uses both the `diff` and `patch` executable that are available on most linux distros afaik.
If this causes trouble for many users one could consider a move to using git for these things.

### Remarks

This plugin is still in a very early stage of active development.
If you have suggestions for improvement feel free to open issues or even implement stuff yourself and open a pull request.
Also with any questions I would always be happy to help.
