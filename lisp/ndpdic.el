;;; ndpdic.el --- Lookup `PDIC' interface  -*- coding: utf-8 -*-
;; Copyright (C) 2009 Lookup Development Team

;; Author: KAWABATA Taichi <kawabata.taichi@gmail.com>
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

;;; Documentation:

;; This is agent program for `PDIC' format.

;;; Usage: Put the XXX.dic files into a folder and specify that folder for ndpdic agent.
;; 
;; (setq lookup-search-agents
;;       '(
;;         ....
;;        (ndpdic "~/edicts/eijiro")
;;         ....
;;         ))
;;
;; If dictionary option `:index' is specified via support file, then it 
;; will be possible to search the dictionary by regular expression.
;;
;; There is a small sample function to create `index' file for PDIC.
;; To make an index, type M-x ndpdic-create-index-file.
;; (You need at least 1G memory, it would take 10 minutes for 2GHz machine 
;; for huge file such as Eijiro.)

;;;
;;; Customizable Variables
;;;

(defvar ndpdic-max-hits 150)

(defvar ndpdic-grep-program "grep")

(defvar ndpdic-grep-options (list (format "--max-count=%d" ndpdic-max-hits) "-e"))

(defvar ndpdic-extended-attributes
  '((0 . (lambda (x) (concat (ndpdic-bocu-to-str x) "\n")))
    (1 . (lambda (x) (concat "【用例】" (ndpdic-bocu-to-str x) "\n")))
    (2 . (lambda (x) (concat "【発音】" (ndpdic-bocu-to-str x) "\n")))))

;;;
;;; Interface Functions
;;;

(defvar ndpdic-extension-regexp "\\.dic\\'")

(defun ndpdic-dictionary-index (dictionary)
  "Return optional index file for DICTIONARY if exists."
  (let* ((location
          (lookup-agent-location
           (lookup-dictionary-agent dictionary)))
         (index
          (lookup-dictionary-option dictionary :index))
         (index
          (if index
              (expand-file-name index location))))
    (if (and index (file-exists-p index)) index)))

