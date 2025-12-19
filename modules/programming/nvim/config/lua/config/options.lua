vim.g.have_nerd_font = false
vim.opt.mouse = "a"
vim.opt.showmode = false

vim.o.number = true
vim.o.relativenumber = true
vim.o.encoding = "utf-8"

vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.breakindent = true

vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", lead = "·", nbsp = "␣" }

vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "yes"

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.scrolloff = 15
-- vim.opt.cmdheight = 0

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
