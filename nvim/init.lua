-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/site/pack/lazy/start/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set up plugins
require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  }
})
vim.opt.number = true        -- Show current line number
vim.opt.relativenumber = true -- Show relative line numbers
