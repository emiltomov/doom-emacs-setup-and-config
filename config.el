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
    (dolist (k '(("C-c o c" . "Copilot CLI")
                 ("C-c o d" . "Open dashboard")
                 ("C-c o k" . "Kitty at project root")
                 ("C-c o t" . "Toggle terminal inside Emacs (vterm)")
                 ("C-c l p" . "Markdown preview")
                 ("F8" . "Toggle Treemacs")
                 ("C-<next> / C-<prior>" . "Next / previous tab")
                 ("RET in Magit" . "Changed-file diff in separate window")
                 ("C-c C-c in commit pane" . "Review draft / finish commit")
                 ("C-c h" . "Rust docs popup")
                 ("C-S-t t" . "Go to implementation (Rust)")
                 ("gd / gD / gI / K" . "Definition / refs / impl / docs")))
      (insert (format "    %-22s %s\n" (car k) (cdr k)))))
  (add-to-list 'dashboard-item-generators '(keys . my/dashboard-insert-keys))
  (add-to-list 'doom-real-buffer-modes 'dashboard-mode)
  (defun my/dashboard-buffer ()
    "Return a populated dashboard without replacing an editor window."
    (dashboard-insert-startupify-lists t)
    (let ((buffer (get-buffer dashboard-buffer-name)))
      (when (bound-and-true-p persp-mode)
        (persp-add-buffer buffer))
      buffer))
  (defun my/open-dashboard ()
    "Open the dashboard in the current window."
    (interactive)
    (switch-to-buffer (my/dashboard-buffer)))
  (defun my/startup-buffer ()
    "Show the dashboard unless this frame has restored its saved layout."
    (let ((dashboard (my/dashboard-buffer)))
      (if (frame-parameter nil 'my-layout-restored)
          (window-buffer (selected-window))
        dashboard)))
  (setq dashboard-items '((recents . 10) (projects . 8) (bookmarks . 5) (keys . 1))
        dashboard-projects-backend 'projectile
        dashboard-center-content t
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-startup-banner 'logo
        initial-buffer-choice #'my/startup-buffer)
  (dashboard-setup-startup-hook)
  (remove-hook 'emacs-startup-hook #'dashboard-initialize)
  (add-hook 'emacs-startup-hook #'my/dashboard-buffer)
  (map! :leader :desc "Dashboard" "o d" #'my/open-dashboard))

(use-package! agent-shell
  :commands (agent-shell agent-shell-github-start-copilot)
  :init
  (map! :leader :desc "Copilot CLI (agent-shell)" "o c" #'agent-shell-github-start-copilot))

(defun my/open-kitty (&optional here)
  "Open Kitty at the project root, or the current directory with prefix HERE."
  (interactive "P")
  (when (file-remote-p default-directory)
    (user-error "Open Kitty from a local directory, not a remote buffer"))
  (let ((kitty (executable-find "kitty"))
        (directory (if here default-directory
                     (or (doom-project-root) default-directory))))
    (unless kitty
      (user-error "Kitty is not installed or is not on PATH"))
    (start-process "kitty" nil kitty "--detach" "--directory" directory)))

(map! :leader :desc "Kitty terminal" "o k" #'my/open-kitty)

(defvar-local my/markdown-preview-source-buffer nil)

(defun my/markdown-mermaid-svg (code)
  "Render Mermaid CODE locally and return its cached SVG filename."
  (require 'json)
  (let* ((renderer (executable-find "mmdc"))
         (browser (or (executable-find "google-chrome")
                      (executable-find "chromium")
                      (executable-find "chromium-browser")))
         (directory (expand-file-name "markdown-diagrams/" doom-cache-dir))
         (options '((theme . "dark") (htmlLabels . :false)
                    (flowchart . ((htmlLabels . :false)))
                    (securityLevel . "strict")))
         (config (json-serialize options))
         (file (expand-file-name
                (concat (secure-hash 'sha256 (concat config code)) ".svg")
                directory)))
    (unless renderer
      (user-error "Install Mermaid CLI with bootstrap.sh"))
    (unless browser
      (user-error "Install Chrome or Chromium to render Mermaid diagrams"))
    (unless (file-exists-p file)
      (make-directory directory t)
      (set-file-modes directory #o700)
      (let ((input (make-temp-file (expand-file-name "input-" directory) nil ".mmd"))
            (output (make-temp-file (expand-file-name "output-" directory) nil ".svg"))
            (settings (make-temp-file (expand-file-name "config-" directory) nil ".json"))
            (puppeteer (make-temp-file (expand-file-name "browser-" directory) nil ".json"))
            (log (get-buffer-create "*Mermaid render*")))
        (unwind-protect
            (progn
              (with-temp-file input (insert code))
              (with-temp-file settings (insert config))
              (with-temp-file puppeteer
                (insert (json-serialize `((executablePath . ,browser)))))
              (with-current-buffer log
                (let ((inhibit-read-only t)) (erase-buffer)))
              (unless (eq 0 (call-process renderer nil log nil
                                         "-i" input "-o" output
                                         "-c" settings "-p" puppeteer
                                         "-b" "transparent"))
                (error "Mermaid rendering failed; see *Mermaid render*"))
              (set-file-modes output #o600)
              (rename-file output file t))
          (dolist (temporary (list input output settings puppeteer))
            (when (file-exists-p temporary)
              (delete-file temporary))))))
    file))

(defun my/markdown-render-pre (dom)
  "Render Mermaid fences as images and leave other code blocks unchanged."
  (if (and (display-graphic-p)
           (member "mermaid" (split-string (or (dom-attr dom 'class) ""))))
      (condition-case err
          ;; Preserve syntax across Pandoc's highlighting spans.
          (let ((file (my/markdown-mermaid-svg (dom-texts dom ""))))
            (shr-ensure-newline)
            (insert-image (create-image file 'svg nil
                                        :max-width (window-body-width nil t)))
            (insert "\n"))
        (error
         (shr-tag-pre dom)
         (insert (format "\n[Mermaid: %s]\n" (error-message-string err)))))
    (shr-tag-pre dom)))

(defun my/markdown-fit-images (window)
  "Fit preview SVGs to WINDOW after restoring its saved width."
  (with-current-buffer (window-buffer window)
    (when (buffer-live-p my/markdown-preview-source-buffer)
      (with-silent-modifications
        (let ((position (point-min))
              (width (window-body-width window t)))
          (while (< position (point-max))
            (let ((next (next-single-property-change position 'display nil (point-max)))
                  (image (get-text-property position 'display)))
              (when (and (eq (car-safe image) 'image)
                         (eq (image-property image :type) 'svg))
                (setq image (copy-sequence image))
                (setf (image-property image :max-width) width)
                (put-text-property position next 'display image))
              (setq position next))))))))

(defun my/markdown-preview ()
  "Render the current Markdown buffer in an Emacs pane without exporting files."
  (interactive)
  (unless (derived-mode-p 'markdown-mode)
    (user-error "Open a Markdown buffer first"))
  (unless (executable-find "pandoc")
    (user-error "Install pandoc to preview Markdown"))
  (require 'shr)
  (require 'browse-url)
  (unless (libxml-available-p)
    (user-error "Markdown preview needs Emacs built with libxml2 support"))
  (let* ((source (current-buffer))
         (directory default-directory)
         (document
          (with-temp-buffer
            (let ((output (current-buffer)))
              (with-current-buffer source
                (let ((mark-active nil)
                      (markdown-command '("pandoc" "--from=gfm" "--to=html5")))
                  (markdown output))))
            (libxml-parse-html-region (point-min) (point-max))))
         (preview (get-buffer-create
                   (format "*Markdown preview: %s*" (buffer-name))))
         (window (display-buffer preview)))
    (with-selected-window window
      (let ((inhibit-read-only t)
            (shr-external-rendering-functions
             (cons '(pre . my/markdown-render-pre)
                   shr-external-rendering-functions)))
        (erase-buffer)
        (shr-insert-document
         `(html nil
                (head nil (base ((href . ,(browse-url-file-url directory)))))
                ,@(dom-children document)))
        (goto-char (point-min))
        (special-mode)
        (setq-local default-directory directory
                    my/markdown-preview-source-buffer source
                    revert-buffer-function
                    (lambda (&rest _)
                      (with-current-buffer source
                        (my/markdown-preview))))))))

(after! markdown-mode
  (map! :map markdown-mode-map
        :localleader :desc "Preview in Emacs" "p" #'my/markdown-preview))

(set-popup-rule! "^\\*Markdown preview:"
  :side 'right :size 0.5 :select nil :quit t :ttl nil :modeline t)

(add-to-list 'default-frame-alist '(fullscreen . maximized))


(setq desktop-dirname (concat doom-cache-dir "desktop/")
      desktop-path (list desktop-dirname)
      desktop-base-file-name "emacs.desktop"
      desktop-restore-frames nil
      desktop-restore-eager t
      desktop-save t
      desktop-load-locked-desktop t
      desktop-auto-save-timeout nil)
(after! desktop
  (add-to-list (quote desktop-minor-mode-table) (quote (centaur-tabs-local-mode nil))))
(make-directory desktop-dirname t)
(desktop-save-mode 1)
(desktop-auto-save-disable)
(add-hook 'kill-emacs-hook #'desktop-save-in-desktop-dir)
(add-hook 'emacs-startup-hook #'desktop-read 90)

(require 'windmove)
(windmove-default-keybindings '(control shift))

(defvar my/layout-file (concat doom-cache-dir "layout.eld"))
(defvar my/session-file (concat doom-cache-dir "workspaces.eld"))
(defvar my/layout-restored nil)
(defvar my/layout-in-progress nil)

(defun my/main-frame-p (frame)
  (and (frame-live-p frame)
       (display-graphic-p frame)
       (not (frame-parent frame))
       (not (frame-parameter frame 'my-magit-diff))))

(defun my/session-buffer-state (buffer)
  "Describe how to reopen BUFFER without replaying commands."
  (with-current-buffer buffer
    (unless (file-remote-p default-directory)
      (cons (buffer-name)
            (cond
             (buffer-file-name
              (list :kind 'file :file buffer-file-name :point (point)))
             ((derived-mode-p 'dashboard-mode) '(:kind dashboard))
             ((derived-mode-p 'dired-mode)
              (list :kind 'dired :directory default-directory))
             ((derived-mode-p 'treemacs-mode)
              (list :kind 'treemacs :directory default-directory))
             ((derived-mode-p 'vterm-mode)
              (list :kind 'vterm :directory default-directory))
             ((derived-mode-p 'magit-status-mode)
              (list :kind 'magit :directory default-directory))
             ((buffer-live-p my/markdown-preview-source-buffer)
              (list :kind 'markdown
                    :source (buffer-name my/markdown-preview-source-buffer)))
             (t '(:kind buffer)))))))

(defun my/restore-session-buffer (entry)
  "Reopen a saved buffer ENTRY, recreating supported tool panes."
  (let* ((name (car entry))
         (data (cdr entry))
         (existing (get-buffer name))
         (buffer
          (pcase (plist-get data :kind)
            ('file
             (when (file-readable-p (plist-get data :file))
               (let ((buffer (find-file-noselect (plist-get data :file))))
                 (with-current-buffer buffer
                   (goto-char (min (point-max) (or (plist-get data :point) 1))))
                 buffer)))
            ('dashboard (my/dashboard-buffer))
            ('dired (dired-noselect (plist-get data :directory)))
            ('treemacs
             (require 'treemacs)
             (let ((default-directory (plist-get data :directory)))
               (treemacs))
             (treemacs-get-local-buffer))
            ('vterm
             (if (and existing
                      (with-current-buffer existing (derived-mode-p 'vterm-mode))
                      (process-live-p (get-buffer-process existing)))
                 existing
               (require 'vterm)
               (with-current-buffer (get-buffer-create name)
                 (setq default-directory (plist-get data :directory))
                 (vterm-mode)
                 (current-buffer))))
            ('magit
             (magit-status (plist-get data :directory))
             (current-buffer))
            ('markdown
             (when-let ((source (get-buffer (plist-get data :source))))
               (with-current-buffer source (my/markdown-preview))
               (get-buffer (format "*Markdown preview: %s*" (buffer-name source)))))
            (_ (or existing (get-buffer-create name))))))
    (when (and buffer (not (get-buffer name)))
      (with-current-buffer buffer (rename-buffer name)))
    buffer))

(defun my/save-layout (&optional frame)
  "Save the main editor before workspace or frame teardown."
  (when-let ((frame (and my/layout-restored (not my/layout-in-progress)
                        (if frame
                            (and (my/main-frame-p frame) frame)
                          (if (my/main-frame-p (selected-frame))
                              (selected-frame)
                            (seq-find #'my/main-frame-p (frame-list)))))))
    (let ((my/layout-in-progress t))
      (with-selected-frame frame
        (dolist (other (frame-list))
          (unless (my/main-frame-p other)
            (set-frame-parameter other 'persp-ignore-wconf t)))
        (let* ((buffers
                (delete-dups
                 (append (seq-filter (lambda (buffer)
                                       (buffer-local-value 'buffer-file-name buffer))
                                     (buffer-list))
                         (mapcar #'window-buffer (window-list frame)))))
               (state (list :window-state (window-state-get (frame-root-window frame) t)
                            :workspace (+workspace-current-name)
                            :buffers (delq nil (mapcar #'my/session-buffer-state buffers))))
               (temporary (make-temp-file (concat my/layout-file "."))))
          (unwind-protect
              (progn
                (desktop-save desktop-dirname)
                (doom-save-session my/session-file)
                (with-temp-file temporary (prin1 state (current-buffer)))
                (rename-file temporary my/layout-file t))
            (when (file-exists-p temporary)
              (delete-file temporary))))))))

(defun my/restore-layout (&optional frame)
  "Restore buffers and splits after the first graphical frame has settled."
  (let ((frame (or frame (selected-frame))))
    (when (and (not my/layout-restored) (my/main-frame-p frame))
      (let ((my/layout-in-progress t))
        (condition-case err
            (with-selected-frame frame
              (when (file-exists-p my/layout-file)
                (let* ((state (with-temp-buffer
                                (insert-file-contents my/layout-file)
                                (read (current-buffer))))
                       (window-state (or (plist-get state :window-state) state))
                       (requested-buffer (window-buffer (selected-window)))
                       (requested-point (window-point (selected-window))))
                  (when (file-readable-p my/session-file)
                    (condition-case err
                        (doom-load-session my/session-file)
                      (error (message "Workspace restore failed: %s" err))))
                  (when-let ((workspace (plist-get state :workspace)))
                    (+workspace-switch workspace t))
                  (save-window-excursion
                    (dolist (entry (plist-get state :buffers))
                      (condition-case err
                          (my/restore-session-buffer entry)
                        (error (message "Buffer restore failed: %s" err)))))
                  ;; Emacs 31 mixes pixel and cell units in nested splits.
                  (window-state-put
                   (seq-remove (lambda (entry)
                                 (memq (car-safe entry) '(pixel-width pixel-height)))
                               window-state)
                   (frame-root-window frame) 'safe)
                  (when (buffer-file-name requested-buffer)
                    (switch-to-buffer requested-buffer)
                    (goto-char (min requested-point (point-max))))
                  (dolist (window (window-list frame))
                    (my/markdown-fit-images window)
                    (persp-add-buffer (window-buffer window)))))
              (my/dashboard-buffer)
              (set-frame-parameter frame 'my-layout-restored t)
              (setq my/layout-restored t))
          (error (message "Layout restore failed: %s" err)))))))

(defun my/restore-layout-after-frame (&optional frame)
  (let ((frame (or frame (selected-frame))))
    (when (my/main-frame-p frame)
      (run-with-timer 0.2 nil #'my/restore-layout frame))))

(defun my/reset-layout-on-frame-close (frame)
  (when (and (my/main-frame-p frame)
             (not (seq-find (lambda (other)
                              (and (not (eq other frame)) (my/main-frame-p other)))
                            (frame-list))))
    (setq my/layout-restored nil)))

(after! persp-mode
  (setq persp-auto-save-opt 0))
(remove-hook 'server-after-make-frame-hook #'my/restore-layout)
(remove-hook 'window-setup-hook #'my/restore-layout)
(add-hook 'delete-frame-functions #'my/save-layout -90)
(add-hook 'delete-frame-functions #'my/reset-layout-on-frame-close -80)
(add-hook 'kill-emacs-hook #'my/save-layout -90)
(remove-hook 'window-state-change-functions #'my/schedule-layout-save)
(add-hook 'server-after-make-frame-hook #'my/restore-layout-after-frame 90)
(add-hook 'window-setup-hook #'my/restore-layout-after-frame 90)

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

(menu-bar-mode 1)
(tool-bar-mode -1)
(add-to-list 'default-frame-alist '(menu-bar-lines . 1))
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
