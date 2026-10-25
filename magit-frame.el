;;; magit-frame.el -*- lexical-binding: t; -*-

;; Remembered geometry: (LEFT TOP WIDTH-PX HEIGHT-PX), persisted across sessions
(defvar my/magit-geometry-file (expand-file-name "magit-frame-geometry.eld" doom-cache-dir))
(defvar my/magit-geometry
  (ignore-errors
    (with-temp-buffer
      (insert-file-contents my/magit-geometry-file)
      (read (current-buffer)))))

(defun my/magit-save-geometry (frame)
  (when (and (frame-live-p frame) (frame-parameter frame 'my-magit))
    (let ((geo (list (frame-parameter frame 'left) (frame-parameter frame 'top)
                     (frame-text-width frame) (frame-text-height frame))))
      (unless (equal geo my/magit-geometry)
        (setq my/magit-geometry geo)
        (ignore-errors
          (with-temp-file my/magit-geometry-file (prin1 geo (current-buffer))))))))

(defun my/magit-frame ()
  (seq-find (lambda (f) (and (frame-parameter f 'my-magit)
                             (frame-live-p f)))
            (frame-list)))

(defun my/magit-display-buffer (buffer)
  "Show Magit buffers in one floating child frame, reusing its window."
  (let ((frame (my/magit-frame))
        (display-buffer-alist nil))
    (cond
     ((and frame (eq (window-frame (selected-window)) frame))
      (let ((cur (current-buffer)))
        (unless (eq cur buffer)
          (set-frame-parameter frame 'my-magit-history
                               (cons cur (frame-parameter frame 'my-magit-history)))))
      (display-buffer buffer '(display-buffer-same-window)))
     (t
      (let* ((parent (selected-frame))
             (w (floor (* 0.8 (frame-width parent))))
             (h (floor (* 0.8 (frame-height parent))))
             (win (display-buffer
                   buffer
                   `((display-buffer-in-child-frame)
                     (child-frame-parameters
                      . ((my-magit . t)
                         (name . "Magit")
                         ,@(if (and (consp my/magit-geometry)
                                    (= (length my/magit-geometry) 4)
                                    (cl-every #'integerp my/magit-geometry))
                               `((left . ,(nth 0 my/magit-geometry))
                                 (top . ,(nth 1 my/magit-geometry))
                                 (width . (text-pixels . ,(nth 2 my/magit-geometry)))
                                 (height . (text-pixels . ,(nth 3 my/magit-geometry))))
                             `((width . ,w) (height . ,h)
                               (left . 0.5) (top . 0.5)))
                         (undecorated . t)
                         (border-width . 2)
                         (internal-border-width . 8)
                         (drag-internal-border . t)
                         (drag-with-mode-line . t)
                         (drag-with-header-line . t)
                         (no-other-frame . nil)
                         (unsplittable . t)))))))
        (when win (select-frame-set-input-focus (window-frame win)))
        win)))))

(defun my/magit-bury (&optional kill-buffer)
  "Go back to the previous Magit buffer, or close the Magit frame."
  (let* ((frame (selected-frame))
         (cur (current-buffer)))
    (if (not (frame-parameter frame 'my-magit))
        (quit-window kill-buffer)
      (let ((hist (seq-filter #'buffer-live-p
                              (frame-parameter frame 'my-magit-history))))
        (while (and hist (eq (car hist) cur)) (pop hist))
        (set-frame-parameter frame 'my-magit-history (cdr hist))
        (if hist
            (progn (switch-to-buffer (car hist) nil t)
                   (when kill-buffer (kill-buffer cur)))
          (when kill-buffer (kill-buffer cur))
          (delete-frame frame))))))

(after! magit
  (setq magit-display-buffer-function #'my/magit-display-buffer
        magit-bury-buffer-function #'my/magit-bury)
  (add-to-list 'display-buffer-alist
               '("\\(COMMIT_EDITMSG\\|MERGE_MSG\\|TAG_EDITMSG\\|NOTES_EDITMSG\\|git-rebase-todo\\|\\*magit-process\\|\\*magit-log\\|\\*magit-revision\\|\\*magit-diff\\|\\*magit-stash\\|\\*magit-refs\\|\\*magit-cherry\\|\\*magit-reflog\\)"
                 (lambda (buffer _alist) (my/magit-display-buffer buffer)))))

(defun my/magit-frame-p-buffer (buf)
  (with-current-buffer buf
    (or (derived-mode-p 'magit-mode 'git-commit-mode 'git-rebase-mode)
        (bound-and-true-p with-editor-mode)
        (string-match-p "COMMIT_EDITMSG\\|MERGE_MSG\\|TAG_EDITMSG\\|\\*magit" (buffer-name)))))

(add-hook 'delete-frame-functions #'my/magit-save-geometry)

(defun my/magit-cleanup-frames ()
  "Close Magit child frames left behind showing a non-Magit buffer.
A non-Magit buffer (e.g. a visited file) is moved to the parent frame."
  (dolist (f (frame-list))
    (when (and (frame-live-p f) (frame-parameter f 'my-magit))
      (my/magit-save-geometry f)
      (let ((buf (window-buffer (frame-selected-window f)))
            (parent (frame-parent f)))
        (unless (my/magit-frame-p-buffer buf)
          (when (frame-live-p parent)
            (with-selected-frame parent (switch-to-buffer buf)))
          (delete-frame f)
          (when (frame-live-p parent) (select-frame-set-input-focus parent)))))))

(defvar my/magit-cleanup-timer nil)
(when (timerp my/magit-cleanup-timer) (cancel-timer my/magit-cleanup-timer))
(setq my/magit-cleanup-timer (run-with-idle-timer 0.5 t #'my/magit-cleanup-frames))
(after! with-editor
  (add-hook 'with-editor-post-finish-hook
            (lambda () (run-at-time 0.2 nil #'my/magit-cleanup-frames))))

;; Make an already-open Magit frame movable/resizable too
(dolist (f (frame-list))
  (when (frame-parameter f 'my-magit)
    (modify-frame-parameters f '((internal-border-width . 8)
                                 (drag-internal-border . t)
                                 (drag-with-mode-line . t)
                                 (drag-with-header-line . t)))))
