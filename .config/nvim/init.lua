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

vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-e>', '<End>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-d>', '<Del>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-h>', '<BS>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-a>', '<Home>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-k>', '<C-o>"_d$', { noremap = true })

vim.api.nvim_set_keymap('n', '<Space>p', ':NERDTreeToggle<CR>', { noremap = true, silent = true })
vim.opt.guifont = 'SourceCodePro-Regular:h12'

-- coc.nvim completion settings
-- Tab: 補完候補があれば次の候補、なければTabを挿入
vim.api.nvim_set_keymap('i', '<TAB>', [[coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"]], { expr = true, silent = true })
-- Shift-Tab: 前の候補
vim.api.nvim_set_keymap('i', '<S-TAB>', [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]],
  { expr = true, silent = true })
-- Enter: 補完を確定
vim.api.nvim_set_keymap('i', '<CR>', [[coc#pum#visible() ? coc#pum#confirm() : "\<CR>"]], { expr = true, silent = true })
-- Ctrl-n: 補完メニューが表示されていれば次の候補、なければ下に移動
vim.api.nvim_set_keymap('i', '<C-n>', [[coc#pum#visible() ? coc#pum#next(1) : "\<Down>"]], { expr = true, silent = true })
-- Ctrl-p: 補完メニューが表示されていれば前の候補、なければ上に移動
vim.api.nvim_set_keymap('i', '<C-p>', [[coc#pum#visible() ? coc#pum#prev(1) : "\<Up>"]], { expr = true, silent = true })

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

-- lazy.nvimでプラグインを読み込み
require("lazy").setup("plugins")

require('telescope').setup {
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
  signs_staged_enable          = true,
  signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir                 = {
    follow_files = true
  },
  auto_attach                  = true,
  attach_to_untracked          = false,
  current_line_blame           = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts      = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 0,
    ignore_whitespace = false,
    virt_text_priority = 50,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority                = 6,
  update_debounce              = 100,
  status_formatter             = nil,  -- Use default
  max_file_length              = 4000, -- Disable if file is longer than this (in lines)
}

require('telescope').load_extension('fzf')
vim.api.nvim_set_keymap('n', '<Space>t', ':Telescope find_files hidden=true<CR>', { noremap = true, silent = true })

vim.g.python3_host_prog = vim.fn.trim(vim.fn.system('mise which python'))
