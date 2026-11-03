;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "JetBrains Mono" :size 14)
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-jetbrains)
;; Specify both a dark and light theme, like so and Doom will choose which one
;; to load based on your system light/dark setting:
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (DARK . LIGHT)
;;
;; If you want more pro-active theme switching based on OS light/dark mode, look
;; up the `auto-dark' package.

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)
(setq-default cursor-type 'bar
              line-spacing 0.1)

(setq window-divider-default-right-width 1
      window-divider-default-bottom-width 1
      window-divider-default-places t)
(window-divider-mode 1)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(use-package! dashboard
  :demand t
  :config
  (defun my/dashboard-insert-keys (_list-size)
    "Insert custom key bindings section."
    (dashboard-insert-heading "Custom keys:")
    (insert "\n")
    (dolist (k '(("SPC o c" . "Copilot CLI")
                 ("F8" . "Toggle Treemacs")
                 ("C-<next> / C-<prior>" . "Next / previous tab")
                 ("RET in Magit" . "Changed-file diff in separate window")
                 ("C-c h" . "Rust docs popup")
                 ("C-S-t t" . "Go to implementation (Rust)")
                 ("gd / gD / gI / K" . "Definition / refs / impl / docs")))
      (insert (format "    %-22s %s\n" (car k) (cdr k)))))
  (add-to-list 'dashboard-item-generators '(keys . my/dashboard-insert-keys))
  (setq dashboard-items '((recents . 10) (projects . 8) (bookmarks . 5) (keys . 1))
        dashboard-projects-backend 'projectile
        dashboard-center-content t
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-startup-banner 'logo
        initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  (dashboard-setup-startup-hook))

(use-package! agent-shell
  :commands (agent-shell agent-shell-github-start-copilot)
  :init
  (map! :leader :desc "Copilot CLI (agent-shell)" "o c" #'agent-shell-github-start-copilot))

(add-to-list 'default-frame-alist '(fullscreen . maximized))


(setq desktop-dirname (concat doom-cache-dir "desktop/")
      desktop-path (list desktop-dirname)
      desktop-base-file-name "emacs.desktop"
      desktop-restore-eager 10
      desktop-save t
      desktop-load-locked-desktop t
      desktop-auto-save-timeout 60)
(after! desktop
  (add-to-list (quote desktop-minor-mode-table) (quote (centaur-tabs-local-mode nil))))
(make-directory desktop-dirname t)
(desktop-save-mode 1)
(add-hook 'kill-emacs-hook #'desktop-save-in-desktop-dir)
(add-hook 'emacs-startup-hook #'desktop-read 90)

(require 'windmove)
(windmove-default-keybindings '(control shift))

(defvar my/layout-file (concat doom-cache-dir "layout.eld"))
(defvar my/layout-restored nil)

(defun my/save-layout (&optional frame)
  (when-let ((f (seq-find (lambda (candidate)
                            (and (display-graphic-p candidate)
                                 (not (frame-parent candidate))
                                 (not (frame-parameter candidate 'my-magit-diff))))
                          (if frame (list frame) (frame-list)))))
    (with-temp-file my/layout-file
      (prin1 (window-state-get (frame-root-window f) t) (current-buffer)))))

(defun my/restore-layout (&optional frame)
  (let ((f (or frame (selected-frame))))
    (when (and (not my/layout-restored)
               (display-graphic-p f)
               (file-exists-p my/layout-file))
      (setq my/layout-restored t)
      (condition-case err
          (with-selected-frame f
            (window-state-put
             (with-temp-buffer
               (insert-file-contents my/layout-file)
               (read (current-buffer)))
             (frame-root-window f) 'safe))
        (error (message "Layout restore failed: %s" err))))))

(add-hook 'delete-frame-functions #'my/save-layout)
(add-hook 'kill-emacs-hook #'my/save-layout)
(run-with-timer 60 60 #'my/save-layout)
(add-hook 'server-after-make-frame-hook #'my/restore-layout 90)
(add-hook 'window-setup-hook #'my/restore-layout 90)

(after! agent-shell
  (setq agent-shell-session-strategy 'new)
  (add-hook 'agent-shell-mode-hook
            (lambda () (when (bound-and-true-p persp-mode) (persp-add-buffer (current-buffer))))))

(load! "magit-frame")

(map! "<f8>" #'+treemacs/toggle)

(after! centaur-tabs
  (setq centaur-tabs-style "bar"
        centaur-tabs-set-bar nil
        centaur-tabs-set-icons t
        centaur-tabs-set-close-button t
        centaur-tabs-set-modified-marker t
        centaur-tabs-gray-out-icons 'buffer
        centaur-tabs-height 32
        centaur-tabs-cycle-scope 'tabs)
  (centaur-tabs-group-by-projectile-project)
  (map! "C-<next>" #'centaur-tabs-forward
        "C-<prior>" #'centaur-tabs-backward
        "C-<tab>" #'centaur-tabs-forward
        "C-S-<iso-lefttab>" #'centaur-tabs-backward))

(defun my/enable-tabs ()
  (centaur-tabs-mode 1))
(remove-hook 'server-after-make-frame-hook #'centaur-tabs-mode)
(add-hook 'server-after-make-frame-hook #'my/enable-tabs)

(after! doom-modeline
  (setq doom-modeline-height 24
        doom-modeline-bar-width 2))

(menu-bar-mode -1)
(tool-bar-mode -1)
(add-to-list 'default-frame-alist '(menu-bar-lines . 0))
(context-menu-mode 1)

;; Name term buffers after their foreground process
(defun my/term-rename-buffers ()
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'term-mode)
        (let* ((proc (get-buffer-process buf))
               (pgid (and proc (process-running-child-p proc)))
               (name (if (integerp pgid)
                         (alist-get 'comm (process-attributes pgid))
                       (and proc (file-name-nondirectory (car (process-command proc)))))))
          (when (and name (not (string-empty-p name)))
            (let ((new (format "*%s*" name)))
              (unless (string= new (buffer-name))
                (rename-buffer new t)))))))))
(run-with-timer 1 1 #'my/term-rename-buffers)

(use-package! rainbow-delimiters
  :hook ((prog-mode text-mode) . rainbow-delimiters-mode))

(use-package! eldoc-box
  :commands eldoc-box-help-at-point
  :init
  (map! :after rust-mode :map rust-mode-map "C-c h" #'eldoc-box-help-at-point)
  (map! :after rust-ts-mode :map rust-ts-mode-map "C-c h" #'eldoc-box-help-at-point))

(map! :after rust-mode :map rust-mode-map
      "C-S-t t" #'eglot-find-implementation
      "C-S-t C-S-t" #'eglot-find-implementation)
(map! :after rust-ts-mode :map rust-ts-mode-map
      "C-S-t t" #'eglot-find-implementation
      "C-S-t C-S-t" #'eglot-find-implementation)