(put 'ndpdic :methods 'ndpdic-dictionary-methods)
(defun ndpdic-dictionary-methods (dictionary)
  "Return methods of DICTIONARY."
  (let ((index (ndpdic-dictionary-index dictionary)))
    (if index '(exact prefix suffix substring wildcard regexp)
      '(exact prefix))))

(put 'ndpdic :list 'ndpdic-list)
(defun ndpdic-list (agent)
  "Return a list of dictionary of AGENT."
  (let ((dir (lookup-agent-location agent)))
    (if (file-directory-p dir)
        (let ((files (directory-files (expand-file-name dir)
                                      nil ndpdic-extension-regexp))
              dicts)
          (dolist (file files)
            (if (> #x500 (ndpdic-file-version (expand-file-name file dir)))
                (message 
                 "Version of PDIC `%s' file is old and not supported!" file)
              (setq dicts
                    (cons (lookup-new-dictionary agent file) dicts))))
          (nreverse dicts))
      (message "ndpdic: directory %s is not found." dir)
      nil)))

(put 'ndpdic :title 'ndpdic-title)
(defun ndpdic-title (dictionary)
  "Return title of DICTIONARY."
  (replace-regexp-in-string
   "^.*/\\([^/]+\\)$" "\\1"
   (lookup-dictionary-name dictionary)))

(put 'ndpdic :search 'ndpdic-dictionary-search)
(defun ndpdic-dictionary-search (dictionary query)
  "Return entries for DICTIONARY QUERY."
  (let ((index (ndpdic-dictionary-index dictionary))
        (query-method (lookup-query-method query))
        query-regexp dir file block-index entries)
    (if (or (null index)
            (equal query-method 'exact)
            (equal query-method 'prefix))
        ;; normal PDIC search
        (ndpdic-dictionary-search-normal dictionary query)
      ;; regular expression search
      (setq query-regexp (replace-regexp-in-string "$\\'" "	"
                          (lookup-query-to-regexp query))
            dir          (lookup-agent-location
                          (lookup-dictionary-agent dictionary))
            file         (expand-file-name
                          (lookup-dictionary-name dictionary) dir)
            block-index  (ndpdic-block-index file))
      (with-temp-buffer
        (lookup-with-coding-system 'utf-8
          (apply 'call-process
                 ndpdic-grep-program nil t nil
                 (append ndpdic-grep-options
                         (list query-regexp index))))
        (goto-char (point-min))
        (while (re-search-forward
                "^\\(.+?	\\)\\([-]+\\)\\|\\([0-9A-F]+\\)" nil t)
          (let* ((word (match-string 1))
                 (hex1 (match-string 2))
                 (hex2 (match-string 3))
                 (hex (if hex1 (+ (* (- (elt hex1 0) 16) 65536)
                                  (* (- (elt hex1 1) 16) 4096)
                                  (* (- (elt hex1 2) 16) 256)
                                  (* (- (elt hex1 3) 16) 16)
                                  (- (elt hex1 4) 16))
                        (string-to-number hex2 16)))
                 (headers (ndpdic-entries file (elt block-index hex)))
                 (header (find-if (lambda (x) (string-match word x)) headers)))
            (if header
                (setq entries (cons
                               (lookup-new-entry
                                'regular dictionary header
                                (if (string-match "	" header)
                                    (substring header (match-end 0))))
                               entries))))))
      (nreverse entries))))

(defun ndpdic-dictionary-search-normal (dictionary query)
  "Return list of entries for DICTIONARY QUERY."
  (let* ((query-method (lookup-query-method query))
         (query-string
          (concat (lookup-query-string query)
                  (if (eq query-method 'exact) "\\(	\\|$\\)")))
         (dir (lookup-agent-location 
               (lookup-dictionary-agent dictionary)))
         (file (expand-file-name (lookup-dictionary-name dictionary) dir))
         (result
          (ndpdic-binary-search file query-string)))
    (when result
      (setq result
            (remove-if
             (lambda (x) (null (string-match
                                (concat "^" query-string) x)))
             (append (ndpdic-entries file (car result))
                     (ndpdic-entries file (cdr result)))))
      ;;(if (> (length result) ndpdic-max-hits)
      ;;    )
      (mapcar (lambda (x) (lookup-new-entry
                           'regular dictionary x
                           (if (string-match "	" x)
                               (substring x (match-end 0)))))
              result))))

(put 'ndpdic :content 'ndpdic-content)
(defun ndpdic-content (entry)
  "Content of ENTRY."
  (let* ((code (lookup-entry-code entry))
         (dictionary (lookup-entry-dictionary entry))
         (dir (lookup-agent-location
               (lookup-dictionary-agent dictionary)))
         (file (expand-file-name (lookup-dictionary-name dictionary) dir))
         (result (car (ndpdic-binary-search file code))))
    (ndpdic-entry-content file result code)))

;; Hash variables 
;; (in future, move them to lookup hash tables)

(defvar ndpdic-block-index-hash
  (make-hash-table :test 'equal)
  "Hash table for file -> block-index table.")

(defvar ndpdic-block-entries-hash
  (make-hash-table :test 'equal)
  "Hash table for file -> (block -> entries) table.")

;;;
;;; BOCU Decoder
;;;

(defun bocu-read-decode-trail-char (reg)
  "BOCU trail char in REG to be decoded."
  `(read-if (,reg > #x20) (,reg -= 13) 
     (if (,reg >= #x1c) (,reg -= 12)   
       (if (,reg >= #x10) (,reg -= 10) 
         (,reg -= 1)))))               

(define-ccl-program decode-bocu
  `(4
    ((r4 = #x40)
     (r3 = ,(charset-id-internal 'unicode))
     (loop
      (read r0)
      ;; Diff calculation phase
      (if (r0 <= #x20) (r1 = r0)
        (if (r0 == #x21)
            ((r1 = -14536567)
             ,(bocu-read-decode-trail-char 'r2)
             (r1 += (r2 * 59049))
             ,(bocu-read-decode-trail-char 'r2)
             (r1 += (r2 * 243))
             ,(bocu-read-decode-trail-char 'r2)
             (r1 += r2))
          (if (r0 < #x25)
              ((r1 = (((r0 - #x25) * 59049) - 10513))
               ,(bocu-read-decode-trail-char 'r2)
               (r1 += (r2 * 243))
               ,(bocu-read-decode-trail-char 'r2)
               (r1 += r2))
            (if (r0 < #x50)
                ((r1 = (((r0 - #x50) * 243) - 64))
                 ,(bocu-read-decode-trail-char 'r2)
                 (r1 += r2))
              (if (r0 < #xd0)
                  (r1 = (r0 - #x90))
                (if (r0 < #xfb)
                    ((r1 = (((r0 - #xd0) * 243) + 64))
                     ,(bocu-read-decode-trail-char 'r2)
                     (r1 += r2))
                  (if (r0 < #xfe)
                      ((r1 = (((r0 - #xfb) * 59049) + 10513))
                       ,(bocu-read-decode-trail-char 'r2)
                       (r1 += (r2 * 243))
                       ,(bocu-read-decode-trail-char 'r2)
                       (r1 += r2))
                    (if (r0 == #xfe)
                        ((r1 = 187660)
                         ,(bocu-read-decode-trail-char 'r2)
                         (r1 += (r2 * 59049))
                         ,(bocu-read-decode-trail-char 'r2)
                         (r1 += (r2 * 243))
                         ,(bocu-read-decode-trail-char 'r2)
                         (r1 += r2)
                         ;; ignore case: `r0 = #xff'
                         )))))))))
      ;; output stage
      (if (r0 <= #x20) 
          ((if (r0 != 13) (write r0))
           (if (r0 < #x20) (r4 = #x40)))
        (if (r0 < #xff)
            ((r1 += r4)
             (if (r1 < 0) (r1 = 0)) ; error recovery
             (write-multibyte-character r3 r1)
             ;; cp renewal stage
             (if (r1 < #x20) (r4 = #x40) ; reset
               (if (r1 == #x20) (r4 = r4) ; space → keep
                 ((r5 = (r1 >= #x3040))
                  (r6 = (r1 <= #x309f))
                  (if (r5 & r6) (r4 = #x3070)
                    ((r5 = (r1 >= #x4e00))
                     (r6 = (r1 <= #x9fa5))
                     (if (r5 & r6) (r4 = #x7711)
                       ((r5 = (r1 >= #xac00))
                        (r6 = (r1 <= #xd7a3))
                        (if (r5 & r6) (r4 = #xc1d1)
                          ((r5 = (r1 & #xff))
                           ;; As of 2009/8/27, #xffffff00 is treated as float.
                           ;;(r6 = (r1 & #xffffff00)) ;; FIXME
                           (r6 = (r1 & -256))
                           (if (r5 < #x80) (r4 = (r6 + #x40))
                             (r4 = (r6 + #xc0)))))))))))))))
      (repeat)))))

(defun ndpdic-bocu-to-str (string)
  "Decode BOCU STRING to Emacs String."
  (ccl-execute-on-string 'decode-bocu '[0 0 0 0 0 0 0 0 0] string))

;;;
;;; Basic Functions
;;;

(defun ndpdic-file-content (file from to)
  "Unibyte string of FILE from FROM to TO."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file nil from to)
    (buffer-string)))

(defun ndpdic-file-byte (file point)
  "Short value of FILE at POINT."
  (string-to-char (ndpdic-file-content file point (1+ point))))

(defun ndpdic-buffer-byte ()
  "Byte value of current buffer point."
  (let ((int (char-after (point))))
    (forward-char)
    int))

(defun ndpdic-string-to-short (str)
  "Convert STR to short value."
  (let ((chs (string-to-list str)))
    (+ (* (elt chs 1) 256) (elt chs 0))))

(defun ndpdic-file-short (file point)
  "Short value of FILE at POINT."
  (ndpdic-string-to-short (ndpdic-file-content file point (+ 2 point))))

(defun ndpdic-buffer-short ()
  "Int value of current buffer point."
  (let ((int (ndpdic-string-to-short (buffer-substring (point) (+ 2 (point))))))
    (goto-char (+ 2 (point)))
    int))

(defun ndpdic-string-to-int (str)
  "Convert STR to int value."
  (let ((factor 16777216) (result 0))
    (dolist (ch (nreverse (string-to-list str)))
      (setq result (+ result (* ch factor))
            factor (/ factor 256)))
    result))

(defun ndpdic-file-int (file point)
  "Int value of FILE at POINT."
  (ndpdic-string-to-int (ndpdic-file-content file point (+ 4 point))))

(defun ndpdic-buffer-int ()
  "Int value of current buffer point."
  (let ((int (ndpdic-string-to-int (buffer-substring (point) (+ 4 (point))))))
    (goto-char (+ 4 (point)))
    int))

(defun ndpdic-file-version (file)
  "Header lowrd value for FILE."
  (ndpdic-file-short file 140))

(defun ndpdic-file-lword (file)
  "Header lowrd value for FILE."
  (ndpdic-file-short file 142))

(defun ndpdic-file-ljapa (file)
  "Header lowrd value for FILE."
  (ndpdic-file-short file 144))

(defun ndpdic-file-block-size (file)
  "Header block_size value for FILE."
  (ndpdic-file-short file 146))

(defun ndpdic-file-index-block (file)
  "Header index_block value for FILE."
  (ndpdic-file-short file 148))

(defun ndpdic-file-header-size (file)
  "Header header_size value for FILE."
  (ndpdic-file-short file 150))

(defun ndpdic-file-nword (file)
  "Header nword value for FILE."
  (ndpdic-file-int file 160))

(defun ndpdic-file-dicorder (file)
  "Header dicorder value for FILE."
  (ndpdic-file-byte file 164))

(defun ndpdic-file-dictype (file)
  "Header dictype value for FILE."
  (ndpdic-file-byte file 165))

(defun ndpdic-file-os (file)
  "Header os value for FILE."
  (ndpdic-file-byte file 167))

(defun ndpdic-file-index-blkbit (file)
  "Header index-blkbit value for FILE."
  (ndpdic-file-byte file 182))

(defun ndpdic-file-extheader (file)
  "Header extheader value for FILE."
  (ndpdic-file-int file 184))

(defun ndpdic-file-empty-block (file)
  "Header empty_block value for FILE."
  (ndpdic-file-int file 188))

(defun ndpdic-file-nindex2 (file)
  "Header nindex2 value for FILE."
  (ndpdic-file-int file 192))

(defun ndpdic-file-nblock2 (file)
  "Header nblock2 value for FILE."
  (ndpdic-file-int file 196))

(defun ndpdic-file-crypt (file)
  "Header extheader value for FILE."
  (ndpdic-file-content file 200 208))

(defun ndpdic-file-index-start (file)
  "Index start point of FILE."
  (+ (ndpdic-file-header-size file)
     (ndpdic-file-extheader file)))

(defun ndpdic-file-data-start (file &optional block)
  "Data start point in FILE of BLOCK number."
  (unless block (setq block 0))
  (+ (ndpdic-file-index-start file) ; 1024
     (* (ndpdic-file-block-size file) ; 1024
        (+ (ndpdic-file-index-block file) block))))

(defun ndpdic-proceed-to-null ()
  "Proceed to next point of null character or eobp.
`char-before' a new point should be null character."
  (interactive)
  (if (not (eobp)) (forward-char))
  (while (not (or (eobp) (eq (char-before (point)) 0)))
    (forward-char)))

(defun ndpdic-block-index (file)
  "Construct Block Index of FILE.  Result will be cached."
  (or
   (gethash (expand-file-name file) ndpdic-block-index-hash)
   (let* ((blocks (make-vector (ndpdic-file-nindex2 file) nil))
          (blkbit (ndpdic-file-index-blkbit file))
          (i 0))
     (with-temp-buffer
       (set-buffer-multibyte nil)
       (insert-file-contents-literally
        file nil (ndpdic-file-index-start file)
        (ndpdic-file-data-start file))
       (goto-char (point-min))
       (while (not (eobp))
         (when (< i (length blocks))
           (aset blocks i
                 (if (= blkbit 0) (ndpdic-buffer-short)
                   (ndpdic-buffer-int)))
           (setq i (1+ i)))
         (if (= (char-after (point)) 0) (goto-char (point-max))
           (ndpdic-proceed-to-null))))
     (puthash (expand-file-name file) blocks ndpdic-block-index-hash)
     blocks)))

(defun ndpdic-insert-block-contents (file block)
  "Insert content of FILE's BLOCK to current buffer.
Return a size of `Field-Length' of the block."
  (let* ((start (ndpdic-file-data-start file block))
         (block-size (ndpdic-file-block-size file))
         (block-num (ndpdic-file-short file start))
         (fl-size (if (eq (logand block-num #x8000) 0) 2 4))
         (block-num (logand block-num #x7fff)))
    (insert-file-contents-literally file nil start
                                    (+ start (* block-num block-size)))
    fl-size))

(defun ndpdic-entries-next-word (prev-word-data &optional field-size-length)
  "Scan the current buffer and return the new word and misc.
Format is a list of (WORD KIND CONTENT-START-POINT WORD-DATA).
It assumes that current point is at beginning of new entry.  If
there is no more entries available in this block, then nil is
returned.  PREV-WORD-DATA will be used for decompressing new word.
Default FIELD-SIZE-LENGTH value would be 2.  If there is a word,
then it proceeds to next point."
  (if (null field-size-length) (setq field-size-length 2))
  (let ((field-size (if (eq field-size-length 2)
                        (ndpdic-buffer-short)
                      (ndpdic-buffer-int)))
        compress kind start
        content-start word-data)
    (when (/= 0 field-size)
      (setq compress (ndpdic-buffer-byte))
      (setq kind (ndpdic-buffer-byte))
      (setq start (point))
      (ndpdic-proceed-to-null)
      (setq word-data (buffer-substring start (1- (point))))
      (setq word-data (concat (substring prev-word-data 0 compress) word-data))
      (setq content-start (point))
      (goto-char (+ start field-size))
      (list (ndpdic-bocu-to-str word-data)
            kind content-start word-data))))

(defun ndpdic-entries (file block)
  "Get all entries in FILE at BLOCK.
Return the list of entry words.  Result will be cached."
  (let ((block-entries-hash (gethash (expand-file-name file) ndpdic-block-entries-hash))
        fl-size word-spec (word-data "") words)
    (when (null block-entries-hash)
      (setq block-entries-hash (make-hash-table))
      (puthash (expand-file-name file) block-entries-hash ndpdic-block-entries-hash))
    (or
     (gethash block block-entries-hash)
     (with-temp-buffer
       (set-buffer-multibyte nil)
       (setq fl-size (ndpdic-insert-block-contents file block))
       (goto-char (+ 2 (point-min)))
       (while (not (eobp))
         (setq word-spec (ndpdic-entries-next-word word-data fl-size))
         (if (null word-spec) (goto-char (point-max))
           (setq words (cons (car word-spec) words))
           (setq word-data (elt word-spec 3))))
       (puthash block (nreverse words) block-entries-hash)))))

(defun ndpdic-entry-content (file block entry)
  "Get content of FILE, BLOCK, and  ENTRY."
  (let* (fl-size word word-spec (word-data "") content)
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (setq fl-size (ndpdic-insert-block-contents file block))
      (goto-char (+ 2 (point-min)))
      (while (not (eobp))
        (setq word-spec (ndpdic-entries-next-word word-data fl-size))
        (setq word (car word-spec))
        (setq word-data (elt word-spec 3))
        (if (null word-spec) (goto-char (point-max))
          (when (equal entry (car word-spec))
            (setq content
                  (ndpdic-adjust-content
                   entry (elt word-spec 1)
                   (elt word-spec 2) (point)))
            (goto-char (point-max)))))
      content)))

(defun ndpdic-adjust-content (entry kind from to &optional field-size-length)
  "Retrieve ENTRY contents of KIND from FROM to TO buffer.
Optional argument FIELD-SIZE-LENGTH specifies size of binary data length field."
  (let ((word-level (logand #x0f kind))
        (extended   (logand #x10 kind))
        (memorize   (logand #x20 kind))
        (modified   (logand #x40 kind))
        extended-data start ext-val data-item)
    ;; Parse Extended Data
    (when (/= extended 0)
      (save-restriction
        (unless field-size-length (setq field-size-length 2))
        (narrow-to-region from to)
        (goto-char (point-min))
        (ndpdic-proceed-to-null)
        (setq extended-data
              (list (cons 0 (buffer-substring from (1- (point))))))
        (while (not (eobp))
          (setq ext-val (ndpdic-buffer-byte))
          (setq start (point))
          (if (/= 0 (logand #x40 ext-val))
              ;; binary
              (let ((length (if (eq field-size-length 2)
                                (ndpdic-buffer-short)
                              (ndpdic-buffer-int))))
                (goto-char (+ start length))
                (setq data-item (buffer-substring start (point))))
            ;; text
            (ndpdic-proceed-to-null)
            (setq data-item (buffer-substring start (1- (point)))))
          (setq extended-data (cons (cons ext-val data-item)
                                    extended-data)))
        (setq extended-data (nreverse extended-data))))
    ;; Contents for Display
    (concat
     ;; entry part
     (if (string-match "	" entry)
         (substring entry (match-end 0)) entry)
     "\n"
     (if (= extended 0)
         (ndpdic-bocu-to-str (buffer-substring from to))
       (mapconcat (lambda (x)
                    (if (assq (car x) ndpdic-extended-attributes)
                        (apply (cdr (assq (car x) ndpdic-extended-attributes))
                               (list (cdr x)))))
                  extended-data "")))))
  

;; binary search

(defun ndpdic-compare-entry (entry entries)
  "Judege if ENTRY is larger, smaller, or inclusive of ENTRIES.
Comparison is done lexicographicaly.
If larger, t. smaller, nil.  equal, 0 will be returned."
  (if (string-lessp entry (car entries)) nil
    (if (string-lessp (car (last entries)) entry) t 0)))

(defun ndpdic-binary-search (file entry)
  "Find block in FILE which includes ENTRY.
Return value would be (block . next-block)."
  (let* ((block-index (ndpdic-block-index file))
         (start 0) (end (length block-index))
         (middle (/ end 2))
         (entries (ndpdic-entries file (aref block-index middle)))
         result)
    (while
        (progn
          (setq result (ndpdic-compare-entry entry entries))
          (not (or (and (numberp result) (= 0 result))
                   (= start middle))))
      (if result (setq start middle)
        (setq end middle))
      (setq middle (/ (+ start end) 2))
      (setq entries (ndpdic-entries file (aref block-index middle))))
    (if (and (numberp result) (= 0 result))
        (cons (aref block-index middle)
              (if (/= (1- (length block-index)) middle)
                  (aref block-index (1+ middle))))
      nil)))
        
;; Utility Function

(defun ndpdic-create-index-file (file &optional eijiro)
  "Create index file from FILE.
PDIC辞書に対して、正規表現などで検索するためのインデックスファイルを生成する。
 各行は以下の構成となる。
 ［エントリ］<TAB>［16進数のブロック番号］
 英辞郎と同様のフォーマットにするならば、 EIJIRO を t にする。"
  (interactive "fPDIC File Name:")
  (let ((index-file (concat (file-name-sans-extension file) ".idx"))
        (block-index (ndpdic-block-index file))
        buffer block block-num (total (ndpdic-file-nindex2 file)))
    (if (or (file-exists-p index-file)
            (null (y-or-n-p (format "Index file %s will be created.  OK? " index-file))))
        (error "%s can't be created!" index-file)
      (with-temp-buffer
        (dotimes (i (length block-index))
          (setq block (aref block-index i))
          (if (= 0 (% i 100)) (message "%d %% done..." (/ (* 100 i) total)))
          (setq block-num (number-to-string i))
          (dolist (entry (ndpdic-entries file block))
            (if (string-match "	" entry)
                (insert (substring entry 0 (match-beginning 0)) "\t"
                        (format "%05x" block-num))
              (insert entry "\t" (format "%05x" block-num)))))
        (when eijiro
          (goto-char (point-min))
          (while (re-search-forward "	\\([0-9A-F]\\{5\\}\\)" nil t)
            (replace-match
             (save-match-data
               (apply 'string
                      (mapcar
                       (lambda (x) (+ 16 (string-to-number x 16)))
                       (split-string (match-string 1) "" t))))
             t nil nil 1)))
        (write-region (point-min) (point-max) (expand-file-name index-file))))))

(provide 'ndpdic)

;;; ndpdic.el ends here
