"
" Filetype detection
"
augroup filetypedetect
    " Detect .txt as 'text'
    autocmd! BufNewFile,BufRead *.txt setfiletype text
    autocmd! BufNewFile,BufRead *.scala setfiletype scala （追加）
augroup END
