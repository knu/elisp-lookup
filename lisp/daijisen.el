;;; daijisen.el --- search agent for $B>.3X4[!XBg<-@t!Y(B
;; Copyright (C) 2002 yamagata@nwgpc.kek.jp

;; Author: yamagata@nwgpc.kek.jp
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

;;
;; $B;H$$J}(B
;;
;; (setq lookup-search-agents
;;      '((daijisen "/cdrom")))
;;
;; $B$N$h$&$K(B(daijisen "/cdrom")$B$rDI2C$9$k$@$1!#(B
;; $B$R$i$,$J$+%"%k%U%!%Y%C%H$G$7$+8!:w$G$-$J$$$N$G!"(Bkakasi$BI,?\$G$9!#(B
;; $B:#$N$H$3$m!"%a%K%e!<$NBP1~$NJ}:v$N$a$I$O$?$C$F$$$^$;$s!#(B
;;

;;; Code:

(require 'lookup)
(require 'lookup-kanji)

;;;
;;; Customizable variables
;;;

(defgroup daijisen nil
  "Lookup daijisen interface."
  :group 'lookup-search-agents)

(defcustom daijisen-program-name "daijisen"
  "*$BBg<-@t(BCDROM$B$r8!:w$9$k%W%m%0%i%`L>(B"
  :type 'string
  :group 'daijisen)

(defcustom daijisen-dictionary-title "$BBg<-@t(B"
  "*Title of daijisen dictionary."
  :type 'string
  :group 'daijisen)

(defcustom daijisen-process-coding-system lookup-process-coding-system
  "*Coding system for daijisen process."
  :type 'symbol
  :group 'daijisen)


;;;
;;; types
;;;

(put 'daijisen :methods '(exact prefix suffix))
(put 'daijisen :reference-pattern
     '("[$B"N"M"*(B]\\([$B!<$!(B-$B$s%!(B-$B%v0!(B-$Bs~(B]+\\)" 0 1 lookup-dynamic-search))


;;;
;;; Interface functions
;;;

(put 'daijisen :list 'daijisen-list)
(defun daijisen-list (agent)
  (list (lookup-new-dictionary agent daijisen-program-name)))

(put 'daijisen :title daijisen-dictionary-title)

(put 'daijisen :search 'daijisen-dictionary-search)
(defun daijisen-dictionary-search (dictionary query)
  (with-current-buffer (get-buffer-create " *daijisen*")
    (goto-char (point-max))
    (let* ((opts (lookup-get-property dictionary 'daijisen-opts))
	   (qstr (lookup-query-to-wildcard query))
	   (kanji (string-match "[$B%!(B-$B%v0!(B-$Bt&(B]" qstr))
	   yomi-list)
      (unless opts
	(let* ((agent (lookup-dictionary-agent dictionary))
	       (dir (expand-file-name (lookup-agent-location agent))))
	  (setq opts `(,(format "-d%s" dir))))
	(lookup-put-property dictionary 'daijisen-opts opts))
      (and
       kanji
       (setq yomi-list (lookup-kanji-get-readings qstr)))
      (setq opts
	    (append
	     opts
	     (cons "-l" (if kanji yomi-list (list qstr)))))
      (if lookup-enable-debug
	  (insert "> " daijisen-program-name " " (mapconcat 'eval opts " ") "\n"))
      (save-excursion
	(lookup-with-coding-system daijisen-process-coding-system
	  (apply 'call-process daijisen-program-name nil t nil
		 (mapcar
		  (lambda (str)
		    (encode-coding-string
		     str
		     daijisen-process-coding-system))
		  opts))))
      (and
       kanji
       (< 8 (length (car yomi-list)))
       (setq kanji nil)
       (message "too long query, turn off filter"))
      (let (entries)
	(if kanji
	    (while (search-forward (lookup-query-string query) nil t)
	      (save-excursion
		(beginning-of-line)
		(looking-at "^\\([^\n ]+\\) *\t\\([0-9.]+\\)$")
		(setq
		 entries
		 (cons
		  (lookup-new-entry 'regular dictionary (match-string 2) (match-string 1))
		  entries))))
	  (while (re-search-forward "^\\([^\n ]+\\) *\t\\([0-9.]+\\)$" nil t)
	    (setq
	     entries
	     (cons
	      (lookup-new-entry 'regular dictionary (match-string 2) (match-string 1))
	      entries))))
	(if (not lookup-enable-debug) (kill-buffer (current-buffer)))
	(nreverse entries)))))
    

(put 'daijisen :content 'daijisen-entry-content)
(defun daijisen-entry-content (entry)
  (with-current-buffer (get-buffer-create " *daijisen*")
    (goto-char (point-max))
    (let ((opts (lookup-get-property (lookup-entry-dictionary entry) 'daijisen-opts))
	  (code (lookup-entry-code entry)))
      (setq opts (append opts (list code)))
      (if lookup-enable-debug
	  (insert "> " daijisen-program-name " " (mapconcat 'eval opts " ") "\n"))
      (save-excursion
	(lookup-with-coding-system daijisen-process-coding-system
	  (apply 'call-process daijisen-program-name nil t nil opts)))
      (buffer-substring (point) (point-max)))))

(provide 'daijisen)

;;; daijisen.el ends here
