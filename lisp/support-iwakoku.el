;;; iwakoku.el --- support file for $B!X4dGH9q8l<-E5!Y(B
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

(defconst iwakoku-gaiji-table
  (lookup-new-gaiji-table
   '(("za321" "[$BL>(B]") ("za322" "[$BBe(B]") ("za323" "[$B7A(B]") ("za324" "[$BF0(B]")
     ("za325" "[$BI{(B]") ("za326" "[$B@\(B]") ("za327" "[$BA0(B]") ("za328" "[$B4'(B]")
     ("za329" "[$B4V(B]") ("za32a" "[$B=u(B") ("za32b" "$BF0(B]") ("za32c" "[$B@\(B")
     ("za32d" "$BF,(B]") ("za32e" "$BHx(B]") ("za32f" "[U]") ("za330" "[C]")
     ("za331" "($BC1(B)") ("za332" "($BJ#(B)") ("za333" "[A]") ("za334" "[P]")
     ("za335" "($B<+(B)") ("za336" "($BB>(B)") ("za337" "[$B@.(B") ("za338" "$B6g(B]")
     ("za339" nil "[$B2;(B]") ("za33a" nil "[$BNc(B]") ("za33b" nil "[$B%a%b(B]")
     ("za33c" nil "[$B0lMw(B]") ("za37c" "(C)") ("za37d" "(R)") ("za722" "$B"M(B"))))

(defconst iwakoku-arrange-table
  '((structure . iwakoku-arrange-headings)))

(defun iwakoku-fix-by-black-list (entry)
  (let ((code (lookup-entry-code entry)))
    (cond
     ((string= code "212d:d8")
      (search-forward "$B$5(B\n$B$?(B") (replace-match "$B$5$?(B")))))

(defun iwakoku-arrange-headings (entry)
  (lookup-arrange-structure entry)
  (while (re-search-forward "\\(\\[.\\]\\)\\|\\(([0-9]+)\\)\\|([$B%"(B-$B%s(B]+)" nil t)
    (lookup-make-region-heading (match-beginning 0) (match-end 0)
				(if (match-beginning 1) 3
				  (if (match-beginning 2) 4 5)))
    (save-excursion
      (goto-char (match-beginning 0))
      (unless (or (bolp) (get-text-property (- (point) 2) 'lookup-heading))
	(newline)))))

(setq lookup-support-options
      (list ':gaiji-table iwakoku-gaiji-table
	    ':arrange-table iwakoku-arrange-table))

;;; iwakoku.el ends here
