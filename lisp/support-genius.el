;;; genius.el --- support file for $B!X%8!<%K%"%91QOB!&OB1Q<-E5!Y(B
;; Copyright (C) 2000 Keisuke Nishida <knsihida@ring.gr.jp>

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

(defconst genius-gaiji-table
  (lookup-new-gaiji-table
   '(("ha121" . ",Aa(B")
     ("ha122" . ",A`(B")
     ("ha123" . ",0,(B")
     ("ha124" . ",0,(B'")
     ("ha125" . ",0,(B`")
     ("ha127" . ",0+(B")
     ("ha12a" . ",0'(B")
     ("ha12b" . ",0'(B'")
     ("ha12e" . ",Ai(B")
     ("ha12f" . ",Ah(B")
     ("ha134" . ",Am(B")
     ("ha135" . ",Al(B")
     ("ha136" . ",As(B")
     ("ha137" . ",Ar(B")
     ("ha13a" . ",07(B")
     ("ha13e" . ",Az(B")
     ("ha13f" . ",Ay(B")
     ("ha143" . ",0$(B")
     ("ha149" . "g")
     ("ha14a" . ",0U(B")
     ("ha14b" . ",03(B-")
     ("ha14c" . ",0I(B")
     ("ha14d" . ",0L(B")
     ("ha152" . ",0M(B")
     ("ha154" . ",0r(B")
     ("ha155" . ",Aa(B")
     ("ha156" . ",A`(B")
     ("ha157" . ",Ai(B")
     ("ha158" . ",Ah(B")
     ("ha159" . ",Am(B")
     ("ha15a" . ",Al(B")
     ("ha15b" . ",As(B")
     ("ha15c" . ",Ar(B")
     ("ha15d" . ",Az(B")
     ("ha15e" . ",Ay(B")
     ("ha161" . ",Ag(B")
     ("ha16a" . ",AA(B")
     ("ha16b" . ",A@(B")
     ("ha16d" . ",AI(B")
     ("ha16e" . ",AS(B")
     ("ha16f" . ",AR(B")
     ("ha171" . ",A}(B")
     ("ha172" . "y`")
     ("ha176" . ",AM(B")
     ("ha235" . "/")
     ("za430" . "[C]")
     ("za431" . "[U]")
     ("za432" . "[S]")
     ("za433" . "[D]")
     ("za43a" . "$B!](B"))))

(defconst genius-structure-regexp
  (concat "^\\($B!]!Z(B.*$B![(B\\)\\|"			; level 2
	  "^\\($B!]!C(B.*$B!C(B\\)\\|"			; level 3
	  "^\\([0-9]+\\)\\(\\)\\|"		; level 4
	  "^\\(\\*.*\n\\)"))			; level 6

(defun genius-arrange-structure (entry)
  ;; break examples into lines
  (save-restriction
    (while (search-forward "$B!B(B" nil t)
      (delete-region (match-beginning 0) (match-end 0))
      (insert "\n*")
      (narrow-to-region (point) (progn (end-of-line) (point)))
      (goto-char (point-min))
      (while (search-forward "/" nil t)
	(delete-region (match-beginning 0) (match-end 0))
	(insert "\n*"))
      (widen)))
  ;; level 1
  (goto-char (point-min))
  (when (re-search-forward "\\`\\([^*/]+\\)\\(\\**\\)?/[^/]+/" nil t)
    (newline)
    (let ((mb2 (match-beginning 2)) (me2 (match-end 2)))
      (lookup-make-region-heading (point-min) (match-end 1) 1)
      (when (< mb2 me2)
	(let ((num (length (buffer-substring mb2 me2))))
	  (delete-region mb2 me2)
	  (goto-char (point-min))
	  (insert "(")
	  (insert-char ?+ num)
	  (insert ")")))))
  ;; level 2-6
  (let ((case-fold-search nil) n)
    (while (re-search-forward genius-structure-regexp nil t)
      (setq n 1)
      (while (<= n 6)
	(if (match-beginning n)
	    (lookup-make-region-heading
	     (match-beginning n) (match-end n) (1+ n)))
	(setq n (1+ n))))))

(setq lookup-support-options
      (list :gaiji-table genius-gaiji-table
	    :arrange-table '((structure . genius-arrange-structure))
	    :transformer 'lookup-stemming-search))

;;; genius.el ends here
