;;; chujiten.el --- support file for $B!X?71QOB!&OB1QCf<-E5!Y(B
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

(defconst chujiten-gaiji-table
  (lookup-new-gaiji-table
   '(("ha121" . "(+)")
     ("ha122" . "(++)")
     ("ha123" . "(+++)")
     ("ha124" . "(*)")
     ;; ("ha125")
     ("ha126" . "$B!Z(B")
     ("ha127" . "$B![(B")
     ("ha128" . "$B!N(B")
     ("ha129" . "$B!O(B")
     ("ha12a" nil "~")
     ("ha12b" . "-")
     ("ha12c" . "-'")
     ("ha12d" . "-`")
     ;; ("ha12e") - ("ha133")
     ("ha134" . ",Ag(B")
     ("ha135" . ",0'(B'")
     ("ha136" . ",0:(B'")
     ("ha137" . ",0!(B'")
     ("ha138" . ",07(B'")
     ("ha139" . ",05(B'")
     ("ha13a" . ",0,(B'")
     ("ha13b" . "'")
     ("ha13c" . "E'")
     ("ha13d" . ",Aa(B")
     ("ha13e" . ",Ai(B")
     ("ha13f" . ",Am(B")
     ("ha140" . ",As(B")
     ("ha141" . ",Az(B")
     ("ha142" . ",0+(B'")
     ("ha143" . ",0'(B`")
     ("ha144" . ",0:(B`")
     ("ha145" . ",0!(B`")
     ("ha146" . ",07(B`")
     ("ha147" . ",05(B`")
     ("ha148" . ",0,(B`")
     ("ha149" . "`")
     ("ha14a" . ",A`(B")
     ("ha14b" . ",Ah(B")
     ("ha14c" . ",Al(B")
     ("ha14d" . ",Ar(B")
     ("ha14e" . ",Ay(B")
     ("ha14f" . ",0+(B`")
     ("ha150" . ",0+(B")
     ("ha151" . "A'")
     ("ha152" . "B'")
     ("ha153" . "C'")
     ("ha154" . "D'")
     ("ha155" . "E'")
     ("ha156" . "F'")
     ("ha157" . "G'")
     ("ha158" . "H'")
     ("ha159" . "I'")
     ("ha15a" . "L'")
     ("ha15b" . "M'")
     ("ha15c" . "O'")
     ("ha15d" . "P'")
     ("ha15e" . "Q'")
     ("ha15f" . "R'")
     ("ha160" . "S'")
     ("ha161" . "T'")
     ("ha162" . "U'")
     ("ha163" . "V'")
     ("ha164" . "X'")
     ("ha165" . "Y'")
     ("ha166" . "Z'")
     ("ha167" ",Aa(B" "a")
     ("ha168" ",Ai(B" "e")
     ("ha169" ",Am(B" "i")
     ("ha16a" ",As(B" "o")
     ("ha16b" ",Az(B" "u")
     ("ha16c" ",A}(B" "y")
     ("ha16d" . "A`")
     ("ha16e" . "E`")
     ("ha16f" . "I`")
     ("ha170" . "O`")
     ("ha171" . ",0$(B'")
     ("ha172" . "")
     ("ha173" . ",0$(B`")
     ("ha174" . "")
     ("ha175" . ",0$(B")
     ("ha176" . "")
     ("ha177" . "S`")
     ("ha178" . "T`")
     ("ha179" . "U`")
     ("ha17a" . "V`")
     ("ha17b" ",A`(B" "a")
     ("ha17c" ",Ah(B" "e")
     ("ha17d" ",Al(B" "i")
     ("ha17e" ",Ar(B" "o")
     ("ha221" ",Ay(B" "u")
     ("ha222" "y`" "y")
     ("ha223" . ",0;(B")
     ("ha224" . ",0>(B")
     ("ha225" . ",0<(B")
     ("ha226" . ",0'(B")
     ("ha227" . ",0:(B")
     ("ha228" . ",0!(B")
     ("ha229" . ",07(B")
     ("ha22a" . ",05(B")
     ("ha22b" . ",0H(B")
     ("ha22c" . ",0I(B")
     ("ha22d" . ",0L(B")
     ("ha22e" . ",0M(B")
     ("ha22f" . ",0U(B")
     ;; ("ha22f")
     ;; ("ha230")
     ;; ("ha231")
     ;; ("ha232")
     ("ha233" . ",0r(B")
     ("ha234" . ",0,(B")
     ("ha235" . ",B3(B")
     ("ha236" . "~")
     ("ha237" . ",Ac(B")
     ("ha238" . ",Aq(B")
     ("ha239" . ",Ax(B")
     ("ha23a" . ",AE(B")
     ("ha23b" . ",B~(B")
     ("ha23c" . ",A0(B")
     ("ha23d" . ",A((B")
     ("ha23e" . ",AV(B")
     ("ha23f" . ",Ad(B")
     ("ha240" . ",Ak(B")
     ("ha241" . ",Ao(B")
     ("ha242" . ",Av(B")
     ("ha243" . ",A|(B")
     ("ha244" . "^")
     ("ha245" . ",Ab(B")
     ("ha246" . ",Aj(B")
     ("ha247" . ",An(B")
     ("ha248" . ",At(B")
     ("ha249" . "-")
     ("ha24a" . ",D`(B")
     ("ha24b" . ",D:(B")
     ("ha24c" . ",Do(B")
     ("ha24d" . ",Dr(B")
     ("ha24e" . ",D~(B")
     ("ha24f" . "y-")
     ("ha250" . ",Bc(B")
     ;; ("ha251" . "e~")
     ;; ("ha252" . "o~")
     ("ha253" . ",BH(B")
     ;; ("ha253" . "a~")
     ("ha255" . ",Bh(B")
     ;; ("ha256" . "e~")
     ("ha257" . ",B5(B")
     ("ha258" . ",Bx(B")
     ("ha259" . ",B9(B")
     ;; Any gaiji of the code "haxxx" after this doesn't seem to
     ;; appear except "ha26b", so we don't define them.
     ("ha26b" . "*")
     ("za321" . "[$BL>(B]")
     ("za322" . "[$BBe(B]")
     ("za323" . "[$B7A(B]")
     ("za324" . "[$BF0(B]")
     ("za325" . "[$BI{(B]")
     ("za326" . "[$B@\(B]")
     ("za327" . "[$BA0(B]")
     ("za328" . "[$B4'(B]")
     ("za329" . "[$B4V(B]")
     ("za32a" . "[$B=u(B")
     ("za32b" . "$BF0(B]")
     ("za32c" . "[$B@\(B")
     ("za32d" . "$BF,(B]")
     ("za32e" . "$BHx(B]")
     ("za32f" . "[U]")
     ("za330" . "[C]")
     ("za331" . "($BC1(B)")
     ("za332" . "($BJ#(B)")
     ("za333" . "[A]")
     ("za334" . "[P]")
     ("za335" . "($B<+(B)")
     ("za336" . "($BB>(B)")
     ("za337" . "[$B@.(B")
     ("za338" . "$B6g(B]")
     ("za339" . "[$B2;(B]")
     ("za33a" . "[$BNc(B]")
     ("za33b" . "[$B%a%b(B]")
     ("za33c" . "[$B0lMw(B]")
     ("za33f" . "$B"*(B")
     ("za34e" . "$B!](B")
     ("za34f" . "$B"N(B")
     ("za722" . "$B"M(B"))))

;; reference pattern

(defconst chujiten-base-reference-regexp
  (cond ((eq lookup-support-agent 'ndtp)
	 "$B"*(B<\\([0-9a-f:]+\\)>")
	((eq lookup-support-agent 'ndeb)
	 "<reference>$B"*(B</reference=\\([0-9a-f:]+\\)>")))

(defconst chujiten-eiwa-reference-pattern
  (list (concat chujiten-base-reference-regexp "\\([a-zA-Z' ]*[$B#0(B-$B#9(B]*\\>\\)?")
	'(concat "$B"*(B" (match-string 2)) 2 1))

(defconst chujiten-waei-reference-pattern
  (list (concat chujiten-base-reference-regexp "\\([^ ,.\n]*\\)?")
	'(concat "$B"*(B" (match-string 2)) 2 1))

(defun chujiten-reference-pattern (entry)
  (cond
   ((chujiten-eiwa-entry-p entry) chujiten-eiwa-reference-pattern)
   ((chujiten-waei-entry-p entry) chujiten-waei-reference-pattern)
   (t (lookup-dictionary-ref (lookup-entry-dictionary entry)
			     ':reference-pattern))))

;; arrange table

(defconst chujiten-arrange-table
  '((structure . chujiten-arrange-structure)))

; (defconst chujiten-example-regexp
;   (cond ((eq lookup-support-agent 'ndtp)
; 	 "$B"*(B<gaiji:za33a><\\([0-9a-f:]+\\)>")
; 	((eq lookup-support-agent 'ndeb)
; 	 "<reference>$B"*(B<gaiji=za33a></reference=\\([0-9a-f:]+\\)>")))

; (defun chujiten-arrange-expand-examples (entry)
;   (setq entry (lookup-new-entry (lookup-entry-dictionary entry) nil ""))
;   (while (re-search-forward chujiten-example-regexp nil t)
;     (lookup-entry-set-code entry (match-string 1))
;     (delete-region (match-beginning 0) (match-end 0))
;     (forward-line)
;     (narrow-to-region (point) (progn (insert (lookup-dictionary-command
; 					      dictionary 'content entry))
; 				     (point)))
;     (goto-char (point-min))
;     (while (not (eobp)) (insert "*") (forward-line))
;     (widen)))

(defconst chujiten-eiwa-structure-regexp
  (concat "^\\($B!](B\\[[^]\n]+\\]\\)\\|"		; level 2
	  "^\\([A-Z]\\>\\)\\|"			; level 3
	  "^\\([0-9]+\\)?\\([a-z]\\)?\\>\\|"	; level 4, 5
	  "^\\(\\*.*\n\\)"))			; level 6

(defun chujiten-eiwa-arrange-structure (entry)
  ;; $B8+=P$78l$r(B level 1
  (when (looking-at "\\(([+*]+)\\)?\\([^/\n]*\\) *\\(/[^/\n]+/\\)?")
    (lookup-make-region-heading (match-beginning 2) (match-end 2) 1))
  (forward-line)
  ;; level 2-6
  (let ((case-fold-search nil) n)
    (while (re-search-forward chujiten-eiwa-structure-regexp nil t)
      (setq n 1)
      (while (<= n 6)
	(if (match-beginning n)
	    (lookup-make-region-heading
	     (match-beginning n) (match-end n) (1+ n)))
	(setq n (1+ n))))))

(defun chujiten-waei-arrange-structure (entry)
  (lookup-make-region-heading (point) (progn (end-of-line) (point)) 1)
  (forward-line)
  (while (re-search-forward "^\\([0-9]+\\)\\|^\\(\\($B!ZJ8Nc![(B\\)?\\*.*\n\\)" nil t)
    (if (match-beginning 1)
	(lookup-make-region-heading (match-beginning 1) (match-end 0) 4)
      (lookup-make-region-heading (match-beginning 2) (match-end 2) 6))))

(defun chujiten-arrange-structure (entry)
  (cond
   ((chujiten-eiwa-entry-p entry) (chujiten-eiwa-arrange-structure entry))
   ((chujiten-waei-entry-p entry) (chujiten-waei-arrange-structure entry))
   (t (lookup-arrange-structure entry))))

;; internal functions

(defun chujiten-eiwa-entry-p (entry)
  (let ((code (lookup-entry-code entry)))
    (and (string< "17a2" code) (string< code "6e8d"))))

(defun chujiten-waei-entry-p (entry)
  (let ((code (lookup-entry-code entry)))
    (and (string< "6e8d" code) (string< code "a773"))))

(defun chujiten-menu-entry-p (entry)
  (let ((code (lookup-entry-code entry)))
    (or (string< code "17a2") (string< "a773" code))))

;; support options

(setq lookup-support-options
      (list ':gaiji-table chujiten-gaiji-table
	    ':reference-pattern 'chujiten-reference-pattern
	    ':arrange-table chujiten-arrange-table
	    ':transformer 'lookup-stemming-search))

;;; chujiten.el ends here
