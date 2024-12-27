vim.opt.number = true
vim.cmd('filetype on')
vim.cmd('highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=white')
vim.cmd('match ZenkakuSpace /　/')

vim.opt.autoread = true
vim.opt.hidden = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.laststatus = 2
vim.opt.cursorline = true
vim.opt.clipboard = 'unnamed'

vim.api.nvim_set_keymap('n', '<Space>q', ':quit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>Q', ':quit!<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>e', ':wq<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space><Space>', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>r', ':Denite file/rec<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('i', '<C-p>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-e>', '<End>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-d>', '<Del>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-h>', '<BS>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-a>', '<Home>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-k>', '<C-o>"_d$', { noremap = true })

vim.api.nvim_set_keymap('n', '<Space>p', ':NERDTreeToggle<CR>', { noremap = true, silent = true })
vim.opt.guifont = 'SourceCodePro-Regular:h12'

vim.cmd([[
autocmd BufWritePre * :%s/\s\+$//ge
]])

vim.g.NERDTreeShowHidden = 1
vim.g.NERDTreeWinSize = 40

vim.opt.compatible = false

if vim.fn.has('filetype') == 1 then
  vim.cmd('filetype indent plugin on')
end

if vim.fn.has('syntax') == 1 then
  vim.cmd('syntax on')
end

vim.cmd('filetype plugin indent on')
vim.cmd('colorscheme atom-dark')
vim.cmd('syntax enable')

vim.cmd([[
autocmd FileType js setlocal sw=2 sts=2 et
autocmd FileType yml setlocal sw=2 sts=2 et
autocmd FileType yaml setlocal sw=2 sts=2 ts=2 et
autocmd FileType lua setlocal tabstop=2 shiftwidth=2 noexpandtab
autocmd BufNewFile,BufRead *.schema set filetype=ruby
autocmd BufNewFile,BufRead Schemafile set filetype=ruby
autocmd BufNewFile,BufRead *.iam set filetype=ruby
autocmd BufNewFile,BufRead *.html setlocal tabstop=2 shiftwidth=2
]])

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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

local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  require('plugins').setup(use)

  if packer_bootstrap then
    require('packer').sync()
  end
end)

local function packer_sync_and_compile()
  vim.cmd [[autocmd User PackerComplete ++once lua require('packer').compile()]]
  require('packer').install()
end

if packer_bootstrap then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      packer_sync_and_compile()
    end,
  })
end

require('telescope').setup{
  defaults = {
    file_ignore_patterns = { "node_modules" }
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
}

require('gitsigns').setup {
  signs_staged_enable = true,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 130,
    ignore_whitespace = false,
    virt_text_priority = 100,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 4000, -- Disable if file is longer than this (in lines)
}

require('telescope').load_extension('fzf')
vim.api.nvim_set_keymap('n', '<Space>t', ':Telescope find_files hidden=true<CR>', { noremap = true, silent = true })
