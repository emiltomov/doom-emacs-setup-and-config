;;; ts-grammars.el --- build tree-sitter grammars in batch  -*- lexical-binding: t; -*-
;; Rust, JavaScript, CSS are pinned to older tags: Emacs 31.1.50 supports ABI 13-14 only.
(setq treesit-extra-load-path (list (expand-file-name "~/.config/emacs/.local/etc/tree-sitter/"))
      treesit-language-source-alist
      '((rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.2")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.23.1")
        (css "https://github.com/tree-sitter/tree-sitter-css" "v0.23.2")
        (doxygen "https://github.com/tree-sitter-grammars/tree-sitter-doxygen" "v1.1.0")
        (java "https://github.com/tree-sitter/tree-sitter-java")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src")))
(dolist (lang (mapcar #'car treesit-language-source-alist))
  (unless (treesit-language-available-p lang)
    (treesit-install-language-grammar
     lang (car treesit-extra-load-path))))
