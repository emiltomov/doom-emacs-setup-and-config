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
      doom-variable-pitch-font (font-spec :family "JetBrains Mono" :size 14))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme (quote doom-nova))
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
  (setq dashboard-items '((recents . 10) (projects . 8) (bookmarks . 5))
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
  (when-let ((f (if (and frame (display-graphic-p frame))
                    frame
                  (seq-find #'display-graphic-p (frame-list)))))
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
        centaur-tabs-set-bar 'under
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

(defun my/style-tabs ()
  (when (facep 'centaur-tabs-selected)
    (let* ((bg (face-background 'default nil t))
           (fg (face-foreground 'default nil t))
           (accent (or (face-foreground 'font-lock-keyword-face nil t) fg))
           (raised (doom-lighten bg 0.12))
           (selected (doom-lighten bg 0.22))
           (bar (doom-darken bg 0.25)))
      (set-face-attribute 'tab-line nil :background bar :box nil)
      (set-face-attribute 'centaur-tabs-default nil :background bar :foreground fg)
      (set-face-attribute 'centaur-tabs-unselected nil
                          :background raised :foreground (doom-darken fg 0.25)
                          :box '(:line-width 3 :style released-button) :weight 'normal)
      (set-face-attribute 'centaur-tabs-unselected-modified nil
                          :background raised :foreground accent
                          :box '(:line-width 3 :style released-button) :weight 'normal)
      (set-face-attribute 'centaur-tabs-selected nil
                          :background selected :foreground (doom-lighten fg 0.2)
                          :box '(:line-width 3 :style pressed-button) :weight 'bold)
      (set-face-attribute 'centaur-tabs-selected-modified nil
                          :background selected :foreground accent
                          :box '(:line-width 3 :style pressed-button) :weight 'bold)
      (set-face-attribute 'centaur-tabs-active-bar-face nil :background accent)
      (set-face-attribute 'centaur-tabs-close-selected nil :background selected)
      (set-face-attribute 'centaur-tabs-close-unselected nil :background raised))))

;; Global menu bar and right-click context menu
(menu-bar-mode 1)
(add-to-list 'default-frame-alist '(menu-bar-lines . 1))
(context-menu-mode 1)

(after! centaur-tabs
  (setq centaur-tabs-style "box"
        centaur-tabs-set-bar 'over)
  (my/style-tabs)
  (add-hook 'doom-load-theme-hook #'my/style-tabs 90))

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
