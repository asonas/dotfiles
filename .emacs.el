(setq load-path (cons "~/.emacs.d/" load-path))
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(gud-gdb-command-name "gdb --annotate=1")
 '(large-file-warning-threshold nil)
 '(safe-local-variable-values (quote ((encoding . utf-8)))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

;;; cperl-mode の設定
;;; http://d.hatena.ne.jp/gan2/20071019/1192791373
(defalias 'perl-mode 'cperl-mode)
(autoload 'cperl-mode
  "cperl-mode"
  "alternate mode for editing Perl programs" t)
(setq auto-mode-alist
      (append '(("\\.\\([pP][Llm]\\|al\\)$" . cperl-mode))
              auto-mode-alist ))
(setq cperl-indent-level 2
      cperl-hairy t
      cperl-font-lock t)

;;; perl の予約語を補完
;;; http://d.hatena.ne.jp/gan2/20071027/1193441140
(add-hook 'cperl-mode-hook
          (lambda ()
            (require 'perlplus)
            (local-set-key "\M-o" 'perlplus-complete-symbol)
            (perlplus-setup)
            (set-face-bold-p 'cperl-array-face nil)
            (set-face-background 'cperl-array-face "black")
            (set-face-bold-p 'cperl-hash-face nil)
            (set-face-italic-p 'cperl-hash-face nil)
            (set-face-background 'cperl-hash-face "black")

;; ここは嘘かも。Emacs に入った状態で .pl ファイル開くとこんなエラーが出る
;; File mode specification error: (error "Key sequence C-h f starts with non-prefix key C-h")
;; C-h が使えなくて困る
;            (eval-after-load "cperl-mode"
;              '(define-key cperl-mode-map "\C-h" 'backward-delete-char))

;; 上の問題の解決？cperl-mode で定義されてる C-h のバインドを解除
;; http://wota.jp/ac/?date=20070725
(local-unset-key "\C-h")
))


;; ruby-mode
(autoload 'ruby-mode "ruby-mode"
  "Mode for editing ruby source files" t)
(setq auto-mode-alist
      (append '(("\\.rb$" . ruby-mode)) auto-mode-alist))
(setq interpreter-mode-alist (append '(("ruby" . ruby-mode))
                                     interpreter-mode-alist))
(autoload 'run-ruby "inf-ruby"
  "Run an inferior Ruby process")
(autoload 'inf-ruby-keys "inf-ruby"
  "Set local key defs for inf-ruby in ruby-mode")
(add-hook 'ruby-mode-hook
          '(lambda () (inf-ruby-keys)))

;; rubydb
(autoload 'rubydb "rubydb3x"
  "run rubydb on program file in buffer *gud-file*.
the directory containing file becomes the initial working directory
and source-file directory for your debugger." t)

;; ruby-block
(require 'ruby-block)
(ruby-block-mode t)
;; ミニバッファに表示し, かつ, オーバレイする.
(setq ruby-block-highlight-toggle t)

;; rails
(defun try-complete-abbrev (old)
  (if (expand-abbrev) t nil))
(setq hippie-expand-try-functions-list
      '(try-complete-abbrev
        try-complete-file-name
        try-expand-dabbrev))
(setq rails-use-mongrel t)
(require 'cl)
(require 'rails)


;; ECB
;つかわない
;(setq load-path (cons (expand-file-name "~/.emacs.d/ecb-2.40") load-path))
;(load-file "~/elisp/cedet-1.0/common/cedet.el")
;(setq semantic-load-turn-useful-things-on t)
;(require 'ecb)
;(setq ecb-tip-of-the-day nil)
;(setq ecb-windows-width 0.25)
;(defun ecb-toggle ()
;  (interactive)
;  (if ecb-minor-mode
;      (ecb-deactivate)
;    (ecb-activate)))
;(global-set-key [f2] 'ecb-toggle)


;;右側の行数
(require 'linum)
(global-linum-mode t)      ; デフォルトで linum-mode を有効にする
(setq linum-format "%5d ") ; 5 桁分の領域を確保して行番号のあとにスペースを入れる
