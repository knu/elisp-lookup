;;; lookup-cache.el --- disk cache routines
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

(defconst lookup-dump-functions
  '(lookup-dump-modules
    lookup-dump-agent-attributes
    lookup-dump-module-attributes
    lookup-dump-dictionary-attributes
    lookup-dump-entry-attributes))

(defvar lookup-agent-attributes nil)
(defvar lookup-module-attributes nil)
(defvar lookup-dictionary-attributes nil)
(defvar lookup-entry-attributes nil)


;;;
;;; Interface functions
;;;

(defconst lookup-cache-notes "\
;; The definitions in this file overrides those in ~/.lookup.
;; If you want to modify this file by hand, follow this instruction:
;;
;;   1. M-x lookup-exit
;;   2. Edit this file as you like.
;;   3. M-x lookup-restart")

(defun lookup-dump-cache (file)
  (let ((name (file-name-nondirectory file)))
    (with-temp-buffer
      (insert ";;; " name " --- Lookup cache file\t\t-*- emacs-lisp -*-\n")
      (insert ";; Generated by `lookup-dump-cache' on "
	      (format-time-string "%Y/%m/%d") ".\n\n")
      (insert lookup-cache-notes "\n\n")
      (mapc 'funcall lookup-dump-functions)
      (insert "\n;;; " name " ends here\n")
      (write-region (point-min) (point-max) (expand-file-name file)))))


;;;
;;; Search modules
;;;

(defun lookup-dump-modules ()
  (setq lookup-search-modules
	(mapcar (lambda (module)
		  (cons (lookup-module-name module)
			(mapcar (lambda (dict)
				  (lookup-dump-modules-dictionary module dict))
				(lookup-module-dictionaries module))))
		lookup-module-list))
  (lookup-dump-list 'lookup-search-modules 2))

(defun lookup-dump-modules-dictionary (module dict)
  (list (lookup-dictionary-id dict)
	:priority (lookup-module-dictionary-priority module dict)))


;;;
;;; Agent attributes
;;;

(defun lookup-dump-agent-attributes ()
  (setq lookup-agent-attributes
	(mapcar (lambda (agent)
		  (list (lookup-agent-id agent)
			(cons 'dictionaries
			      (mapcar 'lookup-dictionary-name
				      (lookup-agent-dictionaries agent)))))
		lookup-agent-list))
  (lookup-dump-list 'lookup-agent-attributes 2))

(defun lookup-restore-agent-attributes (agent)
  (let ((alist (lookup-assoc-ref 'lookup-agent-attributes
				 (lookup-agent-id agent))))
    (lookup-put-property
     agent 'dictionaries
     (mapcar (lambda (name) (lookup-new-dictionary agent name))
	     (lookup-assq-get alist 'dictionaries)))))


;;;
;;; Module attributes
;;;

(defun lookup-dump-module-attributes ()
  (dolist (module lookup-module-list)
    (let (alist)
      (let ((marks (mapcar 'lookup-entry-id
			   (lookup-module-bookmarks module))))
	(if marks (lookup-assq-set 'alist 'bookmarks marks)))
      (lookup-assoc-set 'lookup-module-attributes
			(lookup-module-name module) alist)))
  (lookup-dump-list 'lookup-module-attributes 3))

(defun lookup-dump-module-attributes--session (session)
  (let ((type (lookup-session-type session)))
    (cond ((eq type 'lookup-select-session) (list type))
	  ((eq type 'lookup-search-query)
	   (let ((query (lookup-session-query session)))
	     (cons type (list (lookup-query-method query)
			      (lookup-query-string query)
			      (lookup-query-pattern query))))))))

(defun lookup-restore-module-attributes (module)
  (let ((alist (lookup-assoc-ref 'lookup-module-attributes
				 (lookup-module-name module))))
    (let ((marks (mapcar 'lookup-get-entry-create
			 (lookup-assq-ref 'alist 'bookmarks))))
      (setf (lookup-module-bookmarks module) marks))))


;;;
;;; Dictionary attributes
;;;

(defun lookup-dump-dictionary-attributes ()
  (setq lookup-dictionary-attributes
	(mapcar (lambda (dict)
		  (list (lookup-dictionary-id dict)
			(cons 'title (lookup-dictionary-title dict))
			(cons 'methods (lookup-dictionary-methods dict))))
		lookup-dictionary-list))
  (lookup-dump-list 'lookup-dictionary-attributes 2))

(defun lookup-restore-dictionary-attributes (dictionary)
  (dolist (pair (lookup-assoc-ref 'lookup-dictionary-attributes
				  (lookup-dictionary-id dictionary)))
    (lookup-put-property dictionary (car pair) (cdr pair))))


;;;
;;; Entry attributes
;;;

(defun lookup-dump-entry-attributes ()
  (dolist (entry (lookup-entry-list))
    (let ((id (lookup-dictionary-id (lookup-entry-dictionary entry)))
	  (bookmark (lookup-entry-bookmark entry))
	  plist heading)
      (when (and bookmark lookup-cache-bookmarks)
	(setq plist (plist-put plist 'bookmark bookmark)))
      (when plist
	(setq heading (lookup-get-property entry 'original-heading))
	(setq plist (plist-put plist 'heading heading)))
      (let ((alist (lookup-assoc-ref 'lookup-entry-attributes id)))
	(setq alist (lookup-assoc-put alist (lookup-entry-code entry) plist))
	(lookup-assoc-set 'lookup-entry-attributes id alist))))
  (lookup-dump-list 'lookup-entry-attributes 2))

(defun lookup-restore-entry-attributes (entry)
  (let* ((id (lookup-dictionary-id (lookup-entry-dictionary entry)))
	 (alist (lookup-assoc-ref 'lookup-entry-attributes id))
	 (plist (lookup-assoc-get alist (lookup-entry-code entry))))
    (when plist
      (lookup-put-property entry 'original-heading
				 (plist-get plist 'heading))
      (when lookup-cache-bookmarks
	(setf (lookup-entry-bookmark entry) (plist-get plist 'bookmark))))))


;;;
;;; Internal functions
;;;

(defun lookup-dump-list (symbol &optional level)
  (when (symbol-value symbol)
    (insert "(setq " (symbol-name symbol))
    (let ((list (symbol-value symbol)))
      (if (not level)
	  (insert (format "'%S)\n" list))
	(insert "\n      '(")
	(lookup-dump-list-1 list 0 (1- level))
	(insert "))\n\n")))))

(defun lookup-dump-list-1 (list layer level)
  (let* ((emp "") (prefix emp))
    (while list
      (if (or (= layer level) (not (listp (car list))))
	  (insert prefix (format "%S" (car list)))
	(insert prefix "(")
	(lookup-dump-list-1 (car list) (1+ layer) level)
	(insert ")"))
      (if (eq prefix emp)
	  (setq prefix (concat "\n\t" (make-string layer ? ))))
      (setq list (cdr list)))))

(provide 'lookup-cache)

;;; lookup-cache.el ends here
