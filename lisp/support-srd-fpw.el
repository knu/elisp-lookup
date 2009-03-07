;;; srd-fpw.el --- supplement file for $B!X%i%s%@%`%O%&%91Q8l<-E5!Y(B

;; Copyright (C) 2000 Keisuke Nishida <kxn30@po.cwru.edu>
;; Copyright (C) 2000 Kazuhiko Shiozaki <kazuhiko@ring.gr.jp>
;; Copyright (C) 2000 Kazuyoshi KOREEDA <k_koreed@d2.dion.ne.jp>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Code:

(require 'lookup)
(require 'poem)

(defvar srd-fpw-data-directory "/usr/local/dict/srd"
  "img.dat, srdra.bnd $B$N$"$k>l=j!#(B")
(defvar play-realaudio-process "realplay"
  "RealAudio $B$r:F@8$9$k%W%m%;%9L>!#(Bnil $B$J$i:F@8$7$J$$!#(B")
(defvar display-image-process "display"
  "$B2hA|(B $B$rI=<($9$k%W%m%;%9L>!#(Bnil $B$J$iI=<($7$J$$!#(B")
(defvar srd-fpw-sound-without-notice nil
  "t $B$J$i8!:w$HF1;~$K2;@<$r:F@8$9$k!#(B")
(defvar display-image-inline t
  "nil $B$J$i(B ($B2DG=$J>l9g$G$b(B) $B2hA|$r%$%s%i%$%sI=<($7$J$$!#(B")
(defvar perl-process "perl"
  "perl $B$N%W%m%;%9L>!#%Q%9$,DL$C$F$$$J$$>l9g$O%U%k%Q%9$G5-=R$9$k$3$H!#(B")

(defvar srd-fpw-tmp-dir temporary-file-directory "$B0l;~%U%!%$%k$N:n@.>l=j(B")

(defvar srd-fpw-process-file-alist '())

;; 
;; $B85$+$i$"$k(B lookup-content-follow-link$B$N3HD%(B
;; 
; (unless (fboundp 'lookup-content-follow-link:old)
;   (fset 'lookup-content-follow-link:old
; 	  (symbol-function 'lookup-content-follow-link))
;   (defun lookup-content-follow-link ()
;     (interactive)
;     (let ((action (get-text-property (point) 'action)))
; 	(if action 
; 	    (funcall action (point))
; 	  (lookup-content-follow-link:old)))))

(defun srd-fpw-arrange-structure (entry)
  (srd-fpw-arrange-images entry)
  (goto-char (point-min))
  (srd-fpw-arrange-realaudio entry))

(defun srd-fpw-arrange-images (entry)
  (while (re-search-forward
	  "<image=\\([^:]+\\):\\([^>]+\\)>" nil t)
    (let ((file "img.dat")
	  (offset (match-string 1))
	  (length (match-string 2))
	  (start (match-beginning 0))
	  (end (match-end 0)))
      ;; Find data file.
      (if (file-exists-p (expand-file-name file srd-fpw-data-directory))
	  (setq file (expand-file-name file srd-fpw-data-directory)))
      (progn
	(replace-match "$B"*(B[$B2hA|(B]")
	(add-text-properties start 
			     (+ (length "$B"*(B[$B2hA|(B]") start)
			     (list 'action 'srd-fpw-display-image
				   'file  file
				   'offset offset
				   'mouse-face 'highlight
				   'face 'lookup-reference-face
				   'length   length))))))

(defun srd-fpw-arrange-realaudio (entry)
  (while (re-search-forward
	  "<sound=\\([^:]+\\):\\([^>]+\\)>" nil t)
    (let ((file "srdra.bnd")
	  (offset (match-string 1))
	  (length (match-string 2))
	  (start (match-beginning 0))
	  (end (match-end 0)))
      ;; Find data file.
      (if (file-exists-p (expand-file-name file srd-fpw-data-directory))
	  (setq file (expand-file-name file srd-fpw-data-directory)))
      (if srd-fpw-sound-without-notice
	  (let* ((tmp-snd-file
		  (make-temp-name 
		   (expand-file-name "sr" temporary-file-directory)))
		 )
	    (if play-realaudio-process
		(progn
		  (call-process
		   perl-process nil nil nil
		   (expand-file-name "extract.pl" lookup-support-directory)
		   file offset length tmp-snd-file)
		  (srd-fpw-start-process play-realaudio-process
					 nil tmp-snd-file t)))))
      (replace-match "$B"*(B[$B2;@<(B]")
      (add-text-properties start 
			   (+ (length "$B"*(B[$B2;@<(B]") start)
			   (list 'action 'srd-fpw-play-realaudio
				 'file  file
				 'offset offset
				 'mouse-face 'highlight
				 'face 'lookup-reference-face
				 'length   length)))))
;;
;; $B30It%W%m%;%9$rMxMQ$7$?%$%a!<%8$NI=<((B
;;
(defun srd-fpw-display-image (pos)
  (let* ((file (get-text-property pos 'file))
	 (offset (get-text-property pos 'offset))
	 (length (get-text-property pos 'length))
	 (tmp-img-file (make-temp-name 
			(expand-file-name "sr" temporary-file-directory))))
    (if display-image-process
	(progn
	  (call-process
	   perl-process nil nil nil
	   (expand-file-name "extract.pl" lookup-package-directory)
	   file offset length tmp-img-file)
	  (srd-fpw-start-process display-image-process nil tmp-img-file t)))))
;;
;; $B30It%W%m%;%9$rMxMQ$7$?2;@<$N:F@8(B
;;
(defun srd-fpw-play-realaudio (pos)
  (let* ((file (get-text-property pos 'file))
	 (offset (get-text-property pos 'offset))
	 (length (get-text-property pos 'length))
	 (tmp-snd-file (make-temp-name 
			(expand-file-name "sr" temporary-file-directory)))
	 )
    (if play-realaudio-process
	(progn
	  (call-process
	   perl-process nil nil nil
	   (expand-file-name "extract.pl" lookup-package-directory)
	   file offset length tmp-snd-file)
	  (srd-fpw-start-process play-realaudio-process nil tmp-snd-file t)))))
;;
;; $B30It%W%m%;%9$N8F=P$7(B
;; 
(defun srd-fpw-start-process (program options file &optional delete-file)
  (message "Starting %s ..." program)
  (let ((pro (apply (function start-process)
		    (format "*srd-fpw %s*" program)
		    nil
		    "ssh"
		    (append (list "kei" program)
			    options (list (concat "/mnt/indy" file))))))
    (message "Starting %s ... done" program)
    (set-process-sentinel pro 'srd-fpw-start-process-sentinel)
    (setq srd-fpw-process-file-alist 
	  (cons (cons pro file) 
		(if delete-file 
		    srd-fpw-process-file-alist
		  nil)))))
;;
;; $B%W%m%;%9$N>uBV$,JQ99$5$l$?$H$-$K%U%!%$%k$r:o=|$9$k!#(B
;;
(defun srd-fpw-start-process-sentinel (process event)
  (let ((al (assoc process srd-fpw-process-file-alist)))
    (and (cdr al) (delete-file (cdr al)))
    (setq srd-fpw-process-file-alist
	  (delete al srd-fpw-process-file-alist))))

(setq lookup-support-options
      (list :arranges '((structure srd-fpw-arrange-structure))))

;;; srd-fpw.el ends here
