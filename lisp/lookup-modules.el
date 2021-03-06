;;; lookup-modules.el --- Lookup modules mode
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

(defvar lookup-modules-killed-modules nil)

;;;###autoload
(defun lookup-list-modules ()
  (interactive)
  (with-current-buffer (lookup-get-buffer " *Module List*")
    (setq lookup-modules-killed-modules nil)
    (lookup-modules-mode)
    (lookup-modules-build-buffer)
    (setq buffer-undo-list nil)
    (buffer-enable-undo)
    (set-buffer-modified-p nil)
    (lookup-modules-goto-first)
    (lookup-pop-to-buffer (current-buffer))))

(defun lookup-modules-build-buffer ()
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert "Lookup Module List  (First module in list will be default module)\n")
    (insert "Type `c' to create module, `v' to visit, "
	    "`q' to leave, `?' for help.\n\n")
    (lookup-table-insert
     "%c %-8t %s\n"
     (append
      '((?% "Name" "Dictionaries")
	(?- "----" "------------"))
      (mapcar (lambda (module)
		(let* ((dicts (lookup-module-dictionaries module))
		       (str (mapconcat 'lookup-dictionary-name dicts "/")))
		  (list ? (lookup-module-name module)
			(format "[%d] %s" (length dicts) str))))
	      lookup-module-list)))))

(defun lookup-modules-update-buffer ()
  "Update buffer."
  (let ((line (lookup-current-line)))
    (lookup-modules-build-buffer)
    (goto-line line)))

;;;
;;; Modules Mode
;;;

(defconst lookup-modules-mode-help
  "Lookup Modules mode:")

(defvar lookup-modules-mode-map nil
  "*Keymap for Lookup Modules mode.")

