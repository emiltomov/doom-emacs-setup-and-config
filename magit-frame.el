;;; magit-frame.el -*- lexical-binding: t; -*-

(setq magit-diff-fontify-hunk 'all
      magit-diff-specify-hunk-foreground nil
      magit-diff-use-indicator-faces t)

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
  (map! :map magit-status-mode-map "RET" #'my/magit-open-change)
  (map! :map magit-mode-map "q" #'magit-mode-bury-buffer)
  (set-popup-rule! "\\(?:COMMIT_EDITMSG\\|MERGE_MSG\\|TAG_EDITMSG\\|NOTES_EDITMSG\\)"
    :actions '(display-buffer-in-side-window)
    :side 'left :slot 1 :size 0.33
    :select t :quit nil :ttl nil :modeline t))
