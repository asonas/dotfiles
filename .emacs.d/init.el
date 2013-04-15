;;load-path
(add-to-list 'load-path "~/.emacs.d/elisp")
;; load-pathを追加する関数を定義
(defun add-to-load-path (&rest paths)
  (let (path)
    (dolist (path paths paths)
      (let ((default-directory
	      (expand-file-name (concat user-emacs-directory path))))
	(add-to-list 'load-path default-directory)
	(if (fboundp 'normal-top-level-add-subdirs-to-load-path)
	    (normal-top-level-add-subdirs-to-load-path))))))
;; 引数のディレクトリとそのサブディレクトリをload-pathに追加
(add-to-load-path "elisp" "conf" "public_repos")

;; backup
(setq backup-direcotry-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))
(setq auto-save-timeout 15)
(setq auto-save-interval 60)

;; package.el
(when (require 'package nil t)
  (add-to-list 'package-archives
	       '("marmalade" . "http://marmalade-repo.org/packages/"))
  (add-to-list 'package-archives '("ELPA" . "http://tromey.com/elpa/"))
  (package-initialize))

;; auto-install
(when (require 'auto-install nil t)
  ;; auto-install directory
  (setq auto-install-directory "~/.emacs.d/elisp/")
  (auto-install-update-emacswiki-package-name t)
  (auto-install-compatibility-setup))

;; 極力UTF-8
(prefer-coding-system 'utf-8)
;;colors
(require 'color-theme-tomorrow)
(color-theme-initialize)
(color-theme-tomorrow-night-bright)
(if window-system (progn
        ;;背景の透明度
        (set-frame-parameter nil 'alpha 85)))

;;時計表示
(display-time)
;;yesをyで答える
(defalias 'yes-or-no-p 'y-or-n-p)
;;履歴を多めに保存。
(setq history-length 10000)
;;履歴を次回に保存する。
(savehist-mode t)
;;; 最近開いたファイルを保存する数を増やす
(setq recentf-max-saved-items 10000)
;;行数
(require 'linum)
(global-linum-mode t)
(setq linum-format "%4d")  ;;4桁表示
;;スタートアップページいらない
(setq inhibit-startup-message t)
;;hide toolbar
(tool-bar-mode -1)
;; リージョンを削除できるように
(delete-selection-mode t)
;;対応する括弧をハイライト
(show-paren-mode t)
;;カーソル点滅
(blink-cursor-mode t)
;;編集行ハイライト
(global-hl-line-mode t)
;;ビープ音消去
(setq visible-bell t)
(setq ring-bell-function 'ignore)
;;ミニバッファ履歴リストの最大長：tなら無限
(setq history-length t)
;;minibufでisearchを使えるようにする
(require 'minibuf-isearch nil t)

;; Mac用
(when (eq system-type 'darwin)
  ;; MacのEmacsでファイル名を正しく扱うための設定
  (require 'ucs-normalize)
  (setq file-name-coding-system 'utf-8-hfs)
  (setq locale-coding-system 'utf-8-hfs)
  ;; 日本語入力
  (setq default-input-method "MacOSX")
  ;; フォント
  (add-to-list 'default-frame-alist '(font . "fontset-dejavukakugo")))

;; anything
(require 'anything-startup)
(when (require 'anything nil t)
  (setq
   anything-idle-delay 0.3
   anything-input-idle-delay 0.2
   anything-candidate-number-limit 100
   anything-quick-update t
   anything-enable-shortcuts 'alphabet)
  (when (require 'anything-coding nil t)
    (setq anything-su-or-sudo "sudo"))
  (require 'anything-match-plugin nil t)
  (when (and (executable-find "cmigemo")
	     (require 'migemo nil t))
    (require 'anything-migemo nit t))
  (when (require 'anything-complete nil t)
    (anything-lisp-complete-symbol-set-timer 150))
  (require 'anything-show-completion nil t)
  (when (require 'auto-install nil t)
    (require 'anything-auto-install nil t))
  (when (require 'descbinds-anything nil t)
    (descbinds-anything-install)))

(global-set-key (kbd "C-x b") 'anything)

;; auto-complete
(require 'auto-complete)
(require 'auto-complete-config)
(global-auto-complete-mode t)
(setq ac-auto-start t)

;; other window
;; via: http://d.hatena.ne.jp/rubikitch/20100210/emacs
(defun other-window-or-split ()
  (interactive)
  (when (one-window-p)
    (split-window-horizontally))
  (other-window 1))

(global-set-key (kbd "C-t") 'other-window-or-split)

;; goto-line
(global-set-key "\C-l" 'goto-line)

;; タブ, 全角スペース、改行直前の半角スペースを表示する
(when (require 'jaspace nil t)
  (when (boundp 'jaspace-modes)
    (setq jaspace-modes (append jaspace-modes
                                (list 'php-mode
                                      'yaml-mode
                                      'javascript-mode
                                      'ruby-mode
                                      'text-mode
                                      'fundamental-mode
				      'smarty-mode))))
  (when (boundp 'jaspace-alternate-jaspace-string)
    (setq jaspace-alternate-jaspace-string "□"))
  (when (boundp 'jaspace-alternate-eol-string)
    (setq jaspace-alternate-eol-string "↓\n"))
  (when (boundp 'jaspace-highlight-tabs)
    (setq jaspace-highlight-tabs ?^))
  (add-hook 'jaspace-mode-off-hook
            (lambda()
              (when (boundp 'show-trailing-whitespace)
                (setq show-trailing-whitespace nil))))
  (add-hook 'jaspace-mode-hook
            (lambda()
              (progn
                (when (boundp 'show-trailing-whitespace)
                  (setq show-trailing-whitespace t))
                (face-spec-set 'jaspace-highlight-jaspace-face
                               '((((class color) (background light))
                                  (:foreground "blue"))
                                 (t (:foreground "green"))))
                (face-spec-set 'jaspace-highlight-tab-face
                               '((((class color) (background light))
                                  (:foreground "red"
                                   :background "unspecified"
                                   :strike-through nil
                                   :underline t))
                                 (t (:foreground "purple"
                                     :background "unspecified"
                                     :strike-through nil
                                     :underline t))))
                (face-spec-set 'trailing-whitespace
                               '((((class color) (background light))
                                  (:foreground "red"
                                   :background "unspecified"
                                   :strike-through nil
                                   :underline t))
                                 (t (:foreground "purple"
                                     :background "unspecified"
                                     :strike-through nil
                                     :underline t))))))))

;; redo+.el
(when (require 'redo+ nil t)
  (global-set-key (kbd "C-'") 'redo))

;; php-mode
(require 'php-mode)
(autoload 'php-mode "php-mode")
(setq auto-mode-alist
      (cons '("\\.php\\'" . php-mode) auto-mode-alist))
(setq php-mode-force-pear t)
(add-hook 'php-mode-hook
      (lambda ()
        (c-set-offset 'arglist-intro '+)
        (c-set-offset 'arglist-close 0)
        (setq tab-width 4)
        (setq c-basic-offset 4)
        (setq indent-tabs-mode nil)
        ))

;; smarty
;; http://deboutv.free.fr/lisp/smarty/download.php
(add-to-list 'auto-mode-alist (cons "\\.tpl\\'" 'smarty-mode))
(autoload 'smarty-mode "smarty-mode" "Smarty Mode" t)
(add-hook 'smarty-mode-hook
          (lambda ()
            (setq tab-width 4)
            (setq c-basic-offset 4)))

;; howm
(setq howm-directory "~/Dropbox/share/howm/")
;(setq howm-file-name-format "%Y/%m/%Y-%m-%d.howm")
(setq howm-menu-lang 'ja)
(setq howm-process-coding-system 'utf-8)
(when (require 'howm-mode nil t)
  (define-key global-map (kbd "C-c ,,") 'howm-menu))
;; save and close howm
(defun howm-save-buffer-and-kill ()
  "close howm"
  (interactive)
  (when (and (buffer-file-name)
	     (string-match "\\.txt" (buffer-file-name)))
    (save-buffer)
    (kill-buffer nil)))
(define-key howm-mode-map (kbd "C-c C-c") 'howm-save-buffer-and-kill)

(require 'tramp)
(setq tramp-default-method "ssh")
(add-to-list 'tramp-default-proxies-alist '("\\'" "\\`root\\'" "/ssh:%h:")) ;; 追加
(add-to-list 'tramp-default-proxies-alist '("localhost\\'" "\\`root\\'" nil)) ;; 追加
