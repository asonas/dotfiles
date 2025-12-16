-- lazy.nvim用のプラグイン設定
return {
  -- coc.nvim: Language Server Protocol client
  {
    'neoclide/coc.nvim',
    branch = 'release',
    -- または自動ビルドしたい場合:
    -- build = 'npm ci'
  },

  -- NERDTree: ファイルエクスプローラー
  'preservim/nerdtree',

  -- Telescope: ファジーファインダー
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      }
    }
  },

  -- GitSigns: Git差分表示
  {
    'lewis6991/gitsigns.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
  }
}
