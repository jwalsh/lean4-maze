;; Project-specific Emacs configuration for lean4-maze

;; Package setup
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
(package-initialize)

;; Bootstrap use-package if needed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Required dependencies that should be installed first
(use-package dash :ensure t)
(use-package f :ensure t)
(use-package ht :ensure t)
(use-package lv :ensure t)
(use-package spinner :ensure t)

;; LSP mode for enhanced features
(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :config
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-lens-enable t)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-signature-render-documentation nil))

;; Company mode for completion
(use-package company
  :ensure t
  :config
  (setq company-idle-delay 0.1)
  (setq company-minimum-prefix-length 1))

;; Lean4 mode setup - use local clone
(add-to-list 'load-path (expand-file-name "./lean4-mode"))
(require 'lean4-mode nil t)

;; Configure lean4-mode if available
(when (featurep 'lean4-mode)
  (add-to-list 'auto-mode-alist '("\\.lean\\'" . lean4-mode))
  (add-hook 'lean4-mode-hook #'lsp-deferred)
  (add-hook 'lean4-mode-hook #'company-mode)
  (setq lean4-rootdir "/usr/local")
  ;; Try using lake serve as a language server alternative
  (setq lsp-lean4-server-command '("lake" "serve"))
  ;; Keeping the original setting as a comment for reference
  ;; (setq lsp-lean4-server-path "/usr/local/bin/lean-language-server")
  )

;; Provide this file
(provide '.emacs-project)