(unless lookup-modules-mode-map
  (setq lookup-modules-mode-map (make-sparse-keymap))
  (set-keymap-parent lookup-modules-mode-map lookup-global-map)
  ;; general commands
  (define-key lookup-modules-mode-map " " 'next-line)
  (define-key lookup-modules-mode-map "n" 'next-line)
  (define-key lookup-modules-mode-map "p" 'previous-line)
  ;; module management
  (define-key lookup-modules-mode-map "c" 'lookup-modules-create-module)
  (define-key lookup-modules-mode-map "r" 'lookup-modules-rename-module)
  (define-key lookup-modules-mode-map "\ey" 'lookup-modules-wrap-command)
  (define-key lookup-modules-mode-map "\C-k" 'lookup-modules-wrap-command)
  (define-key lookup-modules-mode-map "\C-y" 'lookup-modules-wrap-command)
  (define-key lookup-modules-mode-map "\C-x\C-t" 'lookup-modules-wrap-command)
  (define-key lookup-modules-mode-map [?\C-/] 'lookup-modules-wrap-command)
  ;; general commands
  (define-key lookup-modules-mode-map "v" 'lookup-modules-visit-module)
  (define-key lookup-modules-mode-map "g" 'lookup-modules-update)
  (define-key lookup-modules-mode-map "q" 'lookup-leave)
  )

(defvar lookup-modules-mode-hook nil
  "*Hook for Lookup select mode.")

(defvar lookup-modules-kill-ring nil)

(defun lookup-modules-mode ()
  "\\{`lookup-modules-mode-map'}."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'lookup-modules-mode)
  (setq mode-name "Select")
  (setq mode-line-buffer-identification
	'("Lookup:%12b <" (lookup-module-name (lookup-current-module)) ">"))
  (setq lookup-help-message lookup-modules-mode-help)
  (setq buffer-read-only t)
  (setq truncate-lines t)
  (use-local-map lookup-modules-mode-map)
  (run-hooks 'lookup-modules-mode-hook))

;;;
;;; Interactive Commands
;;;

(defun lookup-modules-create-module (name)
  "Create new module with specified NAME."
  (interactive "sModule name: ")
  (setq name (replace-regexp-in-string "[\x00-\x1f]" "" name))
  (setq name (replace-regexp-in-string "[\t ]+$" "" name))
  (if (lookup-get-module name)
      (error "Module `%s' already exists" name))
  (let ((modules lookup-module-list)
        (module (lookup-modules-this-module))
        (new-module (lookup-new-module name t)))
    (if (eq module (car modules))
        (setq lookup-module-list (cons new-module modules))
      (while (not (eq module (cadr modules))) (setq modules (cdr modules)))
      (setcdr modules (cons new-module (cdr modules)))))
  (lookup-modules-update-buffer))

(defun lookup-modules-rename-module ()
  "Rename existing module Module with specified name."
  (interactive)
  (let* ((module (lookup-modules-this-module))
         (old-name (lookup-module-name module))
         (new-name
          (lookup-read-string
           (format "Rename module name `%s' to" old-name))))
    (setq new-name (replace-regexp-in-string "[\x00-\x1f]" "" new-name))
    (setq new-name (replace-regexp-in-string "[\t ]+$" "" new-name))
    (if (lookup-get-module new-name)
      (error "Module `%s' already exists" new-name))
    (setf (lookup-module-name module) new-name))
  (lookup-modules-update-buffer))

(defun lookup-modules-wrap-command (arg)
  "Call the corresponding global command with keys and reset dictionaries.
This command should be binded for the same keys with the commands
`kill-line', `yank', `yank-pop',`transpose-lines', or `undo'.
When this command is called, the variable `lookup-modules-kill-ring'
will be used instead of the usual `kill-ring'."
  (interactive "P")
  (let ((kill-ring lookup-modules-kill-ring)
	(kill-whole-line t)
	(inhibit-read-only t))
    (beginning-of-line)
    (unwind-protect
	(progn
	  (use-local-map global-map)
	  (call-interactively (key-binding (this-command-keys))))
      (use-local-map lookup-modules-mode-map))
    (setq lookup-modules-kill-ring kill-ring)
    (lookup-modules-reset-modules)
    (lookup-modules-update-buffer)))

(defun lookup-modules-update ()
  (interactive)
  (let* ((module (lookup-current-module))
	 (message (format "Updating %s..." (lookup-module-name module))))
    (message message)
    ;; (dolist (dict (lookup-module-dictionaries module))
    ;;   (lookup-dictionary-setplist dict nil))
    (lookup-modules-update-buffer)
    (message (concat message "done"))))

(defun lookup-modules-visit-module ()
  (interactive)
  (lookup-select-dictionaries (lookup-modules-this-module)))

;;;
;;; Internal functions
;;;

(defun lookup-modules-goto-first ()
  (goto-char (point-min))
  (forward-line 5))

(defun lookup-modules-set-mark (mark)
  (let ((inhibit-read-only t))
    (beginning-of-line)
    (delete-char 1)
    (insert-char mark 1))
  (forward-line))

(defun lookup-modules-this-module ()
  "Return the current line module or nil.  It also looks from killed-modules."
  (save-excursion
    (beginning-of-line)
    (goto-char (+ (point) 2))
    (let ((lookup-property (plist-get (text-properties-at (point)) 'lookup)))
      (and lookup-property
           (or (lookup-get-module (elt lookup-property 1))
               (lookup-get-module (elt lookup-property 1) lookup-modules-killed-modules))))))

(defun lookup-modules-reset-modules ()
  "Reset the current module settings as of buffer."
  (save-excursion
    (lookup-modules-goto-first)
    (let ((old-modules lookup-module-list) module modules)
      (while (setq module (lookup-modules-this-module))
	(setq modules (cons module modules))
	(forward-line))
      (setq lookup-modules-killed-modules
            (nunion lookup-modules-killed-modules
                    (set-difference lookup-module-list modules)))
      (setq lookup-module-list (nreverse modules)))))

(provide 'lookup-modules)

;;; lookup-modules.el ends here
