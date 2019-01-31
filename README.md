# git-blame-nvim

git-blame-nvim is a neovim plugin that displays git blame information after EOL of the current line.

![](https://user-images.githubusercontent.com/33946/52085090-af514700-25f7-11e9-81ff-2640e0705411.png)

It's neovim only as I don't believe vim has a way to display virtual text yet.

## Usage:

Just install (using your favourite vim plugin management solution). It will be enabled automatically on subsequent launches, but when you first install it you will need to manually enable it:

`:call GitBlameEnable()`
