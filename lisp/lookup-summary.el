;;; lookup-summary.el --- Lookup Summary mode
;; Copyright (C) 2000 Keisuke Nishida <knishida@ring.gr.jp>
;; Copyright (C) 2009 Lookup Development Team

;; Author: Keisuke Nishida <knishida@ring.gr.jp>
;; Keywords: dictionary

;; This file is part of Lookup.

;; Lookup is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; Lookup is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Lookup; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Code:

(require 'lookup)

;;;###autoload
(defun lookup-summary-display (session)
  (with-current-buffer (lookup-get-buffer (lookup-summary-buffer))
    (let ((query (lookup-session-query session))
	  (entries (lookup-session-entries session))
	  (excursion (lookup-session-excursion session)))
      ;; insert entries
      (let ((inhibit-read-only t))
	(lookup-summary-mode)
	(erase-buffer)
	(mapc 'lookup-search-query-insert entries)
	(set-buffer-modified-p nil))
      ;; set mode line
      (setq lookup-summary-line-module
	    (lookup-module-name (lookup-session-module session)))
      (setq lookup-summary-line-pattern (lookup-query-pattern query))
      (setq lookup-summary-line-number (number-to-string (length entries)))
      ;; display buffer
      (if excursion
	  (lookup-search-set-excursion excursion)
	(lookup-pop-to-buffer (current-buffer))
	(goto-char (point-min))
	(lookup-summary-goto-link)
	(if lookup-dynamic-display (sit-for 0))
	(lookup-summary-display-content)
	(if lookup-dynamic-display (sit-for 0))))))

(defun lookup-summary-append (entries)
  (with-current-buffer (lookup-summary-buffer)
    (save-excursion
      (let ((inhibit-read-only t)
	    (modified (buffer-modified-p)))
	(goto-char (point-max))
	(mapc 'lookup-search-query-insert entries)
	(set-buffer-modified-p modified)))
    (setf (lookup-session-entries lookup-current-session)
	  (append (lookup-session-entries lookup-current-session) entries))
    (setq lookup-summary-line-number
	  (number-to-string (+ (string-to-number lookup-summary-line-number)
			       (length entries))))
    (if lookup-dynamic-display (sit-for 0))))

(defun lookup-summary-expand-references (entry)
  (let ((entries (lookup-entry-references entry)))
    ;; rebuild buffer
    (let ((inhibit-read-only t)
	  (modified (buffer-modified-p))
	  (start (line-beginning-position)))
      (delete-region start (progn (forward-line) (point)))
      (mapc 'lookup-search-query-insert entries)
      (goto-char start)
      (lookup-summary-goto-link)
      (set-buffer-modified-p modified))
    ;; rebuild cache
    (let ((list (lookup-session-entries (lookup-current-session))))
      (if (eq entry (car list))
	  (setf (lookup-session-entries (lookup-current-session))
		(append entries (cdr list)))
	(while (not (eq entry (cadr list))) (setq list (cdr list)))
	(if list (setcdr list (append entries (cddr list))))))
    (setq lookup-summary-line-number
	  (number-to-string (+ (string-to-number lookup-summary-line-number)
			       (1- (length entries)))))))

(defun lookup-search-query-insert (entry)
  (lookup-search-query-insert-mark entry)
  (insert (lookup-dictionary-heading (lookup-entry-dictionary entry)) " \n")
  (backward-char)
  (lookup-entry-heading-insert entry)
  (forward-char))

(defun lookup-search-query-insert-mark (entry)
  (let ((bookmark (lookup-entry-bookmark (or (lookup-entry-substance entry)
					     entry))))
    (insert (if (stringp bookmark) "#" (if bookmark "!" " ")))))

;; content

(defun lookup-content-display (entry)
  (with-current-buffer (lookup-get-buffer (lookup-content-buffer))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (let ((content (lookup-get-property entry 'content)))
	(if (and content lookup-enable-format (not lookup-force-update))
	    (insert content)
	  (lookup-with-message (format "Inserting `%s'" (lookup-entry-heading entry))
	    (let ((dictionary (lookup-entry-dictionary entry)))
	      (insert (lookup-entry-content entry))
	      (when lookup-enable-format
		(lookup-arrange-content entry)
		(lookup-put-property entry 'content (buffer-string))))))
	(if lookup-enable-format (lookup-adjust-content entry)))
      ;; arrange functions might change the buffer mode
      (lookup-content-mode)
      (set-buffer-modified-p nil))
    (setq lookup-content-entry entry)
    (setq lookup-content-line-heading (lookup-entry-heading entry))
    (lookup-display-buffer (current-buffer))))

;;;
;;; Excursion
;;;

(defun lookup-search-excursion ()
  (let ((entry (get-buffer (lookup-summary-buffer)))
	(content (get-buffer (lookup-content-buffer))))
    (when entry
      (cons (with-current-buffer entry
	      (cons (point) (let ((window (get-buffer-window entry)))
			      (if window (window-start window)))))
	    (when (and content (with-current-buffer entry
				 (lookup-summary-this-entry)))
	      (with-current-buffer content
		(cons (point) (let ((window (get-buffer-window content)))
				(if window (window-start window))))))))))

(defun lookup-search-set-excursion (excursion)
  (let ((entry-point (caar excursion)) (entry-start (cdar excursion))
	(content (cdr excursion)))
    (lookup-pop-to-buffer (lookup-summary-buffer))
    (goto-char entry-point)
    (if entry-start
	(set-window-start (selected-window) entry-start))
    (if (eobp)
	(lookup-summary-previous-entry)
      (lookup-summary-display-content))
    (when content
      (lookup-with-buffer-and-window (lookup-content-buffer)
	(goto-char (car content))
	(if (cdr content)
	    (set-window-start (selected-window) (cdr content)))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Lookup Summary Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst lookup-summary-mode-help
  "Lookup Summary mode:

`n' - next entry        `SPC' - next page       `<' - first page
`p' - previous entry    `DEL' - previous page   `>' - last page

`m' - mark entry        `!' - put bookmark
`u' - unmark entry      `#' - write memorandum  

`b' - auto bookmark

`M-p' - previous session
`M-n' - next session
`M-f' - forward module
`M-b' - backward module

`v'(iew)   - toggle Overview  	`o'(pen)  - maximize window
`s'(earch) - isearch-forward  	`w'(rite) - kill-ring-save contents

`L'(inks)  - list references    `S'(elect)   - select dictionaries
`M'(enu)   - display the menu   `B'(ookmark) - display the bookmarks

`f'(ind)
`c'(ontinuous)

`t f' - toggle format
`t g' - toggle gaiji
`t b' - toggle autobook

`g g' - search again            `g =' - redo exactly
`g s' - use secondary           `g @' - redo keyword
`g f' - use forward module      `g <' - redo prefix
`g b' - use backward module     `g >' - redo suffix

`r'   - back to original buffer `h'   - move to content buffer
`q'   - quit buffer             `g'   - redo search
`Q'   - quit lookup             `R'   - restart lookup")

(defvar lookup-summary-mode-map nil
  "*Keymap for Lookup Summary mode.")

(unless lookup-summary-mode-map
  (setq lookup-summary-mode-map (make-sparse-keymap))
  (set-keymap-parent lookup-summary-mode-map lookup-global-map)
  ;; basic commands
  (define-key lookup-summary-mode-map " " 'lookup-summary-next-page)
  (define-key lookup-summary-mode-map "\C-?" 'lookup-summary-previous-page)
  (define-key lookup-summary-mode-map [delete] 'lookup-summary-previous-page)
  (define-key lookup-summary-mode-map "\C-m" 'lookup-summary-scroll-up-content)
  (define-key lookup-summary-mode-map "<" 'lookup-summary-beginning-of-content)
  (define-key lookup-summary-mode-map ">" 'lookup-summary-end-of-content)
  (define-key lookup-summary-mode-map "n" 'lookup-summary-next-entry)
  (define-key lookup-summary-mode-map "p" 'lookup-summary-previous-entry)
  (define-key lookup-summary-mode-map "P" 'enlarge-window)
  (define-key lookup-summary-mode-map "N" 'shrink-window)
  (define-key lookup-summary-mode-map "\M-N" 'lookup-summary-following-entry)
  (define-key lookup-summary-mode-map "\M-N" 'lookup-summary-preceding-entry)
  (define-key lookup-summary-mode-map
    (if (featurep 'xemacs) 'button2 [mouse-2]) 'lookup-summary-mouse-follow)
  ;; entry management
  (define-key lookup-summary-mode-map "i" 'lookup-summary-info)
  (define-key lookup-summary-mode-map "m" 'lookup-summary-mark)
  (define-key lookup-summary-mode-map "u" 'lookup-summary-unmark)
  (define-key lookup-summary-mode-map "U" 'lookup-summary-unmark-all)
  (define-key lookup-summary-mode-map "!" 'lookup-summary-bookmark)
  (define-key lookup-summary-mode-map "#" 'lookup-summary-memorandum)
;  (define-key lookup-summary-mode-map "A" 'lookup-summary-add-entry)
;  (define-key lookup-summary-mode-map "C" 'lookup-summary-copy-entry)
;  (define-key lookup-summary-mode-map "D" 'lookup-summary-delete-entry)
;  (define-key lookup-summary-mode-map "E" 'lookup-summary-edit-entry)
;  (define-key lookup-summary-mode-map "O" 'lookup-summary-open-entry)
  ;; content access
  (define-key lookup-summary-mode-map "h" 'lookup-summary-content-window)
  (define-key lookup-summary-mode-map "s" 'lookup-summary-isearch-content)
  (define-key lookup-summary-mode-map "w" 'lookup-summary-cite-content)
  ;; toggle minor
  (define-key lookup-summary-mode-map "t" (make-sparse-keymap))
  (define-key lookup-summary-mode-map "l" 'lookup-summary-toggle-example)
  (define-key lookup-summary-mode-map "v" 'lookup-summary-toggle-overview)
  (define-key lookup-summary-mode-map "tb" 'lookup-summary-toggle-autobook)
  (define-key lookup-summary-mode-map "te" 'lookup-summary-toggle-example)
  (define-key lookup-summary-mode-map "tf" 'lookup-summary-toggle-format)
  (define-key lookup-summary-mode-map "tg" 'lookup-summary-toggle-gaiji)
  (define-key lookup-summary-mode-map "tv" 'lookup-summary-toggle-overview)
  ;; new session
  (define-key lookup-summary-mode-map "^" 'lookup-select-dictionaries)
;  (define-key lookup-summary-mode-map "I" 'lookup-summary-show-index)
  (define-key lookup-summary-mode-map "L" 'lookup-summary-list-references)
  (define-key lookup-summary-mode-map "M" 'lookup-summary-dictionary-menu)
  ;; redo
  (define-key lookup-summary-mode-map "g" (make-sparse-keymap))
  (define-key lookup-summary-mode-map "gg" 'lookup-summary-redo)
  (define-key lookup-summary-mode-map "g=" 'lookup-summary-redo-exactly)
  (define-key lookup-summary-mode-map "g@" 'lookup-summary-redo-keyword)
  (define-key lookup-summary-mode-map "g>" 'lookup-summary-redo-prefix)
  (define-key lookup-summary-mode-map "g<" 'lookup-summary-redo-suffix)
  (define-key lookup-summary-mode-map "g." 'lookup-summary-update-content)
  (define-key lookup-summary-mode-map "1" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "2" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "3" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "4" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "5" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "6" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "7" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "8" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "9" 'lookup-summary-redo-nth-dictionary)
  (define-key lookup-summary-mode-map "0" 'lookup-summary-redo-all-dictionary)
  )

(defvar lookup-summary-mode-hook nil)

(defvar lookup-summary-overview-mode nil)
(make-variable-buffer-local 'lookup-summary-overview-mode)
(or (assq 'lookup-summary-overview-mode minor-mode-alist)
    (setq minor-mode-alist (cons '(lookup-summary-overview-mode " Overview")
				 minor-mode-alist)))

(defvar lookup-summary-autobook-mode nil)
(or (assq 'lookup-summary-autobook-mode minor-mode-alist)
    (setq minor-mode-alist (cons '(lookup-summary-autobook-mode " Autobook")
				 minor-mode-alist)))

(defvar lookup-summary-line-module "")
(defvar lookup-summary-line-pattern "")
(defvar lookup-summary-line-number "0")

(make-variable-buffer-local 'lookup-summary-line-module)
(make-variable-buffer-local 'lookup-summary-line-pattern)
(make-variable-buffer-local 'lookup-summary-line-number)

(defun lookup-summary-mode ()
  "\\{lookup-summary-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (buffer-disable-undo)
  (setq major-mode 'lookup-summary-mode)
  (setq mode-name "Summary")
  (setq mode-line-buffer-identification
	'("Lookup:%b <" lookup-summary-line-module "> {"
	  lookup-summary-line-pattern "} ["
	  lookup-summary-line-number "]"))
  (setq lookup-help-message lookup-summary-mode-help)
  (setq truncate-lines t)
  (setq buffer-read-only t)
  (use-local-map lookup-summary-mode-map)
  (run-hooks 'lookup-summary-mode-hook))

;;;;;;;;;;;;;;;;;;;;
;; Interactive Commands
;;;;;;;;;;;;;;;;;;;;

(defun lookup-summary-display-content ()
  "$B%]%$%s%H9T$N%(%s%H%j$NK\J8$rI=<($9$k!#(B
Overview $B%b!<%I$K$J$C$F$$$k>l9g$K$O$=$l$r2r=|$7!"(BContent $B%P%C%U%!$r(B
$B%*!<%W%s$9$k!#%(%s%H%j$,%j%U%!%l%s%9$N>l9g$K$O!"$=$l$r;2>H$9$k!#(B"
  (interactive)
  (lookup-summary-goto-link)
  (let ((entry (lookup-summary-this-entry)))
    (when entry
      (setq lookup-summary-overview-mode nil)
      (lookup-content-display entry)
      (if lookup-summary-autobook-mode (lookup-summary-bookmark)))))

(defun lookup-summary-mouse-follow (event)
  "$B%^%&%9$G%/%j%C%/$7$?%(%s%H%j$NK\J8$rI=<($9$k!#(B"
  (interactive "e")
  (mouse-set-point event)
  (lookup-summary-display-content))

(defun lookup-summary-next-page ()
  "$B%(%s%H%jK\J8$NI=<($r0l%Z!<%8?J$a$k!#(B
$B%P%C%U%!$N=*$o$j$^$GC#$7$?$i!"<!$N%(%s%H%j$K0\F0$9$k!#(B"
  (interactive)
  (cond
   ((not (lookup-summary-this-entry)) nil)
   ((not (lookup-summary-content-visible-p)) (lookup-summary-display-content))
   ((lookup-with-buffer-and-window (lookup-content-buffer)
      (not (pos-visible-in-window-p (point-max) (selected-window))))
    (lookup-summary-scroll-up-content))
   (t (lookup-summary-next-entry))))

(defun lookup-summary-previous-page ()
  "$B%(%s%H%jK\J8$NI=<($r0l%Z!<%8La$9!#(B
$B%P%C%U%!$N;O$a$^$GC#$7$?$i!"A0$N%(%s%H%j$K0\F0$9$k!#(B"
  (interactive)
  (cond
   ((not (lookup-summary-this-entry)) (lookup-summary-previous-entry))
   ((not (lookup-summary-content-visible-p)) (lookup-summary-display-content))
   ((lookup-with-buffer-and-window (lookup-content-buffer)
      (not (pos-visible-in-window-p (point-min) (selected-window))))
    (lookup-summary-scroll-down-content))
   (t (lookup-summary-previous-entry))))

(defun lookup-summary-scroll-up-content (&optional arg)
  "$B%(%s%H%jK\J8$r%W%l%U%#%9%/$N9T?t$@$1%9%/%m!<%k!&%"%C%W$9$k!#(B"
  (interactive "p")
  (if (lookup-summary-content-visible-p)
      (lookup-with-buffer-and-window (lookup-content-buffer)
	(scroll-up arg))
    (lookup-summary-display-content)))

(defun lookup-summary-scroll-down-content (&optional arg)
  "$B%(%s%H%jK\J8$r%W%l%U%#%9%/$N9T?t$@$1%9%/%m!<%k!&%@%&%s$9$k!#(B"
  (interactive "p")
  (if (lookup-summary-content-visible-p)
      (lookup-with-buffer-and-window (lookup-content-buffer)
	(scroll-down arg))
    (lookup-summary-display-content)))

(defun lookup-summary-beginning-of-content ()
  "$B%(%s%H%jK\J8$NI=<($r@hF,$^$GLa$9!#(B"
  (interactive)
  (if (lookup-summary-content-visible-p)
      (lookup-with-buffer-and-window (lookup-content-buffer)
	(goto-char (point-min)))
    (lookup-summary-display-content)))

(defun lookup-summary-end-of-content ()
  "$B%(%s%H%jK\J8$NI=<($rKvHx$^$G?J$a$k!#(B"
  (interactive)
  (if (lookup-summary-content-visible-p)
      (lookup-with-buffer-and-window (lookup-content-buffer)
	(goto-char (point-max))
	(recenter -2))
    (lookup-summary-display-content)))

(defun lookup-summary-next-entry (&optional arg)
  "$B<!$N%(%s%H%j$rI=<($9$k!#%W%l%U%#%/%9$N?t$@$1?J$`!#(B"
  (interactive "p")
  (if (eobp)
      (progn (message "End of buffer") (ding))
    (forward-line arg)
    (lookup-summary-goto-link)
    (unless lookup-summary-overview-mode
      (or (pos-visible-in-window-p (save-excursion (forward-line) (point)))
	  (recenter -2))
      (lookup-summary-display-content))))

(defun lookup-summary-previous-entry (&optional arg)
  "$BA0$N%(%s%H%j$rI=<($9$k!#%W%l%U%#%/%9$N?t$@$1La$k!#(B"
  (interactive "p")
  (beginning-of-line)
  (if (bobp)
      (progn (message "Beginning of buffer") (ding))
    (forward-line (- (or arg 1)))
    (lookup-summary-goto-link)
    (unless lookup-summary-overview-mode
      (or (pos-visible-in-window-p (save-excursion (forward-line -1) (point)))
	  (recenter 1))
      (lookup-summary-display-content))))

(defun lookup-summary-info ()
  "$B%(%s%H%j$N>pJs$r=PNO$9$k!#(B"
  (interactive)
  (let ((entry (lookup-summary-this-entry)))
    (with-current-buffer (lookup-get-buffer "*Entry Information*")
      (help-mode)
      (let ((inhibit-read-only t)
	    (dict (lookup-entry-dictionary entry))
	    (heading (lookup-entry-heading entry))
	    (memo (lookup-entry-bookmark entry)))
	(erase-buffer)
	(insert (format "Entry information for `%s':\n\n" heading))
	(insert (format "Dictionary: %s\n" (lookup-dictionary-id dict)))
	(insert (format "Code:       %s\n" (lookup-entry-code entry)))
	(if (stringp memo) (insert "\n---- memorandum ----\n" memo))
	(goto-char (point-min)))
      (lookup-display-buffer (current-buffer)))))

(defun lookup-summary-mark ()
  (interactive)
  (let ((inhibit-read-only t))
    (save-excursion
      (beginning-of-line)
      (delete-char 1)
      (insert "*")))
  (if lookup-summary-overview-mode (next-line 1)))

(defun lookup-summary-unmark ()
  (interactive)
  (let ((entry (lookup-summary-this-entry)) memo)
    (when entry
      (when (or (not (stringp (lookup-entry-bookmark entry)))
		(progn (setq memo (lookup-summary-memorandum-display))
		       (y-or-n-p "Are you sure to remove this memorandum? ")))
	(setf (lookup-entry-bookmark entry) nil)
	(lookup-module-remove-bookmark (lookup-current-module) entry)
	(lookup-summary-update-mark))
      (when memo
	(lookup-hide-buffer memo)
	(if (not lookup-summary-overview-mode)
	    (lookup-summary-display-content)))
      (if lookup-summary-overview-mode (next-line 1)))))

(defun lookup-summary-bookmark ()
  (interactive)
  (let ((entry (lookup-summary-this-entry)) memo)
    (when entry
      (when (or (not (stringp (lookup-entry-bookmark entry)))
		(progn (setq memo (lookup-summary-memorandum-display))
		       (y-or-n-p "Are you sure to remove this memorandum? ")))
	(setf (lookup-entry-bookmark entry) t)
	(lookup-module-add-bookmark (lookup-current-module) entry)
	(lookup-summary-update-mark)))))

(defvar lookup-summary-memorandum-entry nil)

(defun lookup-summary-memorandum ()
  (interactive)
  (let ((buffer (lookup-summary-memorandum-display)))
    (when buffer
      (select-window (get-buffer-window buffer))
      (message "Type `C-c C-c' to finish editing"))))

(defun lookup-summary-memorandum-display ()
  (let* ((entry (lookup-summary-this-entry))
	 (memo (lookup-entry-bookmark entry)))
    (with-current-buffer (lookup-get-buffer "*Entry Memorandum*")
      (erase-buffer)
      (text-mode)
      (make-variable-buffer-local 'lookup-summary-memorandum-entry)
      (setq lookup-summary-memorandum-entry entry)
      (local-set-key "\C-c\C-c" 'lookup-summary-memorandum-save)
      (insert (if (stringp memo) memo
		(funcall lookup-initial-memorandum entry)))
      (goto-char (point-min))
      (lookup-display-buffer (current-buffer)))))

(defun lookup-summary-memorandum-save ()
  (interactive)
  (let ((entry lookup-summary-memorandum-entry))
    (setf (lookup-entry-bookmark entry) (buffer-string))
    (lookup-module-add-bookmark (lookup-current-module) entry))
  (kill-buffer (current-buffer))
  (select-window (get-buffer-window (lookup-summary-buffer)))
  (lookup-summary-display-content)
  (lookup-summary-update-mark))

(defun lookup-summary-entry-open ()
  "$B%(%s%H%jK\J8$rJL%W%m%0%i%`$GI=<($9$k!#(B"
  (interactive)
  (unless (lookup-entry-open (lookup-summary-this-entry))
    (error "This entry doesn't have a open command")))

(defun lookup-summary-toggle-format ()
  "$B%(%s%H%jK\J8$N@07A=hM}$r%H%0%k$9$k!#(B"
  (interactive)
  (with-current-buffer (lookup-content-buffer)
    (lookup-content-toggle-format)))

(defun lookup-summary-toggle-example ()
  (interactive)
  (setq lookup-enable-example (not lookup-enable-example))
  (with-current-buffer (lookup-content-buffer)
    (let ((inhibit-read-only t))
      (lookup-adjust-content lookup-content-entry)))
  (message (if lookup-enable-example "Examples enabled" "Examples disabled")))

(defun lookup-summary-toggle-autobook ()
  (interactive)
  (setq lookup-summary-autobook-mode (not lookup-summary-autobook-mode))
  (force-mode-line-update))

(defun lookup-summary-toggle-overview ()
  "Overview $B%b!<%I$KF~$k!#(B
Cotent $B%P%C%U%!$,%/%m!<%:$5$l!"(B`n' $B$H(B `p' $B$,C1$K%]%$%s%H0\F0$@$1$r(B
$B9T$J$&$h$&$K$J$k!#(B"
  (interactive)
  (if (setq lookup-summary-overview-mode (not lookup-summary-overview-mode))
      (lookup-hide-buffer (lookup-content-buffer))
    (lookup-display-buffer (lookup-content-buffer)))
  (force-mode-line-update))

(defun lookup-summary-isearch-content (&optional rexexp-p)
  "Content $B%P%C%U%!$G(B isearch-forward $B$r<B9T$9$k!#(B"
  (interactive "P")
  (lookup-with-buffer-and-window (lookup-content-buffer)
    (isearch-forward rexexp-p)))

(defun lookup-summary-cite-content ()
  "$B%(%s%H%jK\J8$r%-%k%j%s%0$KJ]B8$9$k!#(B
See also `lookup-content-cite-region'."
  (interactive)
  (unless (lookup-summary-content-visible-p)
    (lookup-summary-display-content))
  (with-current-buffer (lookup-content-buffer)
    (lookup-content-cite-region (point-max) (point-min)))
  (when (interactive-p)
    (message "Saved text for `%s'"
	     (lookup-entry-heading (lookup-summary-this-entry)))))

(defun lookup-summary-dictionary-menu ()
  "$B<-=q$,%a%K%e!<$KBP1~$7$F$$$k>l9g!"$=$l$r;2>H$9$k!#(B"
  (interactive)
  (let ((entry (lookup-summary-this-entry)))
    (when entry
      (let ((menu (lookup-dictionary-menu (lookup-entry-dictionary entry))))
	(if menu
	    (lookup-display-entries (lookup-current-module)
				    (lookup-new-query 'reference "Menu")
;				    (list menu))
				    menu)
	  (error "This dictionary doesn't have a menu"))))))

(defun lookup-summary-list-references ()
  "$B%(%s%H%jK\J8$K4^$^$l$k%j%U%!%l%s%9$r0lMw$9$k!#(B"
  (interactive)
  (unless (lookup-summary-content-visible-p)
    (lookup-summary-display-content))
  (let ((entries (lookup-content-collect-references)))
    (if entries
	(let* ((heading (lookup-entry-heading (lookup-summary-this-entry)))
	       (query (lookup-new-query 'reference heading)))
	  (lookup-display-entries (lookup-current-module) query entries))
      (error "No valid reference in this entry"))))

(defun lookup-summary-content-window ()
  "Content $B%P%C%U%!$K0\F0$9$k!#(B"
  (interactive)
  (unless (lookup-summary-content-visible-p)
    (lookup-summary-display-content))
  (select-window (get-buffer-window (lookup-content-buffer))))

;;;
;;; Redo
;;;

(defun lookup-summary-redo (&optional module)
  "$B:#2s$HF1$88!:w8l$G!"%(%s%H%j$r:F8!:w$9$k!#(B"
  (interactive (list (if current-prefix-arg (lookup-input-module))))
  (let ((query (lookup-session-query (lookup-current-session))))
    (if (not (eq (lookup-query-method query) 'reference))
	(let ((lookup-force-update t))
	  (lookup-search-query (or module (lookup-current-module)) query))
      (error "This session cannot be updated"))))

(defun lookup-summary-redo-exactly ()
  (interactive)
  (lookup-summary-redo-1 'exact))

(defun lookup-summary-redo-keyword ()
  (interactive)
  (lookup-summary-redo-1 'keyword))

(defun lookup-summary-redo-prefix ()
  (interactive)
  (lookup-summary-redo-1 'prefix))

(defun lookup-summary-redo-suffix ()
  (interactive)
  (lookup-summary-redo-1 'suffix))

(defun lookup-summary-redo-1 (method)
  (let* ((query (lookup-session-query (lookup-current-session)))
	 (string (lookup-query-string query)))
    (lookup-search-query (lookup-current-module)
			   (lookup-new-query method string))))

(defun lookup-summary-redo-nth-dictionary ()
  "Search again by using only the Nth dictionary in the current module.
This command should be binded to numerical keys (i.e., `1'..`9'),
which indicates the number of the dictionary."
  (interactive)
  (let* ((module (lookup-current-module))
	 (dict (nth (- (aref (this-command-keys) 0) ?1)
		    (lookup-module-dictionaries module)))
	 (lookup-search-dictionaries (list dict))
	 (query (lookup-session-query (lookup-current-session))))
    (if dict
	(lookup-search-query module query)
      (error "No dictionary on the number: %s" (this-command-keys)))))

(defun lookup-summary-redo-all-dictionary ()
  "Search again by using all dictionary in the current module."
  (interactive)
  (let* ((module (lookup-current-module))
	 (lookup-search-dictionaries (lookup-module-dictionaries module))
	 (query (lookup-session-query (lookup-current-session))))
    (lookup-search-query module query)))

(defun lookup-summary-update-content ()
  "$B%(%s%H%jK\J8$r:FI=<($9$k!#@07A=hM}$bA4$F$d$jD>$5$l$k!#(B"
  (interactive)
  (let ((lookup-force-update t))
    (lookup-summary-display-content)))

;;;;;;;;;;;;;;;;;;;;
;; Internal Functions
;;;;;;;;;;;;;;;;;;;;

(defun lookup-summary-goto-link ()
  (let ((p (line-beginning-position)))
    (if (setq p (next-single-property-change p 'lookup-entry))
	(goto-char p))))

(defun lookup-summary-this-entry ()
  (let ((entry (save-excursion
		 (end-of-line)
		 (if (not (eobp))
		     (get-text-property (1- (point)) 'lookup-entry)))))
    (when entry
      (if (not (eq (lookup-entry-type entry) 'dynamic))
	  (lookup-entry-substance entry)
	(lookup-summary-expand-references entry)
	(lookup-summary-this-entry)))))

(defun lookup-summary-update-mark ()
  (let ((inhibit-read-only t))
    (save-excursion
      (beginning-of-line)
      (delete-char 1)
      (lookup-search-query-insert-mark (lookup-summary-this-entry)))))

(defun lookup-summary-content-visible-p ()
  (and (get-buffer-window (lookup-content-buffer))
       (eq (lookup-summary-this-entry) (lookup-content-entry))))

(provide 'lookup-summary)

;;; lookup-summary.el ends here
