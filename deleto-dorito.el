;; More delete based commands for emacs
;; mostly for keybinds, since smartparens does
;; some finicky behaviour with the kill-ring.
;;
;; most commands are put in terms of delete-region which as of now
;; seems to be a native C function.

(defun dd-delete-sexp (&optional arg)
  "Delete the sexp (balanced expression) following point.
With ARG, kill that many sexps after point.
Negative arg -N means kill N sexps before point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (let ((opoint (point)))
    (sp-forward-sexp (or arg 1))
    (delete-region opoint (point))))

(defun dd-backward-delete-sexp (&optional arg)
  "Delete the sexp (balanced expression) preceding point.
With ARG, kill that many sexps before point.
Negative arg -N means kill N sexps after point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (dd-delete-sexp (- (or arg 1))))

(defun dd-forward-delete-sexp (&optional arg)
  "Delete the sexp (balanced expression) following point.
With ARG, kill that many sexps before point.
Negative arg -N means kill N sexps after point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (dd-delete-sexp (or arg 1)))

(defun dd-forward-delete-whitespace ()
  (let (p p2)
    (setq p (point))
    (skip-chars-forward " \n\t")
    (setq p2 (point))
    (delete-region p p2)))

(defun dd-backward-delete-whitespace ()
  (let (p p2)
    (setq p (point))
    (skip-chars-backward " \n\t")
    (setq p2 (point))
    (delete-region p2 p)))

(defun dd-delete-word (&optional arg)
  "Delete characters forward until encountering the end of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (forward-word (or arg 1)) (point))))

(defun dd-backward-delete-word (&optional arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (dd-delete-word (- (or arg 1))))

(defun dd-copy-sexp (&optional arg)
  "Copy the sexp (balanced expression) following point.
With ARG, kill that many sexps after point.
Negative arg -N means kill N sexps before point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (let ((opoint (point)))
    (sp-forward-sexp (or arg 1))
    (copy-region-as-kill opoint (point))))

;; Selection based commands

(defun dd-kill-sexp-or-selection ()
  (interactive)
  (if (region-active-p)
      (kill-region (mark) (point) 'region)
    (sp-kill-sexp 1)))

;; it is too hard to port smartparens's version of this so enjoy hacks
(defun dd-delete-sexp-or-selection ()
  (interactive)
  (make-local-variable 'kill-ring-yank-pointer)
  (let* ((kill-ring kill-ring)
         (select-enable-clipboard nil))
    (dd-kill-sexp-or-selection arg word)))

(defun dd-copy-sexp-or-selection ()
  (interactive)
  (if (region-active-p)
      (copy-region-as-kill (mark) (point) 'region)
    (sp-copy-sexp)))

;; Very dwim-like commands. Bind them to C-backspace or C-delete for fun, tweak as desired.

(defun dd-forward-delete-word-or-whitespace-or-sexp ()
  (interactive)
  (let (p cb)
    (setq p (point))
    (setq cb (string (following-char)))
    (let* ((select-enable-clipboard nil))
      (cond
       ((or (equal cb " ") (equal cb "\t") (equal cb "\n"))
        (dd-forward-delete-whitespace))
       ((equal cb ")")
        (up-list)
        (dd-backward-delete-sexp))
       ((equal cb "(")
        (dd-delete-sexp))
       (t
        (dd-delete-word))))))

(defun dd-backward-delete-word-or-whitespace-or-sexp ()
  (interactive)
  (let (p cb)
    (setq p (point))
    (setq cb (string (preceding-char)))
    (let* ((select-enable-clipboard nil))
      (cond
       ((or (equal cb " ") (equal cb "\t") (equal cb "\n"))
        (dd-backward-delete-whitespace))
       ((equal cb "(")
        (sp-up-sexp)
        (dd-forward-delete-sexp))
       ((equal cb ")")
        (dd-backward-delete-sexp))
       (t
        (dd-backward-delete-word))))))

;; the dwim INTENSIFIES

(defun dd-paste ()
  (interactive)
  (when kill-ring
    (if (region-active-p)
        (progn
          (kill-region (region-beginning) (region-end))
          (kill-new (cadr kill-ring)))
      (insert (car (kill-ring))))))

(defun dd-yank ()
  (interactive)
  (when kill-ring
    (if (region-active-p)
        (progn
          (kill-region (region-beginning) (region-end))
          (kill-new (cadr kill-ring)))
      (yank))))

(defun dd-inject-paste ()
  (interactive)
  (when kill-ring
    (if (region-active-p)
        (progn
          (kill-region (region-beginning) (region-end))
          (kill-new (cadr kill-ring)))
      (dd-inject (car kill-ring)))))

(defun dd-inject-yank ()
  (interactive)
  (when kill-ring
    (if (region-active-p)
        (progn
          (kill-region (region-beginning) (region-end))
          (kill-new (cadr kill-ring)))
      (dd-inject (current-kill 0)))))

;; (defvar dd-inject-clear
;;   '(" " "'" "`" "," "" "\"" "@" "[" "]" "{" "}"))

(defvar dd-inject-clear-before
  '(" " "(" "'" "`" "," "" "\"" "@" "[" "]" "{" "}"))

(defvar dd-inject-clear-after
  '(")" (string #\newline)))

(defvar dd-inject-paste-before
  '(" " ")" "'" "`" "," "" "\"" "@" "[" "]" "{" "}" ";"))

(defun dd-inject (str)
  "Injects a symbol safely"
  (interactive)
  (when kill-ring
    (if (region-active-p)
        (progn
          (kill-region (region-beginning) (region-end))
          (kill-new (cadr kill-ring)))
      (let ((ops (string (preceding-char)))
            (ofs (string (following-char))))
        (cond
         ;; empty buffer
         ((and (not ops) (not ofs))
          (print 1)
          (insert str))
         ;; empty list
         ((and (eq "(" ops)
               (eq ")" ofs))
          (print 2)
          (insert str))
         ;; not code
         ((sp-point-in-string-or-comment)
          (print 3)
          (insert str))
         ;; OK before
         ((member* ops dd-inject-clear-before :test #'equal)
          (print 4)
          (insert str)
          (unless (string-match-p "[\)\s]" (string (following-char)))
            ;;(member* (string (following-char)) dd-inject-clear-after :test #'equal)
            (insert " "))
          )
         ;; OK after
         ((string-match-p "[\)\s\n]" ofs)
          ;;(member* ofs dd-inject-clear-after :test #'equal)
          (print 5)
          (unless (member* (string (preceding-char)) dd-inject-clear-before :test #'equal)
            (insert " "))
          (insert str)) 
         ;; blocked both sides; insert after blocked token.
         (t
          (print 6)
          (re-search-forward "[ \\)\\'\\\"\\`\\,\\@\\{\\}\\;]")
          (unless (member* (string (preceding-char)) dd-inject-clear-before :test #'equal)
            (insert " "))
          (insert str)
          (insert " ")))))))


