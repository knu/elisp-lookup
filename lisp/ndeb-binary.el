;;; ndeb-binary.el --- binary data support for ndeb agent
;; Copyright (C) 1999-2002 Lookup Development Team <lookup@ring.gr.jp>

;; Author: Satomi I. <satomi@ring.gr.jp>
;; Version: $Id$

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

;;(require 'cl)
;;(load "cl-seq")

;;;
;;; Customizable variables
;;;

(defgroup ndeb-binary nil
  "Binary data support for ndeb agent."
  :group 'ndeb)

(defcustom ndeb-binary-programs
  (cond
   ((featurep 'meadow)
    `(,(if (functionp 'mw32-mci-send-string)
	   '(wave ndeb-binary-play-with-mci)
	 '(wave ("fiber" "-s")))
      (mpeg ("fiber" "-s"))
      (bmp ("fiber" "-s"))
      (xbm ("fiber" "-s"))
      (jpeg ("fiber" "-s"))))
   ((functionp 'play-sound-file)
    '((wave ndeb-binary-play-sound-file)))
   (t nil))
"A list of programs to play binary data on an ndeb entry.
Each element is like a property list of the following form:

  (TYPE PROGRAM [KEY VALUE ...])

Where TYPE is a symbol that represents the binary type. At this time
`xbm', `bmp', `jpeg', `wave' and `mpeg' are recognized.

PROGRAM is eigher a program name or a list of command-line parametrs
or symbol of function to play a binary of this TYPE.

The rest, pairs of KEY and VALUE, are optional properties to control
how to invoke PROGRAM. Valid properties are:

  :directory-separator STRING
      Convert directory separators (/) in the binary filename to
      STRING when constructing the actual command line.

  :disable-sentinel BOOLEAN
      If non-nil, do not use the process sentinel to delete the
      temporary file used by PROGRAM."
  :type '(repeat
	  (list
	   (choice :tag "Type"
		   (const xbm)
		   (const bmp)
		   (const jpeg)
		   (const wave)
		   (const mpeg)
		   symbol)
	   (cons :format "%v"
		 (string :tag "Program")
		 (repeat :tag "Options" string))
	   (set :format "%v" :inline t
		(list :format "%v" :inline t
		      (const :format "" :inline t (:directory-separator))
		      (string :tag "Directory seperator" :value "/"))
		(list :format "%v" :inline t
		      (const :format "" :inline t (:disable-sentinel))
		      (boolean :tag "Disable process sentinel")))))
  :get (lambda (symbol)
	 (mapcar (lambda (elem)
		   (let ((program (nth 1 elem)))
		     (append (list (car elem)
				   (if (stringp program) (list program)
				     program))
			     (cdr (cdr elem)))))
		 (symbol-value symbol)))
  :group 'ndeb-binary)

(defcustom ndeb-binary-extensions
  '((xbm . "xbm")
    (bmp . "bmp")
    (jpeg . "jpg")
    (wave . "wav")
    (mpeg . "mpg"))
  "Alist of binary type vs. filename extension used to create a
temporary file. Each element looks like:

  (TYPE . EXTENSION)

Where TYPE is a symbol that represents the binary type.
EXTENSION is a filename extension without the leading dot."
  :type '(repeat (cons (symbol :tag "Type")
		       (choice :tag "Extension"
			       (const nil)
			       string)))
  :group 'ndeb-binary)

(defcustom ndeb-binary-bmp-display-type
  (or (unless (lookup-inline-image-p 'bmp)
	(or (and (lookup-inline-image-p 'ppm) 'ppm)
	    (and (lookup-inline-image-p 'tiff) 'tiff)))
      'bmp)
  "Image type to which bmp image is converted fot displaying."
  :type '(choice :tag "Type"
		 (const bmp)
		 (const ppm)
		 (const tiff)
		 symbol)
  :group 'ndeb-binary)

(defcustom ndeb-binary-temporary-directory temporary-file-directory
  "Path to the directory where temporary binary files will be created."
  :type 'directory
  :group 'ndeb-binary)

(defcustom ndeb-image-default-caption "$B2hA|(B"
  "Default string to be used when the caption of an image is empty."
  :type 'string
  :group 'ndeb-binary)

(defcustom ndeb-image-caption-format "$B!R(B%s$B!S(B"
  "Format string for the caption of an image.
This string is passed to `format' function with the original text."
  :type '(choice (const nil) string)
  :group 'ndeb-binary)

(defcustom ndeb-sound-default-caption "$B2;@<(B"
  "Default string to be used when the caption of a sound is empty."
  :type 'string
  :group 'ndeb-binary)

(defcustom ndeb-sound-caption-format "$B!T(B%s$B!U(B"
  "Format string for the caption of a sound.
This string is passed to `format' function with the original text."
  :type '(choice (const nil) string)
  :group 'ndeb-binary)

(defcustom ndeb-movie-default-caption "$BF02h(B"
  "Default string to be used when the caption of a movie is empty."
  :type 'string
  :group 'ndeb-binary)

(defcustom ndeb-movie-caption-format "$B!T(B%s$B!U(B"
  "Format string for the caption of a movie.
This string is passed to `format' function with the original text."
  :type '(choice (const nil) string)
  :group 'ndeb-binary)

(defcustom ndeb-play-sound-from-entry nil
"A string or a vector of symbols and characters meaning a
sequence of keystrokes and events for `lookup-entry-play-ndeb-sound'.
If nil no keystrokes are assigned."
  :type '(choice (const nil) (string :tag "Key"))
  :group 'ndeb-binary)

(defcustom ndeb-play-movie-from-entry nil
"A string or a vector of symbols and characters meaning a
sequence of keystrokes and events for `lookup-entry-play-ndeb-movie'.
If nil no keystrokes are assigned."
  :type '(choice (const nil) (string :tag "Key"))
  :group 'ndeb-binary)

(defcustom ndeb-play-binaries-from-entry nil
"A list of lists which consist of key and types to play binary links from lookup-entry mode."
:type '(repeat
	(list
	 (string :tag "Key")
	 (repeat :inline t :tag "Types"
		 (choice :tag "Type"
			 (const xbm)
			 (const bmp)
			 (const jpeg)
			 (const wave)
			 (const mpeg)
			 symbol))))
:group 'ndeb-binary)

(defface ndeb-image-caption-face
  '((((class color) (background light)) (:foreground "Gray50"))
    (((class color) (background dark)) (:foreground "Gray75")))
  "Face used to highlight the caption of an image."
  :group 'ndeb-binary
  :group 'lookup-faces)

(defface ndeb-image-mono-face
  '((t (:foreground "Black" :background "White")))
  "Face applied to the monochrome images."
  :group 'ndeb-binary
  :group 'lookup-faces)

(defface ndeb-sound-caption-face
  '((((class color) (background light)) (:foreground "Green4"))
    (((class color) (background dark)) (:foreground "GreenYellow")))
  "Face used to highlight the caption of a sound."
  :group 'ndeb-binary
  :group 'lookup-faces)

(defface ndeb-movie-caption-face
  '((((class color) (background light)) (:foreground "Green4"))
    (((class color) (background dark)) (:foreground "GreenYellow")))
  "Face used to highlight the caption of a movie."
  :group 'ndeb-binary
  :group 'lookup-faces)

;;;
;;; Internal variables
;;;

(defvar ndeb-binary-link-map nil
  "Keymap for binary links.")

(defvar ndeb-binary-image-page-map nil
  "Keymap for binary links.")

(defvar ndeb-binary-processes nil
  "A list of external processes started by executing a link.
Each element looks like: (PROCESS-ID DICTIONARY-ID ENTRY-POSITION)")

(put 'ndeb :xbm-regexp
     '("<img=mono:\\([0-9]+\\)x\\([0-9]+\\)>" . "</img=\\([^>]+\\)>"))
(put 'ndeb :bmp-regexp
     '("<\\(img\\|inline\\)=bmp>" . "</\\(img\\|inline\\)=\\([^>]+\\)>"))
(put 'ndeb :jpeg-regexp
     '("<\\(img\\|inline\\)=jpeg>" . "</\\(img\\|inline\\)=\\([^>]+\\)>"))
(put 'ndeb :wave-regexp
     '("<snd=wav:\\([0-9]+:[0-9]+\\)-\\([0-9]+:[0-9]+\\)>" . "</snd>"))
(put 'ndeb :mpeg-regexp
     '("<mov=mpg:\\([0-9]+\\),\\([0-9]+\\),\\([0-9]+\\),\\([0-9]+\\)>" . "</mov>"))

(defconst ndeb-binary-extract-commands
  ;; or should be set as dictionary options...??
  '((xbm . "xbm %s %s %s")
    (bmp . "bmp %s %%s")
    (ppm . "bmp2ppm %s %%s")
    (tiff . "bmp2tiff %s %%s")
    (jpeg . "jpeg %s %%s")
    (wave . "wav %s %%s")
    (mpeg . "mpeg %s %%s"))
  "Alist of binary type vs. format string of an eblook command to
extract the target entry.")

(defvar ndeb-binary-glyph-compose-function nil)
(defvar ndeb-binary-glyph-insert-function nil)

;;;
;;; Internal functions
;;;

(defvar ndeb-binary-temporary-subdirectory nil)

(defun ndeb-binary-temporary-subdirectory-initialize ()
  "Initialize temporary subdirectory for ndeb-binary."
  (setq ndeb-binary-temporary-subdirectory
	(make-temp-name (ndeb-binary-expand-file-name
			 "nb" ndeb-binary-temporary-directory)))
  (make-directory ndeb-binary-temporary-subdirectory) ;; error if already exists
  (set-file-modes ndeb-binary-temporary-subdirectory 448) ;; octal 0700
  (add-hook 'kill-emacs-hook 'ndeb-binary-temporary-subdirectory-cleanup))

(defun ndeb-binary-temporary-subdirectory-cleanup ()
  "Cleanup temporary subdirectory for ndeb-binary."
  (remove-hook 'kill-emacs-hook 'ndeb-binary-temporary-subdirectory-cleanup)
  (if (and ndeb-binary-temporary-subdirectory
	   (file-directory-p ndeb-binary-temporary-subdirectory))
      (condition-case nil
	  (let ((files (directory-files ndeb-binary-temporary-subdirectory
					'full "[^.]" 'nosort)))
	    (while files
	      (delete-file (car files))
	      (setq files (cdr files)))
	    (delete-directory ndeb-binary-temporary-subdirectory))
	(error nil)))
  (setq ndeb-binary-temporary-subdirectory nil))

(defun ndeb-binary-initialize ()
  "Initialize ndeb-binary module."
  (ndeb-binary-temporary-subdirectory-initialize)
  (unless ndeb-binary-link-map
    (setq ndeb-binary-link-map (copy-keymap lookup-content-mode-map))
    (define-key ndeb-binary-link-map "\C-m" 'ndeb-binary-follow-link)
    (define-key ndeb-binary-link-map "e" 'ndeb-binary-extract-link)
    (if (featurep 'xemacs)
	(define-key ndeb-binary-link-map 'button2 'ndeb-binary-mouse-follow)
      (define-key ndeb-binary-link-map [mouse-2] 'ndeb-binary-mouse-follow)))
  (unless ndeb-binary-image-page-map
    (setq ndeb-binary-image-page-map (copy-keymap lookup-content-mode-map))
    (if (featurep 'xemacs)
	(define-key ndeb-binary-image-page-map 'button2
	  'ndeb-binary-image-page-follow)
      (define-key ndeb-binary-image-page-map [mouse-2]
	'ndeb-binary-image-page-follow)))
  (when window-system
    (cond ((lookup-inline-image-p 'xbm)
	   (setq ndeb-binary-glyph-compose-function 'lookup-glyph-compose
		 ndeb-binary-glyph-insert-function 'lookup-glyph-insert))
	  ((featurep 'bitmap)
	   (setq ndeb-binary-glyph-compose-function 'lookup-bitmap-compose
		 ndeb-binary-glyph-insert-function 'insert)))))

(defun ndeb-binary-set-link (start end face type target &optional params)
  "Create a link between the range from START to END to play the
binary on the current dictionary.

FACE is a face for the link or `lookup-reference-face' if nil.
TYPE is a symbol that represents the binary type.
TARGET is a string that specifies the binary location.
PARAMS is a list of additional parameters used to format the eblook
command defined in `ndeb-binary-extract-commands'."
  (let ((binary (list (cons 'type type)
		      (cons 'target target))))
    (if params
	(setq binary (append binary
			     (list (append (list 'parameters) params)))))
    (add-text-properties start end
			 (list 
			  (if (< emacs-major-version 21) 'local-map
			    'keymap)
			  ndeb-binary-link-map
			  'face (or face 'lookup-reference-face)
			  'mouse-face 'highlight
			  'help-echo (format
				      "[%s] mouse-2: play, e: extract"
				      type)
			  'lookup-tab-stop t
			  'ndeb-binary binary))))

(defun ndeb-binary-get-link (pos)
  "Return the binary link at POS."
  (get-text-property pos 'ndeb-binary))

(defun ndeb-binary-expand-file-name (name &optional dir)
  (let ((directory-sep-char ?/))
    (expand-file-name name dir)))

(defun ndeb-binary-bind-temporary-file (dictionary target type)
  (let* ((files (lookup-dictionary-get-property dictionary 'binary-files))
	 (file (assq target files))
	 name lock)
    (if file
	(setq files (delq file files)
	      name (nth 1 file)
	      lock (1+ (nth 2 file)))
      (setq name (ndeb-binary-make-temp-name type)
	    lock 1))
    (lookup-dictionary-put-property
     dictionary 'binary-files (append files (list (list target name lock))))
    name))

(defun ndeb-binary-make-temp-name (type)
  (let* ((suffix (lookup-assq-ref 'ndeb-binary-extensions type))
	 (rest 10)
	 name)
    (setq name (catch 'done
		 (while (< 0 rest)
		   (let ((file (make-temp-name
				(ndeb-binary-expand-file-name
				 "nb" ndeb-binary-temporary-subdirectory))))
		     (when suffix
		       (setq file (concat file "." suffix)))
		     (unless (file-exists-p file)
		       (throw 'done file)))
		   (setq rest (1- rest)))))
    (unless name
      (error "Unable to create unique filename"))
    name))

(defun ndeb-binary-unbind-temporary-file (dictionary target)
  (let* ((files (lookup-dictionary-get-property dictionary 'binary-files))
	 (file (assq target files)))
    (when file
      (let ((name (nth 1 file))
	    (lock (1- (nth 2 file))))
	(setq files (delq file files))
	(if (< lock 1)
	    (condition-case nil
		(progn
		  (delete-file name)
		  (message "Deleted %s" name))
	      (error nil))
	  (setq files (append files (list (list target name lock)))))
	(lookup-dictionary-put-property dictionary 'binary-files files)))))

(defun ndeb-binary-extract (dictionary type target params file)
  "Extract the binary into a file named FILE.

DICTIONARY is a dictionary that contains the target binary.
TYPE is a symbol that represents the binary type.
TARGET is a string that specifies the binary location.
PARAMS is a list of additional parameters used to format the eblook
command or nil if not needed.

See `ndeb-binary-extract-commands' for the available binary types and
corresponding eblook commands."
  (let ((case-fold-search nil)
	(command (apply 'format
			(lookup-assq-ref 'ndeb-binary-extract-commands type)
			(append (list target) params))))
    (ndeb-with-dictionary dictionary
      (save-match-data
        ;; if the command still contains "%s", eblook will create the
        ;; output file.
        (if (string-match "%s" command)
            (let (ret)
              (setq command (replace-match file t t command))
              (message command)
              (setq ret (ndeb-process-require command))
              (unless (string-match "^OK" ret)
                (when (string-match "[ \t\r\n]+$" ret)
                  (setq ret (replace-match "" t t ret)))
                (error ret)))
          ;; otherwise write the eblook output to a temporary file.
          ;; TODO: how eblook returns an error in this case?
          (with-temp-buffer
            (message command)
            (buffer-disable-undo)
            (set-buffer-file-coding-system 'raw-text)
            (insert (ndeb-process-require command))
            (let ((out (with-output-to-string (write-file file))))
              (lookup-proceeding-message out))))))))

;;;
;;; Functions for a link
;;;

(defun ndeb-binary-process-sentinel (process event)
  (when (string-match "^\\(exited\\|finished\\)" event)
    (let ((pi (assq (process-id process) ndeb-binary-processes)))
      (ndeb-binary-unbind-temporary-file (lookup-get-dictionary (nth 1 pi))
					 (nth 2 pi))
      (setq ndeb-binary-processes (delq pi ndeb-binary-processes)))))

(defun ndeb-binary-follow-link ()
  "Play the binary at point."
  (interactive)
  (let* ((dictionary (lookup-entry-dictionary lookup-content-entry))
	 (link (ndeb-binary-get-link (point)))
	 (type (lookup-assq-ref 'link 'type))
	 (target (lookup-assq-ref 'link 'target))
	 (parameters (lookup-assq-ref 'link 'parameters))
	 (program (lookup-assq-ref 'ndeb-binary-programs type)))
    (cond
     ((null program)
      (call-interactively 'ndeb-binary-extract-link))
     ((symbolp (car program))
      (funcall (car program) dictionary target type parameters))
     (t
      (let ((case-fold-search nil)
	    (lookup-proceeding-message "Playing binary")
	    file)
	(lookup-proceeding-message nil)
	(setq 
	 file (ndeb-binary-bind-temporary-file dictionary target type))
	(if (file-exists-p file)
	    (lookup-proceeding-message (concat "Reusing " file))
	  (ndeb-binary-extract dictionary type target parameters file))
	(condition-case err
	    (let* ((params (car program))
		   (program (cdr program))
		   (sep (and (> (length program) 1)
			     (plist-get program :directory-separator)))
		   process)
	      (if (stringp params)
		  (setq params (list params)))
	      (when sep
		(save-match-data
		  (while (string-match "/" file)
		    (setq file (replace-match sep t t file)))))
	      (setq params (append params (list file)))
	      (princ (mapconcat 'identity params " "))
	      (setq process (or (apply 'start-process
				       "ndeb-binary"
				       (get-buffer "*Messages*")
				       (car params)
				       (cdr params))
				(error "Invalid process object")))
	      (if (and (> (length program) 1)
		       (plist-get program :disable-sentinel))
		  (sit-for 3)
		(setq ndeb-binary-processes
		      (append ndeb-binary-processes
			      (list (list (process-id process)
					  (lookup-dictionary-id dictionary)
					  target))))
		(set-process-sentinel process 'ndeb-binary-process-sentinel))
	      (lookup-proceeding-message t))
	  (ndeb-binary-unbind-temporary-file dictionary target)
	  (error (message "%s" err))))))))

(defun ndeb-binary-follow-first-link (types &optional num)
  "Internal use. Call this function from beginning of buffer."
  (unless (listp types) (setq types (list types)))
  (unless (numberp num) (setq num 1))
  (let (point sym)
    (catch 'loop
      (while
	  (setq point (or (and (eq (point) (point-min))
			       (ndeb-binary-get-link (point-min))
			       (point-min))
			  (next-single-property-change (point) 'ndeb-binary)))
	(goto-char point)
        (setq sym (ndeb-binary-get-link point))
	(let ((type (lookup-assq-ref 'sym 'type)))
	  (when (and (memq type types)
		     (eq 0 (setq num (1- num)))
		     (assq type ndeb-binary-programs))
	    (ndeb-binary-follow-link)
	    (throw 'loop t)))
	(next-single-property-change (point) 'ndeb-binary)))))

(defun ndeb-binary-mouse-follow (event)
  "Play the binary you click on."
  (interactive "e")
  (mouse-set-point event)
  (ndeb-binary-follow-link))

(defun ndeb-binary-image-page-follow (event)
  (interactive "e")
  (mouse-set-point event)
  ;; Just for safe.
  (when (functionp 'posn-object-x-y)
    (let ((links (get-text-property (point) 'ndeb-binary-image-page))
	  (pos (posn-object-x-y (event-start event))))
      (while links
	(let ((link (car (car links))))
	  (when (and (<= (car (car link)) (car pos))
		     (<= (cdr (car link)) (cdr pos))
		     (>= (car (cdr link)) (car pos))
		     (>= (cdr (cdr link)) (cdr pos)))
	    (let* ((entries
		    (list (lookup-new-entry
                           'regular
			   (lookup-entry-dictionary
			    lookup-content-entry)
			   (cdr (car links))
			   lookup-reference-default-caption)))
		   (module (lookup-session-module lookup-current-session))
		   (heading (lookup-entry-heading lookup-content-entry))
		   (query (lookup-new-query 'reference heading)))
	      (lookup-display-entries module query entries))
	    (setq links nil)))
	(setq links (cdr links))))))

(defun ndeb-binary-extract-link (link file &optional confirm)
  "Save the binary at LINK into a file FILE.
If the optional argument CONFIRM is non-nil, prompt before
overwriting an existing file.

Interactively, this function obtains the link at point, prompts for
FILE and confirm overwriting if necessary."
  (interactive
   (let ((ref (or (ndeb-binary-get-link (point))
		  (error "No binary at point"))))
     (list 'ref
	   (read-file-name (format "Save %s into file: "
				   (lookup-assq-ref 'ref 'type)))
	   t)))
  (setq file (expand-file-name file))
  (and confirm
       (file-exists-p file)
       (or (y-or-n-p (format "File %s exists; overwrite? " file))
	   (error "Canceled")))
  (ndeb-binary-extract (lookup-entry-dictionary lookup-content-entry)
		       (lookup-assq-ref 'link 'type)
		       (lookup-assq-ref 'link 'target)
		       (lookup-assq-ref 'link 'parameters)
		       file))

(defun ndeb-binary-play-with-mci (dictionary target type parameters)
  "Play media link by MCI functions."
  (unless (functionp 'mw32-mci-send-string)
    (error "This emacs does not support MCI functions"))
  (let ((file (ndeb-binary-make-temp-name type))
	device-id)
    (ndeb-binary-extract dictionary type target parameters file)
    (setq device-id (mw32-mci-send-string
		     (format "open \"%s\" alias %s" file file)))
    (unless (stringp device-id)
      (error "MCI open command error %d" device-id))
    (mw32-mci-send-string (format "play %s notify" file))
    (mw32-mci-add-notify-callback
     (string-to-number device-id)
     'ndeb-binary-play-with-mci-notify file)))

(defun ndeb-binary-play-with-mci-notify (device-id exit-state file)
  (cond
   ((eq exit-state 'mw32-mci-notify-successful)
    (mw32-mci-remove-notify-callback
     device-id 'ndeb-binary-play-with-mci-notify)
    (mw32-mci-send-string (format "close %s" file))
    (condition-case nil
	(delete-file file)
      (error nil)))
   (t
    (error "Abnormal termination"))))

(defun ndeb-binary-play-sound-file (dictionary target type parameters)
  "Play media link by play-sound-file function.
When you use Meadow, use `ndeb-binary-play-with-mci'.
Using this function with :snd-autoplay option is not recommendable."
  (unless (functionp 'play-sound-file)
    (error "This emacs does not have play-sound-file function"))
  (let ((file (ndeb-binary-make-temp-name type)))
    (ndeb-binary-extract dictionary type target parameters file)
    (play-sound-file file)
    (condition-case nil
	(delete-file file)
      (error nil))))

(defun lookup-entry-play-ndeb-sound (&optional num)
  "Play first wave link of ndeb contents."
  (interactive "p")
  (if (assq 'wave ndeb-binary-programs)
      (lookup-entry-play-ndeb-binaries-internal 'wave num)
    (error "Please set ndeb-binary-programs for wave")))

(defun lookup-entry-play-ndeb-movie (&optional num)
  "Play first movie link of ndeb contents."
  (interactive "p")
  (if (assq 'mpeg ndeb-binary-programs)
      (lookup-entry-play-ndeb-binaries-internal 'mpeg num)
    (error "Please set ndeb-binary-programs for mpeg")))

(defun lookup-entry-play-ndeb-binaries (&optional num)
  "Play first link of ndeb contents. Binary types to play is decided by `ndeb-play-binaries-from-entry'."
  (interactive "p")
  (let ((types
	 (or (lookup-assoc-ref ndeb-play-binaries-from-entry
			       (this-command-keys))
	     ;; when called with prefix argument.
	     (lookup-assoc-ref ndeb-play-binaries-from-entry
			       (and
				(string-match
				 (format "^\\(.+%s\\)\\([^0-9].*$\\)"
					 (number-to-string num))
				 (this-command-keys))
				(match-string 2 (this-command-keys)))))))
    (if types
	(let ((params types))
	  (catch 'done
	    (while params
	      (when (assq (car params) ndeb-binary-programs)
		(throw 'done t))
	      (setq params (cdr params)))
	    (error "Please set ndeb-binary-programs appropriately"))
	  (lookup-entry-play-ndeb-binaries-internal types num))
      (error "Please set ndeb-play-binaries-from-entry appropriately"))))

(defun lookup-entry-play-ndeb-binaries-internal (types &optional num)
  (unless (listp types) (setq types (list types)))
  (let ((dictionary (lookup-entry-dictionary
		     (lookup-entry-current-line-entry)))
	autoplay)
    (unless (lookup-entry-content-visible-p)
      (when (setq autoplay
		  (lookup-dictionary-option dictionary :snd-autoplay))
	(lookup-set-dictionary-option
	 (lookup-dictionary-id dictionary) :snd-autoplay nil))
      (lookup-entry-display-content)
      (when autoplay
	(lookup-set-dictionary-option
	 (lookup-dictionary-id dictionary) :snd-autoplay autoplay)))
    (with-current-buffer lookup-content-buffer
      (save-excursion
	(goto-char (point-min))
	(unless (ndeb-binary-follow-first-link types num)
	  (message "No specific and playable binaries"))))))

;;;
;;; Functions for constructing the content buffer
;;;

(defun ndeb-binary-format-caption (start end type target &rest params)
  "Format captions for binary links."
  (let (caption-format caption-face caption)
    (cond
     ((eq type 'wave)
      (setq caption ndeb-sound-default-caption
	    caption-format ndeb-sound-caption-format
	    caption-face 'ndeb-sound-caption-face))
     ((eq type 'mpeg)
      (setq caption ndeb-movie-default-caption
	    caption-format ndeb-movie-caption-format
	    caption-face 'ndeb-movie-caption-face))
     (t
      (setq caption ndeb-image-default-caption
	    caption-format ndeb-image-caption-format
	    caption-face 'ndeb-image-caption-face)))
    (goto-char start)
    (unless (= start end)
      (setq caption (buffer-substring start end))
      (delete-region start end))
    (insert (if caption-format
		(format caption-format caption)
	      caption))
    (ndeb-binary-set-link start (point)
			  caption-face type target params)))

(defun ndeb-binary-insert-mono-image (dictionary target width height)
  "Insert an inline monochrome image."
  (when ndeb-binary-glyph-compose-function
    (let ((command (format "xbm %s %s %s" target width height))
	  xbm glyph start)
      (lookup-proceeding-message command)
      (setq xbm (ndeb-with-dictionary dictionary
                  (ndeb-process-require command)))
      (condition-case nil
	  (setq glyph (funcall ndeb-binary-glyph-compose-function xbm))
	(if (string-match "[ \t\r\n]+$" xbm)
	    (setq xbm (replace-match "" t t xbm)))
	(error xbm))
      (insert ?\n)
      (setq start (point))
      (funcall ndeb-binary-glyph-insert-function glyph)
      (if (featurep 'xemacs)
	  (set-glyph-property glyph 'face 'ndeb-image-mono-face)
	(if (fboundp 'line-beginning-position) ;; just for safe.
	    (save-excursion
	      (while (<= start (point))
		(put-text-property (line-beginning-position) (line-end-position)
				   'face 'ndeb-image-mono-face)
		(forward-line -1)))))
      (unless (= (following-char) ?\n)
	(insert ?\n)))))

(defun ndeb-binary-insert-color-image (dictionary type target &optional start end)
  "Insert an inline color image of type TYPE."
  (when (lookup-inline-image-p type)
    (let ((file (make-temp-name
		 (ndeb-binary-expand-file-name
		  "nb" ndeb-binary-temporary-subdirectory))))
      (ndeb-binary-extract dictionary type target nil file)
      (if (and start end)
	  (lookup-img-file-insert file type start end)
	(insert ?\n)
	(lookup-img-file-insert file type)
	(unless (= (following-char) ?\n)
	  (insert ?\n)))
      (condition-case nil
	  (delete-file file)
	(error nil))
      t)))

;;;
;;; Arrange functions
;;;

(defun ndeb-arrange-xbm (entry)
  "Arrange monochrome images on an ndeb entry."
  (let ((regexp (lookup-dictionary-option dictionary :xbm-regexp t)))
    (while (re-search-forward (car regexp) nil t)
      (let ((width (match-string 1))
	    (height (match-string 2))
	    (start (match-beginning 0)))
	(replace-match "" t t)
	(condition-case err
	    (let (end target)
	      (re-search-forward (cdr regexp))
	      (setq end (match-beginning 0)
		    target (match-string 1))
	      (replace-match "" t t)
	      (ndeb-binary-format-caption start end
					  'xbm target width height)
	      (when lookup-inline-image
		(ndeb-binary-insert-mono-image dictionary target width height)))
	  (error (message "%s" err)))))))

(defun ndeb-arrange-bmp (entry)
  "Arrange bmp images on an ndeb entry."
  (let ((regexp (lookup-dictionary-option dictionary :bmp-regexp t)))
    (while (re-search-forward (car regexp) nil t)
      (let ((start (match-beginning 0)))
	(replace-match "" t t)
	(condition-case err
	    (let (end target inline)
	      (re-search-forward (cdr regexp))
	      (setq end (match-beginning 0)
		    target (match-string 2)
		    inline (equal (match-string 1) "inline"))
	      (replace-match "" t t)
	      (ndeb-binary-format-caption start end 'bmp target)
	      (when lookup-inline-image
		(if inline
		    (ndeb-binary-insert-color-image
		     dictionary ndeb-binary-bmp-display-type target
		     start (point))
		  (ndeb-binary-insert-color-image
		   dictionary ndeb-binary-bmp-display-type target))))
	  (error (message "%s" err)))))))

(defun ndeb-arrange-jpeg (entry)
  "Arrange jpeg images on an ndeb entry."
  (let ((regexp (lookup-dictionary-option dictionary :jpeg-regexp t)))
    (while (re-search-forward (car regexp) nil t)
      (let ((start (match-beginning 0)))
	(replace-match "" t t)
	(condition-case err
	    (let (end target inline)
	      (re-search-forward (cdr regexp))
	      (setq end (match-beginning 0)
		    target (match-string 2)
		    inline (equal (match-string 1) "inline"))
	      (replace-match "" t t)
	      (ndeb-binary-format-caption start end 'jpeg target)
	      (when lookup-inline-image
		(if inline
		    (ndeb-binary-insert-color-image dictionary 'jpeg target
						    start (point))
		  (ndeb-binary-insert-color-image dictionary 'jpeg target))))
	  (error (message "%s" err)))))))

(defun ndeb-arrange-wave (entry)
  "Arrange wave sound on an ndeb entry."
  (let ((regexp (lookup-dictionary-option dictionary :wave-regexp t)))
    (while (re-search-forward (car regexp) nil t)
      (let ((pos_start (match-string 1))
	    (pos_end (match-string 2))
	    (start (match-beginning 0)))
	(replace-match "" t t)
	(condition-case err
	    (let (end)
	      (re-search-forward (cdr regexp))
	      (setq end (match-beginning 0))
	      (replace-match "" t t)
	      (ndeb-binary-format-caption start end 'wave 
						(concat pos_start " " pos_end)))
	  (error (message "%s" err)))))))

(defun ndeb-arrange-mpeg (entry)
  "Arrange mpeg movie on an ndeb entry."
  (let* ((regexp (lookup-dictionary-option dictionary :mpeg-regexp t)))
    (while (re-search-forward (car regexp) nil t)
      (let ((id1 (match-string 1))
	    (id2 (match-string 2))
	    (id3 (match-string 3))
	    (id4 (match-string 4))
	    (start (match-beginning 0)))
	(replace-match "" t t)
	(condition-case err
	    (let (end)
	      (re-search-forward (cdr regexp))
	      (setq end (match-beginning 0))
	      (replace-match "" t t)
	      (ndeb-binary-format-caption start end 'mpeg
					  (concat id1 " " id2 " " id3 " " id4)))
	  (error (message "%s" err)))))))

(defun ndeb-arrange-image-page (entry)
  ;; $B2hA|$N(Barrange$B4X?t$N8e$K8F$V;v(B
  (when (search-forward  "<image-page>" nil t)
    (replace-match "")
    (let (areas)
      (while (re-search-forward "<clickable-area x=\\([0-9]+\\) y=\\([0-9]+\\) w=\\([0-9]+\\) h=\\([0-9]+\\) \\([0-9]+:[0-9]+\\)>" nil t)
	(let* ((pos (match-string 5))
	       (start (match-beginning 0))
	       (end (match-end 0))
	       (beg-pos (cons (string-to-number (match-string 1))
			      (string-to-number (match-string 2))))
	       (params (cons beg-pos
			     (cons
			      (+ (car beg-pos)
				 (string-to-number (match-string 3)) -1)
			      (+ (cdr beg-pos)
				 (string-to-number (match-string 4)) -1)))))
	  (setq areas (append areas `((,params . ,pos))))
	  (condition-case nil
	      (progn
		(search-forward "</clickable-area>")
		(replace-match (format "</reference=%s>\n" pos))
		(delete-region start end)
		(goto-char start)
		(insert (format "<reference>%04d,%04d-%04d,%04d"
				(car (car params))
				(cdr (car params))
				(car (cdr params))
				(cdr (cdr params)))))
	    (error nil))))
      (when (search-forward  "</image-page>" nil t)
	(delete-region (match-beginning 0) (point-max)))
      
      (goto-char (point-min))
      (when (functionp 'posn-object-x-y)
	;; emacs version is always >= 22.
	(let (start end)
	  (when (setq start (next-single-property-change (point) 'display))
	    (goto-char start)
	    (setq end (or (next-single-property-change (point) 'display)
			  (point-max)))
	    (add-text-properties start end
				 (list 'ndeb-binary-image-page areas
				       'keymap
				       ndeb-binary-image-page-map))))))))
  
(defun ndeb-arrange-snd-autoplay (entry)
  "Arrange function for Lookup to play sound in an ndeb entry if option :snd-autoplay is non-nil."
  (when (and (lookup-dictionary-option dictionary :snd-autoplay nil)
	     (assq 'wave ndeb-binary-programs))
    (ndeb-binary-follow-first-link 'wave)))

;;;
;;; Setup
;;;

(eval-after-load "lookup-content" '(ndeb-binary-initialize))

(when ndeb-play-sound-from-entry
  (eval-after-load "lookup-entry"
    '(define-key lookup-entry-mode-map ndeb-play-sound-from-entry
       (function lookup-entry-play-ndeb-sound))))

(when ndeb-play-movie-from-entry
  (eval-after-load "lookup-entry"
    '(define-key lookup-entry-mode-map ndeb-play-movie-from-entry
       (function lookup-entry-play-ndeb-movie))))

(when ndeb-play-binaries-from-entry
  (eval-after-load "lookup-entry"
    '(let ((keys ndeb-play-binaries-from-entry))
       (while keys
	 (define-key lookup-entry-mode-map (car (car keys))
	   (function lookup-entry-play-ndeb-binaries))
	 (setq keys (cdr keys))))))

;;;
;;; Cleanup
;;;

(defun ndeb-binary-clear-dictionary (dictionary)
  "Clear temporary files for DICTIONARY."
  (mapc
   (lambda (file)
     (condition-case nil
	 (let ((name (nth 1 file)))
	   (when (file-exists-p name)
	     (let ((lookup-proceeding-message (format "Deleting %s" name)))
	       (lookup-proceeding-message nil)
	       (delete-file name)
	       (lookup-proceeding-message t))))
	   (error nil)))
   (lookup-get-property dictionary 'binary-files))
  (lookup-put-property dictionary 'binary-files nil))

(defun ndeb-binary-clear (agent)
  "Clear temporary files used by ndeb-binary."
  (let ((dictionaries (append (lookup-agent-dictionaries agent) nil)))
    (mapc 'ndeb-binary-clear-dictionary dictionaries)))

(provide 'ndeb-binary)
