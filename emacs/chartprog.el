;;; chartprog.el --- stock quotes using Chart.

;; Copyright 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012, 2013, 2014 Kevin Ryde

;; Author: Kevin Ryde <user42_kevin@yahoo.com.au>
;; Keywords: comm, finance
;; URL: http://user42.tuxfamily.org/chart/index.html

;; This file is part of Chart.
;;
;; Chart is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; Chart is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; See section "Emacs" in the Chart manual for usage.


;;; Code:

(require 'cl)  ;; for `remove*', `assoc*', `find', maybe more
(require 'timer) ;; xemacs21


;;-----------------------------------------------------------------------------
;; customizations

;;;autoload
(defgroup chartprog nil
  "Chart program interface."
  :prefix "chartprog-"
  :group 'applications
  :link '(custom-manual "(chart)Emacs"))

(defface chartprog-up
  `(;; plain "green" is too light to see against a white background
    (((class color) (background light))
     (:foreground "green4"))
    (((class color))
     (:foreground "green")))
  "Face for a Chart quote which is up."
  :group 'chartprog)

(defface chartprog-down
  `((((class color))
     (:foreground "red")))
  "Face for a Chart quote which is down."
  :group 'chartprog)

(defface chartprog-in-progress
  `((((class color) (background dark))
     (:foreground "cyan"))
    (((class color) (background light))
     (:foreground "blue")))
  "Face for Chart quote fetch in progress."
  :group 'chartprog)

(defcustom chartprog-watchlist-hook nil
  "*Hook called by `chart-watchlist'."
  :type  'hook
  :group 'chartprog)


;;-----------------------------------------------------------------------------
;; xemacs compatibility

;; Past versions lacked propertize did they?  Forget when or what.

;;     (unless (fboundp 'propertize)
;;       (defun chartprog-propertize (str &rest properties)
;;         "Return a copy of STR with PROPERTIES added.
;; PROPERTIES is successive arguments PROPERTY VALUE PROPERTY VALUE ..."
;;         (setq str (copy-sequence str))
;;         (add-text-properties 0 (length str) properties str)
;;         str))))


;;----------------------------------------------------------------------------
;; emacs22 new stuff

(cond ((eval-when-compile (fboundp 'completion-table-dynamic))
       ;; emacs23
       (eval-and-compile
         (defalias 'chartprog--completion-table-dynamic
           'completion-table-dynamic)))

      ((eval-when-compile (fboundp 'dynamic-completion-table))
       ;; emacs22
       (defun chartprog--completion-table-dynamic (func)
         (eval `(dynamic-completion-table ,func))))

      (t
       ;; emacs21,xemacs21
       ;; a table as a function must be a symbol, can't be a lambda form
       (defun chartprog--completion-table-dynamic (func)
         (let ((sym (make-symbol "table-dynamic")))
           (fset sym `(lambda (str pred action)
                        (let ((table (funcall ',func str)))
                          (cond ((null action)
                                 (try-completion str table pred))
                                ((eq action t)
                                 (all-completions str table pred))
                                (t
                                 (eq t (try-completion str table pred)))))))
           sym))))

;;-----------------------------------------------------------------------------
;; misc

(defmacro chartprog-with-temp-message (message &rest body)
  "Display MESSAGE temporarily while evaluating BODY.
This is the same as `with-temp-message' but has a workaround for a bug in
Emacs 21.4 where the temporary message isn't erased if there was no previous
message."
  (if (eval-when-compile (featurep 'xemacs))
      ;; one key for each macro usage, which means each usage is not reentrant
      (let ((key (gensym "chartprog-with-temp-message--")))
        `(unwind-protect
             (progn
               (display-message ',key ,message)
               (prog1 (progn ,@body)
                 (clear-message ',key)))
           (clear-message ',key)))

    `(let* ((chartprog-with-temp-message--oldmsg (current-message)))
       (unwind-protect
           (prog1 (with-temp-message ,message ,@body)
             (or chartprog-with-temp-message--oldmsg (message nil)))
         (or chartprog-with-temp-message--oldmsg (message nil))))))

(put 'chartprog-with-temp-message 'lisp-indent-function 1)

(defmacro chartprog-save-row-col (&rest body)
  "Evaluate BODY, preserving point+mark row/col and window start positions.
This is a bit like `save-excursion', but working with row+column rather than
a point position."
  `(let* ((point-row (count-lines (point-min) (point-at-bol)))
          (point-col (current-column))
          (mark-pos  (mark t)))
     (and mark-pos
          (goto-char mark-pos))
     (let* ((mark-row    (count-lines (point-min) (point-at-bol)))
            (mark-col    (current-column))
            ;; list of pairs (WINDOW . ROW)
            (window-rows (mapcar (lambda (window)
                                   (cons window
                                         (count-lines (point-min)
                                                      (window-start window))))
                                 (get-buffer-window-list (current-buffer)))))
       (prog1 (progn ,@body)
         (dolist (pair window-rows)
           (goto-char (point-min))
           (forward-line (cdr pair))
           (set-window-start (car pair) (point)))

         (goto-char (point-min))
         (forward-line mark-row)
         (move-to-column mark-col)
         (and mark-pos
              (set-marker (mark-marker) (point)))

         (goto-char (point-min))
         (forward-line point-row)
         (move-to-column point-col)))))

(put 'chartprog-save-row-col 'lisp-indent-function 0)

(defun chartprog-intersection (x y)
  "Return the intersection of lists X and Y, ie. elements common to both.
Elements are compared with `equal' and returned in the same order as they
appear in X.

This differs from the cl.el `intersection' in preserving the order of
elements for the return, the cl package doesn't preserve the order."

  (remove* nil x :test-not (lambda (dummy xelem)
                             (member xelem y))))

(defvar chartprog-symbol-history nil
  "Interactive history list of Chart symbols.")

(defun chartprog-copy-tree-no-properties (obj)
  "Return a copy of OBJ with no text properties on strings.
OBJ can be a list or other nested structure."
  (cond ((stringp obj)
         (setq obj (copy-sequence obj))
         (set-text-properties 0 (length obj) nil obj)
         obj)
        ((sequencep obj)
         (mapcar 'chartprog-copy-tree-no-properties obj))
        (t
         obj)))


;;-----------------------------------------------------------------------------
;; subprocess

(defconst chartprog-protocol-version 101)  ;; see App::Chart::EmacsMain

(defvar chartprog-process nil
  "The running chart subprocess, or nil if not running.")
(defvar chartprog-process-timer nil
  "Idle timer to kill chart subprocess when it's unused for a while.")

;; forward references
(defvar chartprog-completion-symbols-alist)
(defvar chartprog-latest-cache)
(defvar chartprog-symlist-alist)
(defvar chartprog-watchlist-map)
(defvar chartprog-watchlist-menu)

(defun chartprog-exec (proc &rest args)
  "Call chart PROC (a symbol) with ARGS (lists, strings, whatever)."

  ;; startup subprocess if not already running
  (unless chartprog-process
    (when (get-buffer " *chartprog subprocess*") ;; possible old buffer
      (kill-buffer " *chartprog subprocess*"))

    (setq chartprog-process
          (let ((process-connection-type nil)) ;; pipe
            (funcall 'start-process
                     "chartprog"
                     (get-buffer-create " *chartprog subprocess*")
                     "chart" "--emacs")))
    (set-process-coding-system chartprog-process 'utf-8 'utf-8)
    (set-process-filter chartprog-process 'chartprog-process-filter)
    (set-process-sentinel chartprog-process 'chartprog-process-sentinel)
    ;; `process-kill-without-query' is "obsolete" in emacs 22 (superceded by
    ;; `set-process-query-on-exit-flag'), but keep using it for emacs 21
    ;; compatibility
    (process-kill-without-query chartprog-process)
    (buffer-disable-undo (process-buffer chartprog-process)))

  ;; send this command
  (let ((form (cons proc args)))
    (process-send-string chartprog-process
                         (concat (prin1-to-string
                                  (chartprog-copy-tree-no-properties form)) "\n")))
  ;; start or restart idle timer
  (when chartprog-process-timer
    (cancel-timer chartprog-process-timer))
  (setq chartprog-process-timer (run-at-time "5 min" nil 'chartprog-process-kill)))

(defun chartprog-incoming-init (codeset protocol-version)
  "Handle chart subprocess init message.
CODESET is always \"UTF-8\".
PROTOCOL-VERSION is the protocol number the subprocess is speaking, to be
matched against `chartprog-protocol-version'."

  (unless (= protocol-version chartprog-protocol-version)
    (when (get-buffer "*chartprog-watchlist*") ;; ignore if gone
      (with-current-buffer "*chartprog-watchlist*"
        (let ((buffer-read-only nil))
          (erase-buffer)
          (insert (format "Chart program doesn't match this chartprog.el.

  chartprog.el protocol:  %s
  chart program protocol: %s

Check your installation.
" chartprog-protocol-version protocol-version)))))

    (chartprog-process-kill)
    (error "Chart subprocess protocol version mismatch, got %s want %s"
           chartprog-protocol-version protocol-version)))

(defun chartprog-process-filter (proc str)
  "Handle chart PROC subprocess output STR."
  (with-current-buffer (process-buffer proc)
    (goto-char (point-max))
    (insert str)
    (while (progn
             ;; form begins with "(", ignore other diagnostics or whatever
             (goto-char (point-min))
             (skip-chars-forward "^(")
             (delete-region (point-min) (point))

             ;; see if a complete form has arrived
             (let ((form (condition-case nil
                             (read (process-buffer proc))
                           (error nil))))
               (when form
                 (delete-region (point-min) (point))
                 (apply (intern (concat "chartprog-incoming-"
                                        (symbol-name (car form))))
                        (cdr form)))

               ;; no more processing after `synchronous', let the result get
               ;; back to the caller before further asynch stuff is
               ;; processed (that further stuff deferred under a timer)
               (when (eq (first form) 'synchronous)
                 (run-at-time 0.0000001 nil
                              (lambda ()
                                (chartprog-process-filter chartprog-process "")))
                 (setq form nil))

               ;; process another form, perhaps
               form)))))

(defun chartprog-process-sentinel (proc event)
  "Handle chart PROC subprocess termination, per EVENT string."
  (when (get-buffer "*chartprog-watchlist*")
    (with-current-buffer "*chartprog-watchlist*"
      (let ((buffer-read-only nil))
        (save-excursion
          (goto-char (point-min))
          (when (looking-at "\\s-*Starting")
            (erase-buffer))
          (insert (format "\nSubprocess died: %s\n\n" event))))))
  (chartprog-process-kill)
  (message "Chart subprocess died: %s" event))

(defun chartprog-process-kill ()
  "Kill chart subprocess."
  (when chartprog-process-timer
    (cancel-timer chartprog-process-timer)
    (setq chartprog-process-timer nil))
  (when chartprog-process
    ;; clear chartprog-process variable immediately, xemacs recurses to here
    (let ((p chartprog-process))
      (setq chartprog-process nil)
      (set-process-sentinel p nil)
      (set-process-filter p nil)
      (delete-process p)
      (kill-buffer (process-buffer p)))
    ;; go back to uninitialized to force a re-read on the contents if the
    ;; subprocess is restarted, that way any additions while we were away
    ;; will appear
    (setq chartprog-completion-symbols-alist 'uninitialized)
    (setq chartprog-symlist-alist 'uninitialized)
    (setq chartprog-latest-cache (make-hash-table :test 'equal))))


;;-----------------------------------------------------------------------------
;; synchronous commands

(defvar chartprog-exec-synchronous-seq 0)
(defvar chartprog-exec-synchronous-got 0)
(defvar chartprog-exec-synchronous-result nil)

(defun chartprog-incoming-synchronous (got result)
  "Receive synchronize number GOT from Chart subprocess."
  (setq chartprog-exec-synchronous-got got)
  (setq chartprog-exec-synchronous-result result))
  
(defun chartprog-exec-synchronous (proc &rest args)
  "Call chart PROC (a symbol) with ARGS (lists, strings, whatever).
Return the return value from that call, when it completes."

  (setq chartprog-exec-synchronous-seq (1+ chartprog-exec-synchronous-seq))
  (apply 'chartprog-exec 'synchronous chartprog-exec-synchronous-seq proc args)

  (while (not (= chartprog-exec-synchronous-seq
                 chartprog-exec-synchronous-got)) ;; ignore old abandoned calls
    (if (not (eq 'run (process-status chartprog-process)))
        (error "Chart process died"))
    (accept-process-output chartprog-process))

  chartprog-exec-synchronous-result)


;;-----------------------------------------------------------------------------
;; incoming from subprocess

(defun chartprog-incoming-update (symbol-list)
  "Receive advice from Chart subprocess that SYMBOL-LIST have updated.
Any in the watchlist are reread, any cached data for `chartprog-latest' is
discarded."
  (dolist (symbol symbol-list)
    (remhash symbol chartprog-latest-cache))
  (let ((want-list (chartprog-intersection (chartprog-watchlist-symbol-list)
                                       symbol-list)))
    (if want-list
        (chartprog-exec 'latest-get-list want-list))))

(defun chartprog-incoming-message (str)
  "Receive a free-form message STR from the Chart subprocess."
  (message "%s" str))

(defun chartprog-incoming-error (errstr backtrace)
  "Receive an error message from the Chart subprocess.
ERRSTR is a string, BACKTRACE is either a string or nil."
  (when backtrace
    (with-current-buffer (get-buffer-create "*chartprog-process-backtrace*")
      (let ((follow (= (point) (point-max))))
        (save-excursion
          (goto-char (point-max))
          (insert "-------------------------------------------------------------------------------\n")
          (insert backtrace))
        (when follow
          (goto-char (point-max))))))
  (message "%s" errstr))


;;-----------------------------------------------------------------------------
;; symbols completion

(defun chartprog-minibuffer-local-completion-map ()
  "Inherited `minibuffer-local-completion-map' but with <SPACE> self-inserting.
Chart symbols can contain spaces, so <SPACE> is best as an ordinary insert,
not a completion like the default in `minibuffer-local-completion-map'."
  ;; `minibuffer-local-completion-map' might change so must
  ;; `set-keymap-parent' each time, and if doing that then the keymap is
  ;; small enough that may as well create a whole fresh one each time
  (let ((m (make-sparse-keymap)))
    (set-keymap-parent m minibuffer-local-completion-map)
    (define-key m " " 'self-insert-command)
    m))

(defvar chartprog-completion-symbols-alist 'uninitialized
  "Alist of Chart symbols for completing read, or 'uninitialized.
Call function `chartprog-completion-symbols-alist' instead of reading this
variable, the function gets the list from the Chart subprocess when
'uninitialized.")

(defun chartprog-completion-symbols-alist (&optional dummy)
  "Return an alist of Chart symbols for completing read.
Currently there's nothing in the `cdr's, it's just ((SYMBOL) (SYMBOL) ...)."
  (when (eq 'uninitialized chartprog-completion-symbols-alist)
    (chartprog-with-temp-message "Receiving database symbols ..."
      (setq chartprog-completion-symbols-alist
            (chartprog-exec-synchronous 'get-completion-symbols))))
  chartprog-completion-symbols-alist)

(defun chartprog-incoming-completion-symbols-update ()
  "Receive advice from Chart subprocess that completion symbols have changed."
  (setq chartprog-completion-symbols-alist 'uninitialized))

(defun chartprog-completing-read-symbol (&optional default)
  "Read a Chart symbol using `completing-read'.
Optional DEFAULT is a string."
  (let ((minibuffer-local-completion-map (chartprog-minibuffer-local-completion-map))
        (completion-ignore-case t))
    (if (equal "" default) ;; allow for empty from thing-at-point
        (setq default nil))
    (completing-read (if default
                         (format "Symbol (%s): " default)
                       "Symbol: ")
                     (chartprog--completion-table-dynamic
                      'chartprog-completion-symbols-alist)
                     nil  ;; pred
                     nil  ;; require-match
                     nil  ;; initial-input
                     'chartprog-symbol-history
                     default)))


;;-----------------------------------------------------------------------------
;; symlist stuff

(defvar chartprog-symlist-history nil
  "Interactive history list of Chart symlists.")

(defvar chartprog-symlist-alist 'uninitialized
  "Alist of symlists in Chart.
Each element is (NAME KEY EDITABLE), where NAME is a string, KEY is a
symbol, and EDITABLE is t or nil.  NAME is first so the list can be used
with `completing-read'.

This is the symbol `uninitialized' when data hasn't yet been read.  See the
function `chartprog-symlist-alist' for reading and initializing.")

(defun chartprog-symlist-alist ()
  "Return the variable `chartprog-symlist-alist', initializing it if necessary."
  (when (eq 'uninitialized chartprog-symlist-alist)
    (chartprog-with-temp-message "Receiving symlist info ..."
      (chartprog-exec-synchronous 'get-symlist-alist)))
  chartprog-symlist-alist)

(defun chartprog-incoming-symlist-alist (alist)
  "Receive the `chartprog-symlist-alist' data from Chart subprocess."
  (setq chartprog-symlist-alist alist)

  ;; freshen name in watchlist, if in use
  (when (get-buffer "*chartprog-watchlist*")
    (chartprog-watchlist-update-symlist-name))

  ;; fill Chart menu for watchlist
  (mapcar (lambda (elem)
            (let ((name (first elem))
                  (key  (second elem)))
              (define-key chartprog-watchlist-menu
                (vector key)
                (cons name `(lambda ()
                              (interactive)
                              (chartprog-watchlist-symlist ',key))))))
          (reverse chartprog-symlist-alist)))

(defun chartprog-symlist-editable-p (key)
  "Return true if symlist KEY (a Lisp symbol) is editable."
  (third (find key (chartprog-symlist-alist) :key 'second)))


;;-----------------------------------------------------------------------------
;; symlist name completion

;; emacs 22 has `dynamic-completion-table' to construct a function like
;; this, but emacs 21 and xemacs 21 don't
(defun chartprog-symlist-completion (str pred all)
  "Chart symlist completion handler, for `completing-read'."
  (cond ((null all)
         (try-completion str (chartprog-symlist-alist) pred))
        ((eq all t)
         (all-completions str (chartprog-symlist-alist) pred))
        ((eq all 'lambda)
         (test-completion str (chartprog-symlist-alist) pred))))

;; emacs has `compare-strings' to do this, but xemacs doesn't
(defun chartprog-string-prefix-ci-p (part str)
  "Return t if PART is a prefix of STR, case insensitive."
  (and (>= (length str) (length part))
       (string-equal (upcase part)
                     (upcase (substring str 0 (length part))))))

(defun chartprog-completing-read-symlist ()
  "Read a Chart symlist using `completing-read'.
The return is the symlist key (a symbol), eg. 'favourites."
  (let ((minibuffer-local-completion-map (chartprog-minibuffer-local-completion-map))
        (completion-ignore-case t))
    (let ((name (completing-read "Symlist: "
                                 'chartprog-symlist-completion
                                 nil  ;; pred
                                 t    ;; require-match
                                 nil  ;; initial-input
                                 'chartprog-symlist-history)))
      ;; completing-read with require-match will return with just a prefix
      ;; of one or more names, go with the first
      (second (assoc* name (chartprog-symlist-alist)
                      :test 'chartprog-string-prefix-ci-p)))))


;;-----------------------------------------------------------------------------
;; watchlist funcs

(defvar chartprog-watchlist-current-symlist 'favourites
  "Current symlist being displayed (it's Scheme `symlist-key').")

(defun chartprog-watchlist-find (symbol)
  "Move point to line for SYMBOL.
Return true if found, or return nil and leave point unchanged if not found."
  (let ((oldpos (point))
        found)
    (goto-char (point-min))
    ;; continue while not found and can move forward a line
    (while (and (not (setq found (equal symbol (chartprog-watchlist-symbol))))
                (= 0 (forward-line))))
    (unless found
      (goto-char oldpos))
    found))

(defun chartprog-watchlist-symbol ()
  "Return symbol on current watchlist line, or nil if none."
  (get-text-property (point-at-bol) 'chartprog-symbol))

(defun chartprog-watchlist-symbol-list ()
  "Return list of symbols in watchlist buffer."
  (and (get-buffer "*chartprog-watchlist*") ;; ignore if gone
       (with-current-buffer "*chartprog-watchlist*"
         (let (lst)
           (save-excursion
             (goto-char (point-min))
             (while (let ((symbol (chartprog-watchlist-symbol)))
                      (if symbol
                          (setq lst (cons symbol lst)))
                      (= 0 (forward-line)))))
           (nreverse lst)))))


;;-----------------------------------------------------------------------------
;; watchlist display

(defun chartprog-incoming-symlist-update (key-list)
  "Receive advice from Chart subprocess that symlists KEY-LIST have updated."
  (if (and (get-buffer "*chartprog-watchlist*") ;; ignore if gone
           (memq chartprog-watchlist-current-symlist key-list))
      (chartprog-exec 'get-symlist chartprog-watchlist-current-symlist)))

(defun chartprog-incoming-latest-line-list (lst)
  "Receive LST of latest elements (SYMBOL STR FACE HELP)."
  (when (get-buffer "*chartprog-watchlist*") ;; ignore if gone
    (with-current-buffer "*chartprog-watchlist*"
      (chartprog-save-row-col
        (let ((buffer-read-only nil))
          (dolist (elem lst) ;; elements (SYMBOL STR FACE)
            (when (chartprog-watchlist-find (first elem))
              (delete-region (point-at-bol) (point-at-eol))
              (insert (propertize (second elem)
                                  'chartprog-symbol (first elem)
                                  'face (third elem)
                                  'help-echo (fourth elem))))))))))

(defun chartprog-incoming-symlist-list (symlist symbol-list)
  "Receive SYMLIST contents SYMBOL-LIST from Chart subprocess."
  (when (and (get-buffer "*chartprog-watchlist*")              ;; ignore if gone
             (eq symlist chartprog-watchlist-current-symlist)) ;; stray response
    (with-current-buffer "*chartprog-watchlist*"
      (let (alst need)

        ;; build alst (SYMBOL . LINE-STRING) for existing lines
        (save-excursion
          (goto-char (point-min))
          (while (let ((symbol (chartprog-watchlist-symbol)))
                   (when symbol
                     (setq alst
                           (acons symbol
                                  (buffer-substring (point)
                                                    (1+ (point-at-eol)))
                                  alst)))
                   (= 0 (forward-line)))))

        ;; fill buffer, and use existing lines from alst
        (let ((buffer-read-only nil))
          (chartprog-save-row-col
            (erase-buffer)
            (dolist (symbol symbol-list)
              (insert (or (cdr (assoc symbol alst))
                          (progn
                            (setq need (cons symbol need))
                            (propertize (concat symbol "\n")
                                        'chartprog-symbol symbol)))))
            (unless symbol-list
              (insert (format "\n\n(Empty list, use `%s' to add a symbol.)"
                              (key-description
                               (car (where-is-internal
                                     'chartprog-watchlist-add
                                     chartprog-watchlist-map))))))))
        (if need
            (chartprog-exec 'latest-get-list (nreverse need)))))))


;;-----------------------------------------------------------------------------
;; header-line-format hscrolling

(defconst chartprog-header-line-scrolling-align0
  (propertize " " 'display '((space :align-to 0)))
  "An align-to 0 space string.")

(defvar chartprog-header-line-scrolling-str nil
  "Buffer local full `header-line-format' string to be hscrolled.")

(defun chartprog-header-line-scrolling-align ()
  "Return a string which will align to column 0 in a `header-line-format'."
  (if (string-match "^21\\." emacs-version)
      (and (display-graphic-p)
           (concat " "  ;; the fringe
                   (and (eq 'left (frame-parameter nil 'vertical-scroll-bars))
                        "  ")))  ;; left scrollbar
    ;; in emacs 22 and up align-to understands fringe and scrollbar
    chartprog-header-line-scrolling-align0))

(defun chartprog-header-line-scrolling-eval ()
  "Install hscrolling header line updates on the windows of the current frame."
  (concat (chartprog-header-line-scrolling-align)
          (substring chartprog-header-line-scrolling-str
                     (min (length chartprog-header-line-scrolling-str)
                          (window-hscroll)))))

(defun chartprog-header-line-scrolling (str)
  "Set STR as `header-line-format' and make it follow any hscrolling."
  (set (make-local-variable 'chartprog-header-line-scrolling-str) str)
  (set (make-local-variable 'header-line-format)
       '(:eval (chartprog-header-line-scrolling-eval))))


;;-----------------------------------------------------------------------------
;; watchlist commands

(defvar chartprog-watchlist-menu (make-sparse-keymap "Chart")
  "Menu for Chart watchlist.")

(defvar chartprog-watchlist-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\C-k" 'chartprog-watchlist-kill-line)
    (define-key m "\C-w" 'chartprog-watchlist-kill-region)
    (define-key m "\C-y" 'chartprog-watchlist-yank)
    (define-key m "\C-_" 'chartprog-watchlist-undo)
    (define-key m "a"    'chartprog-watchlist-add)
    (define-key m "g"    'chartprog-watchlist-refresh)
    (define-key m "n"    'next-line)
    (define-key m "q"    'chartprog-watchlist-quit)
    (define-key m "p"    'previous-line)
    (define-key m "L"    'chartprog-watchlist-symlist)
    (define-key m "?"    'chartprog-watchlist-detail)
    (define-key m [menu-bar chartprog] (cons "Chart" chartprog-watchlist-menu))
    m)
  "Keymap for Chart watchlist.")

(defun chartprog-watchlist-want-edit ()
  "Check that the watchlist being displayed is editable."
  (or (chartprog-symlist-editable-p chartprog-watchlist-current-symlist)
      (error "This list is not editable")))

(defun chartprog-watchlist-detail ()
  "Show detail for this line (stock name and full quote/last times)."
  (interactive)
  (let ((str (get-text-property (point-at-bol) 'help-echo)))
    (if str
        (message "%s" str))))

(defun chartprog-watchlist-kill-line ()
  "Kill watchlist line into the kill ring.
Use \\[chartprog-watchlist-yank] to yank it back at a new position."
  (interactive)
  (chartprog-watchlist-want-edit)
  (let ((buffer-read-only nil))
    (save-excursion
      (beginning-of-line)
      (kill-line 1)))
  (chartprog-exec 'symlist-delete chartprog-watchlist-current-symlist
              (count-lines (point-min) (point-at-bol)) 1))

(defun chartprog-watchlist-kill-region ()
  "Kill watchlist region between point and mark into the kill ring.
Use \\[chartprog-watchlist-yank] to yank them back at a new position."
  (interactive)
  (chartprog-watchlist-want-edit)
  (beginning-of-line)
  (let* ((point-row (count-lines (point-min) (point)))
         (mark-bol  (save-excursion (goto-char (mark)) (point-at-bol)))
         (mark-row   (count-lines (point-min) mark-bol)))
    (let ((buffer-read-only nil))
      (kill-region mark-bol (point)))
    (chartprog-exec 'symlist-delete chartprog-watchlist-current-symlist
                (min point-row mark-row)
                (abs (- point-row mark-row)))))

(defun chartprog-watchlist-update-symlist-name ()
  "Update the symlist name shown in the mode line."
  (with-current-buffer "*chartprog-watchlist*"
    (setq mode-name (concat "Watchlist - "
                            (first (find chartprog-watchlist-current-symlist
                                         (chartprog-symlist-alist)
                                         :key 'second))))))

(defun chartprog-watchlist-symlist (symlist)
  "Select SYMLIST to view."
  (interactive (list (chartprog-completing-read-symlist)))
  (unless (eq symlist chartprog-watchlist-current-symlist)
    (chartprog-exec 'get-symlist symlist))
  (setq chartprog-watchlist-current-symlist symlist)
  (chartprog-watchlist-update-symlist-name))

(defun chartprog-watchlist-add (symbol)
  "Add a symbol to the watchlist (after the current one).
SYMBOL is read from the minibuffer, with completion from the database symbols."
  (interactive (progn (chartprog-watchlist-want-edit)
                      (list (chartprog-completing-read-symbol))))
  (chartprog-watchlist-want-edit)
  (unless (chartprog-watchlist-find symbol)
    (beginning-of-line)
    (forward-line)
    (chartprog-exec 'symlist-insert chartprog-watchlist-current-symlist
                (count-lines (point-min) (point)) ;; position
                (list symbol))
    (let ((buffer-read-only nil))
      (insert (propertize (concat symbol "\n") 'chartprog-symbol symbol)))
    (forward-line -1)
    (chartprog-exec 'latest-get-list (list symbol))
    (chartprog-exec 'request-symbols (list symbol))))

(defun chartprog-watchlist-yank ()
  "Yank a watchlist line.
Only lines from the watchlist buffer can be yanked
\(see `chartprog-watchlist-add' to insert an arbitrary symbol)."
  (interactive)
  (chartprog-watchlist-want-edit)
  (let ((str (current-kill 0 t)))
    (if (string-match "\n+\\'" str) ;; lose trailing newlines
        (setq str (replace-match "" t t str)))
    (let ((symbol-list (mapcar (lambda (line)
                                 (get-text-property 0 'chartprog-symbol line))
                               (split-string str "\n"))))
      (if (memq nil symbol-list)
          (error "Can only yank killed watchlist line(s)"))
      (beginning-of-line)
      (chartprog-exec 'symlist-insert chartprog-watchlist-current-symlist
                  (count-lines (point-min) (point)) ;; position
                  symbol-list)
      (let ((buffer-read-only nil))
        (yank)))))

(defun chartprog-watchlist-undo ()
  "Undo last edit in the watchlist."
  (interactive)
  (error "Sorry, not working yet")

  (chartprog-watchlist-want-edit)
  (let ((buffer-read-only nil))
    (undo)))

(defun chartprog-watchlist-refresh (arg)
  "Refresh watchlist quotes.
With a prefix ARG (\\[universal-argument]), refresh only current line.

For the Alerts list, all symbols with alert levels are refreshed, and the
list contents updated accordingly.  (It's not merely those already showing
which are refreshed.)"

  (interactive "P")
  ;; updates from the subprocess with come with an in-progress face, but
  ;; apply that here explicitly to get it shown immediately
  (if arg
      (progn ;; one symbol
        (let ((buffer-read-only nil))
          (add-text-properties (point-at-bol) (point-at-eol)
                               (list 'face 'chartprog-in-progress)))
        (chartprog-exec 'request-explicit (list (chartprog-watchlist-symbol))))
    (progn ;; whole list
      (let ((buffer-read-only nil))
        (add-text-properties (point-min) (point-max)
                             (list 'face 'chartprog-in-progress)))
      (chartprog-exec 'request-explicit-symlist chartprog-watchlist-current-symlist))))

(defun chartprog-watchlist-quit ()
  "Quit from the watchlist display."
  (interactive)
  (chartprog-process-kill)
  (kill-buffer nil))

;;;###autoload
(defun chart-watchlist ()
  "Chart watchlist display.

\\{chartprog-watchlist-map}
On a colour screen, face `chartprog-up' and face `chartprog-down' show
each line in green or red according to whether the last trade was
higher or lower than the previous close (ie. the change column
positive or negative).  Face `chartprog-in-progress' shows blue while
quotes are being downloaded.

Stock name and quote/last-trade times can be seen in a tooltip by
moving the mouse over each line.  The same can be seen on a text
terminal with `\\[chartprog-watchlist-detail]'."

  (interactive)
  (switch-to-buffer (get-buffer-create "*chartprog-watchlist*"))
  (when (save-excursion
          (goto-char (point-min))
          (or (looking-at "Subprocess died")
              (eq (point-min) (point-max))))

    (setq buffer-read-only nil)
    (erase-buffer)
    (insert "\nStarting chart subprocess ...\n")
    (sit-for 0)
    (kill-all-local-variables)
    (use-local-map chartprog-watchlist-map)
    (setq major-mode 'chart-watchlist
          mode-name  "Watchlist"
          truncate-lines t
          buffer-read-only t
          chartprog-watchlist-current-symlist 'favourites
          ;; header-line-format "Symbol       bid/offer     last  change    low    high    volume   when   note"
          )
    (chartprog-header-line-scrolling "Symbol       bid/offer     last  change    low    high    volume   when   note")

    (when (fboundp 'make-local-hook) ;; "obsolete" in emacs21
      (make-local-hook 'kill-buffer-hook)) ;; for xemacs21
    (add-hook 'kill-buffer-hook 'chartprog-process-kill t t)

    (make-local-variable 'window-scroll-functions)
    (chartprog-exec 'get-symlist chartprog-watchlist-current-symlist)
    (chartprog-exec 'request-symlist chartprog-watchlist-current-symlist)
    (chartprog-exec 'get-symlist-alist)
    (run-hooks 'chartprog-watchlist-hook)))


;;-----------------------------------------------------------------------------
;; quotes

;; `thing-at-point' setups
;; chart-symbol is alphanumerics plus .,^- and ending in an alphanumeric
;; note no [:alnum:] in xemacs 21
(put 'chart-symbol 'beginning-op
     (lambda ()
       (if (re-search-backward "[^A-Za-z0-9.,^-]" nil t)
           (forward-char)
         (goto-char (point-min)))))
(put 'chart-symbol 'end-op
     (lambda ()
       (unless (re-search-forward "\\=[A-Za-z0-9.,^-]*[A-Za-z0-9]" nil t)
         (goto-char (point-max)))))
(put 'chart-symbol 'thing-at-point
     (lambda ()
       (let ((bounds (bounds-of-thing-at-point 'chart-symbol)))
         (and bounds
              (let ((str (buffer-substring (car bounds) (cdr bounds))))
                ;; suffix in upper case, yahoo reuters news often has lower
                (if (string-match "\\(.*\\)\\([.][^.]*\\)" str)
                    (setq str (concat (match-string 1 str)
                                      (upcase (match-string 2 str)))))
                ;; leading "." assumed to be "^", often seen in yahoo reuters
                (if (string-match "^\\." str)
                    (setq str (concat "^" (substring str 1))))
                str)))))

;;;###autoload
(defun chart-quote (symbol)
  "Show a quote in the message area for the Chart stock SYMBOL.
Interactively SYMBOL is read from the minibuffer, the default is the symbol
at point in the current buffer."
  (interactive (list (chartprog-completing-read-symbol (thing-at-point
                                                        'chart-symbol))))
  (message "Fetching ...")
  (let ((elem (chartprog-exec-synchronous 'quote-one symbol)))
    (message "%s" (propertize (second elem) 'face (third elem)))))

;;;###autoload
(defun chart-quote-at-point ()
  "Show a quote in the message area for the Chart stock symbol at point."
  (interactive)
  (chart-quote (thing-at-point 'chart-symbol)))


;;-----------------------------------------------------------------------------
;; latest from elisp

(defvar chartprog-latest-record-calls nil)

(defvar chartprog-latest-cache
  (make-hash-table :test 'equal :weakness 'value)
  "Hash table, key is a chart symbol (a string), value is a latest record.")

;;;###autoload
(defun chart-latest (symbol &optional field scale)
  "Return the latest price for SYMBOL (a string) from Chart.
If there's no information available (an unknown stock, not online and
nothing cached, or whatever) the return is nil.

FIELD is a symbol (a Lisp symbol) for what data to return.  The default is
`last' which is the last price, other possibilities are: name, bid, offer,
open, high, low, change, volume, decimals, note.  Which fields actually have
data depends on the data source.

SCALE is a power of 10 to apply to prices.  For example if SCALE is 2 then a
price 1.23 is returned as 123.  This can be useful for instance if you want
to work in cents but quotes are in dollars.  The default is 0, for no
scaling.

FIELD `decimals' is how many decimal places Chart is using for prices
internally.  Internally prices are kept as an integer and count of decimals.
Using this value for SCALE will ensure an integer return.

FIELD `name' is the stock or commodity name as a string, or nil.  FIELD
`note' is a string with extra notes, like ex-dividend or limit up, or
nil."

  (unless (stringp symbol)
    (error "Not a chart symbol (should be a string)"))
  (if chartprog-latest-record-calls
      (push symbol (aref chartprog-latest-record-calls 0)))
  (unless field
    (setq field 'last))
  (let ((latest (gethash symbol chartprog-latest-cache)))
    (when (or (not latest)
              (plist-get latest 'dirty))
      (setq latest (chartprog-exec-synchronous 'get-latest-record symbol))
      (puthash symbol latest chartprog-latest-cache))

    (let ((value (plist-get latest field)))
      (when (and value
                 (memq field '(bid offer open high low last change)))
        (let ((factor (- (or scale 0) (plist-get latest 'decimals))))
          (if (/= 0 factor)
              (setq value (* value (expt (if (< factor 0) 10.0 10)
                                         factor))))))
      value)))
(put 'chart-latest 'safe-function t)


;;-----------------------------------------------------------------------------
;; ses.el additions

;;;###autoload
(defun chart-ses-refresh ()
  "Refresh Chart prices in a SES spreadsheet.
`ses-recalculate-all' is run first to find what `chartprog-latest' prices are
required, then it's run again after downloading new data for those.

If the second recalculate uses prices for further symbols (perhaps through
tricky conditionals), then those are downloaded and the recalculate done
again.  This is repeated until all prices used have been downloaded."

  (interactive)
  (let ((chartprog-latest-record-calls (vector nil))
        fetched)
    (while
        (progn
          (ses-recalculate-all)
          (let ((more (set-difference (aref chartprog-latest-record-calls 0)
                                      fetched)))
            (and more
                 (progn
                   (chartprog-with-temp-message "Downloading quotes ..."
                     (chartprog-exec-synchronous 'request-symbols-synchronous
                                                 more))
                   (setq fetched (nconc more fetched))
                   t)))))))


;;-----------------------------------------------------------------------------

;; LocalWords: Customizations eg ie watchlist symlist symlists initializing
;; LocalWords: hscrolled hscrolling UTF minibuffer tooltip cl synchronize
;; LocalWords: col init

(provide 'chartprog)

;;; chartprog.el ends here
