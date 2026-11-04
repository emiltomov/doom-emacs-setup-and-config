;;; magit-frame.el -*- lexical-binding: t; -*-

(setq magit-diff-fontify-hunk 'all
      magit-diff-specify-hunk-foreground nil
      magit-diff-use-indicator-faces t)

(define-derived-mode my/magit-commit-draft-mode text-mode "Commit Draft"
  "Edit a repository's draft before starting a Magit commit."
  (setq-local fill-column 72
              tab-line-format nil
              display-line-numbers nil
              header-line-format
              (list "  Commit message  "
                    (propertize
                     "[Commit]" 'mouse-face 'mode-line-highlight
                     'help-echo "Review this message in Magit (C-c C-c)"
                     'local-map
                     (let ((map (make-sparse-keymap)))
                       (define-key map [header-line mouse-1]
                                   #'my/magit-commit-from-draft)
                       map))
                    "  C-c C-c"))
  (face-remap-add-relative 'default :background (doom-color 'bg-alt)))

(defun my/magit-commit-draft-buffer ()
  "Return the current repository's file-backed commit draft."
  (let* ((root (or (magit-toplevel) (user-error "Not inside a Git repository")))
         (file (expand-file-name "DOOM_COMMIT_DRAFT" (magit-gitdir))))
    (unless (file-exists-p file)
      (write-region "" nil file nil 'silent))
    (let ((buffer (find-file-noselect file)))
      (with-current-buffer buffer
        (unless (derived-mode-p 'my/magit-commit-draft-mode)
          (my/magit-commit-draft-mode))
        (setq-local default-directory root
                    display-line-numbers nil)
        (when (bound-and-true-p persp-mode)
          (persp-add-buffer buffer)))
      buffer)))

(defun my/magit-commit-message ()
  "Open the current repository's commit-message pane."
  (interactive)
  (pop-to-buffer (my/magit-commit-draft-buffer)))

(defun my/magit-show-commit-message ()
  "Keep a draft beneath the visible status without replacing an active editor."
  (when (and (derived-mode-p 'magit-status-mode)
             (get-buffer-window (current-buffer) (selected-frame))
             (not (magit-commit-message-buffer)))
    (display-buffer (my/magit-commit-draft-buffer))))

(defun my/magit-commit-from-draft (&optional event)
  "Review the draft using Magit's normal commit command."
  (interactive (list (when (mouse-event-p last-input-event) last-input-event)))
  (when event
    (select-window (posn-window (event-start event))))
  (call-interactively #'magit-commit-create))

(defun my/magit-use-commit-draft ()
  "Seed an empty new-commit editor without overwriting existing messages."
  (when (and (memq last-command '(magit-commit-create magit-commit--all
                                 magit-commit--allow-empty
                                 my/magit-commit-from-draft))
             (equal (file-name-nondirectory (or buffer-file-name ""))
                    "COMMIT_EDITMSG")
             (not (git-commit-buffer-message))
             (not (magit-merge-in-progress-p))
             (not (magit-rebase-in-progress-p)))
    (when-let* ((draft (get-file-buffer
                        (expand-file-name "DOOM_COMMIT_DRAFT" (magit-gitdir))))
                (text (with-current-buffer draft
                        (buffer-substring-no-properties (point-min) (point-max))))
                (_ (not (string-blank-p text))))
      (goto-char (point-min))
      (insert text (if (string-suffix-p "\n" text) "\n" "\n\n"))
      (goto-char (point-min))
      ;; Native setup clears the modified flag after running its hooks.
      (add-hook 'with-editor-pre-finish-hook
                (lambda () (set-buffer-modified-p t)) nil t)
      (add-hook
       'git-commit-post-finish-hook
       (lambda ()
         (when (buffer-live-p draft)
           (with-current-buffer draft
             (when (equal text (buffer-substring-no-properties (point-min) (point-max)))
               (erase-buffer)
               (let ((inhibit-message t)
                     (message-log-max nil))
                 (save-buffer))))))
       nil t))))

(defun my/magit-diff-frame ()
  (seq-find (lambda (frame)
              (and (frame-live-p frame)
                   (frame-parameter frame 'my-magit-diff)))
            (frame-list)))

(defun my/magit-display-buffer (buffer)
  "Dock status on the left and show diffs in a separate native frame."
  (let ((display-buffer-alist nil))
    (cond
     ((with-current-buffer buffer (derived-mode-p 'magit-status-mode))
      (display-buffer
       buffer '((display-buffer-in-side-window)
                (side . left) (slot . 0) (window-width . 0.33)
                (window-parameters . ((no-delete-other-windows . t))))))
     ((and (display-graphic-p)
           (with-current-buffer buffer (derived-mode-p 'magit-diff-mode)))
      (let* ((origin (selected-window))
             (frame (or (my/magit-diff-frame)
                        (let ((new-frame
                               (make-frame '((name . "Git Diff")
                                             (title . "Git Diff")
                                             (my-magit-diff . t)
                                             (persp-ignore-wconf . t)
                                             (fullscreen . nil)
                                             (menu-bar-lines . 0)
                                             (tool-bar-lines . 0)))))
                          (set-frame-size
                           new-frame
                           (round (* 0.9 (frame-pixel-width (window-frame origin))))
                           (round (* 0.85 (frame-pixel-height (window-frame origin))))
                           t)
                          new-frame))))
        (unless (eq frame (selected-frame))
          (set-frame-parameter frame 'my-magit-origin origin))
        (with-selected-frame frame
          (display-buffer buffer '(display-buffer-same-window)))))
     (t
      (display-buffer
       buffer '((display-buffer-reuse-window
                 display-buffer-pop-up-window
                 display-buffer-use-some-window)
                (inhibit-same-window . t)))))))

(defun my/magit-bury (&optional kill-buffer)
  "Close the diff frame, or quit the current Magit window."
  (if (frame-parameter nil 'my-magit-diff)
      (let ((frame (selected-frame))
            (origin (frame-parameter nil 'my-magit-origin)))
        (if kill-buffer (kill-buffer (current-buffer)) (bury-buffer))
        (delete-frame frame)
        (when (window-live-p origin)
          (select-frame-set-input-focus (window-frame origin))
          (select-window origin)))
    (when (derived-mode-p 'magit-status-mode)
      (when-let* ((draft (get-file-buffer
                          (expand-file-name "DOOM_COMMIT_DRAFT" (magit-gitdir))))
                  (window (get-buffer-window draft (selected-frame))))
        (delete-window window)))
    (magit-mode-quit-window kill-buffer)))

(defun my/magit-open-change ()
  "Show the changed file at point in the diff frame."
  (interactive)
  (let ((file (magit-file-at-point)))
    (cond
     ((not file)
      (call-interactively (or (command-remapping #'magit-visit-thing)
                              #'magit-visit-thing)))
     ((eq (magit-diff-type) 'untracked)
      (magit-diff-visit-worktree-file t))
     (t
      (magit-diff-dwim (car (magit-diff-arguments)) (list file))))))

(defun my/magit-status-setup ()
  (setq-local truncate-lines t
              tab-line-format nil
              header-line-format "  Commit / Changes"
              magit-section-initial-visibility-alist
              (cons '(file . hide) magit-section-initial-visibility-alist))
  (face-remap-add-relative 'default :background (doom-color 'bg-alt)))

(after! magit
  (setq magit-display-buffer-function #'my/magit-display-buffer
        magit-bury-buffer-function #'my/magit-bury
        magit-diff-refine-hunk t)
  (add-hook 'magit-status-mode-hook #'my/magit-status-setup)
  (add-hook 'magit-post-display-buffer-hook #'my/magit-show-commit-message)
  (add-hook 'magit-post-refresh-hook #'my/magit-show-commit-message)
  (add-hook 'git-commit-setup-hook #'my/magit-use-commit-draft -80)
  (map! :map my/magit-commit-draft-mode-map "C-c C-c" #'my/magit-commit-from-draft)
  (map! :map magit-status-mode-map "RET" #'my/magit-open-change)
  (map! :map magit-mode-map "q" #'magit-mode-bury-buffer)
  (set-popup-rule! "DOOM_COMMIT_DRAFT"
    :actions '(display-buffer-in-side-window)
    :side 'left :slot 1 :size 0.33
    :select nil :quit nil :ttl nil :modeline t :autosave t)
  (set-popup-rule! "\\(?:COMMIT_EDITMSG\\|MERGE_MSG\\|TAG_EDITMSG\\|NOTES_EDITMSG\\)"
    :actions '(display-buffer-in-side-window)
    :side 'left :slot 1 :size 0.33
    :select t :quit nil :ttl nil :modeline t))
