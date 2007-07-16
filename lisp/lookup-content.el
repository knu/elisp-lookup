;;; lookup-content.el --- Lookup Content mode
;; Copyright (C) 2000 Keisuke Nishida <knishida@ring.gr.jp>

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

(defconst lookup-content-mode-help
  "Lookup Content $B%b!<%I(B:

`SPC' - $B%Z!<%8$r?J$a$k(B          `<'   - $B%P%C%U%!$N:G=i$X(B
`DEL' - $B%Z!<%8$rLa$k(B            `>'   - $B%P%C%U%!$N:G8e$X(B

`TAB' - $B<!$N%j%s%/$X(B            `RET' - $B%j%s%/$rC)$k(B

`t'   - $B@07A=hM}$r%H%0%k$9$k(B    `w'   - $B%j!<%8%g%s$r0zMQ(B
`h'   - Entry $B%P%C%U%!$K0\F0(B    `g'   - $B%P%C%U%!$r99?7$9$k(B
`q'   - $B%P%C%U%!$rH4$1$k(B        `?'   - $B%X%k%W$rI=<((B")

(defvar lookup-content-mode-map nil
  "*Keymap for Lookup Content mode.")

(when (< (length lookup-content-mode-map) 2)
  (setq lookup-content-mode-map (make-sparse-keymap))
  (set-keymap-parent lookup-content-mode-map lookup-global-map)
  (define-key lookup-content-mode-map " " 'scroll-up)
  (define-key lookup-content-mode-map "\C-?" 'scroll-down)
  (define-key lookup-content-mode-map [delete] 'scroll-down)
  (define-key lookup-content-mode-map "<" 'beginning-of-buffer)
  (define-key lookup-content-mode-map ">" 'end-of-buffer)
  (define-key lookup-content-mode-map "\C-i" 'lookup-content-next-link)
  (define-key lookup-content-mode-map "\C-m" 'lookup-content-follow-link)
  (define-key lookup-content-mode-map "t" 'lookup-content-toggle-format)
  (define-key lookup-content-mode-map "w" 'lookup-content-cite-region)
  (define-key lookup-content-mode-map "h" 'lookup-content-entry-window)
  (define-key lookup-content-mode-map "g" 'lookup-content-update)
  (define-key lookup-content-mode-map "q" 'lookup-content-leave)
  (define-key lookup-content-mode-map
    (if (featurep 'xemacs) 'button2 [mouse-2]) 'lookup-content-mouse-follow)
  )

(defvar lookup-content-mode-hook nil)

(defvar lookup-content-entry nil)
(defvar lookup-content-line-heading nil)

(make-variable-buffer-local 'lookup-content-entry)
(make-variable-buffer-local 'lookup-content-line-heading)

;;;###autoload
(defun lookup-content-mode ()
  "\\{lookup-content-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (buffer-disable-undo)
  (setq major-mode 'lookup-content-mode)
  (setq mode-name "Content")
  (setq mode-line-buffer-identification
	'("Lookup:%b {" lookup-content-line-heading "}"))
  (setq lookup-help-message lookup-content-mode-help)
  (setq buffer-read-only t)
  (make-variable-buffer-local 'line-move-ignore-invisible)
  (setq line-move-ignore-invisible t)
  (use-local-map lookup-content-mode-map)
  (run-hooks 'lookup-content-mode-hook))

;;;
;;; Interactive commands
;;;

(defun lookup-content-next-link ()
  "$B<!$N%j%s%/$K0\F0$9$k!#(B"
  (interactive)
  (if (lookup-goto-next-link)
      (message (lookup-entry-id (lookup-get-link (point))))
    (if (lookup-get-link (point))
	(error "No more link in this buffer")
      (goto-char (point-min))
      (if (lookup-goto-next-link)
	  (message (lookup-entry-id (lookup-get-link (point))))
	(error "No link in this buffer")))))

(defun lookup-content-follow-link ()
  "$B%]%$%s%H0LCV$N%j%s%/$r;2>H$9$k!#(B"
  (interactive)
  (let ((entry (lookup-get-link (point))))
    (if entry
	(let ((entries (lookup-entry-substance entry)))
	  (if (setq entries (if entries
				(list entries)
			      (lookup-entry-references entry)))
	      (let* ((heading (lookup-entry-heading lookup-content-entry))
		     (query (lookup-new-query 'reference heading)))
		(lookup-display-entries (lookup-current-module) query entries))
	    (error "This link is torn off")))
      (error "No link here"))))

(defun lookup-content-mouse-follow (event)
  "$B%^%&%9$G%/%j%C%/$7$?%j%s%/$r;2>H$9$k!#(B"
  (interactive "e")
  (mouse-set-point event)
  (lookup-content-follow-link))

(defun lookup-content-toggle-format ()
  "$BK\J8$N@07A=hM}$r%H%0%k$9$k!#(B"
  (interactive)
  (setq lookup-enable-format (not lookup-enable-format))
  (lookup-content-display lookup-content-entry))

(defun lookup-content-cite-region (start end)
  "$B%j!<%8%g%s$NFbMF$r%-%k%j%s%0$KJ]B8$9$k!#(B
$B$=$N:]!"JQ?t(B `lookup-cite-header' $B$^$?$O<-=q%*%W%7%g%s(B `cite-header'
$B$K$h$j0zMQ;~$N%X%C%@$r!"JQ?t(B `lookup-cite-prefix' $B$^$?$O<-=q%*%W%7%g%s(B
`cite-prefix' $B$K$h$j0zMQ;~$N%W%l%U%#%/%9$r;XDj$9$k$3$H$,=PMh$k!#(B"
  (interactive "r")
  (let* ((dictionary (lookup-entry-dictionary lookup-content-entry))
	 (header (or (lookup-dictionary-option dictionary :cite-header t)
		     lookup-cite-header))
	 (prefix (or (lookup-dictionary-option dictionary :cite-prefix t)
		     lookup-cite-prefix))
	 (contents (buffer-substring-no-properties start end)))
    (when prefix
      (with-temp-buffer
	(insert contents)
	(goto-char (point-min))
	(while (not (eobp))
	  (insert prefix)
	  (forward-line))
	(setq contents (buffer-string))))
    (when header
      (let ((title (lookup-dictionary-title dictionary)))
	(while (string-match "%T" header)
	  (setq header (replace-match title t t header))))
      (setq contents (concat header contents)))
    (kill-new contents)
    (if transient-mark-mode (setq deactivate-mark t))
    (when (interactive-p)
      (if (pos-visible-in-window-p (mark) (selected-window))
	  (let ((inhibit-quit t))
	    (save-excursion (goto-char (mark)) (sit-for 1)))
	(let ((len (min (abs (- end start)) 40)))
	  (if (= (point) start)
	      (message "Saved text until \"%s\""
		       (buffer-substring (- end len) end))
	    (message "Saved text from \"%s\""
		     (buffer-substring start (+ start len)))))))))

(defun lookup-content-entry-window ()
  "Entry $B%P%C%U%!$K0\F0$9$k!#(B"
  (interactive)
  (select-window (get-buffer-window (lookup-summary-buffer))))

(defun lookup-content-update ()
  "$B%-%c%C%7%e$rMQ$$$:$KK\J8$rFI$_D>$9!#(B"
  (interactive)
  (let ((lookup-force-update t))
    (lookup-content-display lookup-content-entry)))

(defun lookup-content-leave ()
  "Content $B%P%C%U%!$rH4$1$k!#(B"
  (interactive)
  (lookup-hide-buffer (current-buffer))
  (lookup-summary-display-content))

;;;
;;; Useful functions
;;;

(defun lookup-content-entry ()
  (with-current-buffer (lookup-content-buffer)
    lookup-content-entry))

(defun lookup-content-collect-references ()
  (with-current-buffer (lookup-content-buffer)
    (let (entries)
      (lookup-map-over-property
       (point-min) (point-max) 'lookup-reference
       (lambda (start end entry)
	 (setq entries (cons entry entries))))
      (nreverse entries))))

(provide 'lookup-content)

;;; lookup-content.el ends here
