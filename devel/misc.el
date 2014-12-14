;; Copyright 2014 Kevin Ryde

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


(progn
  (chartprog-exec 'request-explicit '("BHP.AX"))
  (chart-quote "BHP.AX"))

(chart-ses-refresh-download '("BHP.AX" "CBA.AX"))
(chart-ses-refresh-download '("NAB.AX"))

;;-----------------------------------------------------------------------------

(progn
  (setq chartprog-debug t)
  (save-selected-window
    (save-excursion
      (switch-to-buffer-other-window "*chartprog-debug*"))))

;;-----------------------------------------------------------------------------
(let (lst)
  (chart-latest "BHP.AX" 'last 2)
  (maphash (lambda (key value)
             (push (list key value) lst))
           chartprog-latest-cache)
  lst)


;;-----------------------------------------------------------------------------

(easy-menu-define my-pop SYMBOL MAPS DOC MENU)


;;-----------------------------------------------------------------------------
;; after-change-functions save-match-data

(add-to-list 'mode-line-misc-info '(:eval (my-mode-line-bit)))
(defun my-mode-line-bit ()
  "abc")
(progn
  (looking-at "..")
  (force-mode-line-update)
  (match-data))


;;-----------------------------------------------------------------------------

(let ((completion-ignore-case t))
  (completing-read "Symlist: "
                   '(("All") ("Alerts"))
                   nil  ;; pred
                   t    ;; require-match
                   nil  ;; initial-input
                   ))

;;-----------------------------------------------------------------------------
(chartprog-symlist-editable-p 'favourites)
(chartprog-symlist-editable-p 'alerts)

(require 'chartprog)
(chartprog-completing-read-symlist)

;;-----------------------------------------------------------------------------

(progn
  (add-to-list 'load-path (expand-file-name "."))
  (require 'my-byte-compile)
  (my-byte-compile "../emacs/chartprog.el"))
(progn
  (add-to-list 'load-path (expand-file-name "."))
  (require 'my-byte-compile)
  (my-show-autoloads))


;;-----------------------------------------------------------------------------

;; ;; emacs has `compare-strings' to do this, but xemacs doesn't
;; (defun chartprog-string-prefix-ci-p (part str)
;;   "Return t if PART is a prefix of STR, case insensitive."
;;   (and (>= (length str) (length part))
;;        (string-equal (upcase part)
;;                      (upcase (substring str 0 (length part))))))

;; ;; "completing-read with require-match will return with just a prefix
;; ;; of one or more names, use the first."  FIXME: Is this true?  Or was
;; ;; true in the past?
;; (dolist (elem (reverse (chartprog-symlist-alist)))
;;   (if (chartprog-string-prefix-ci-p name (car elem))
;;       (setq key (cadr elem))))
;; (or key (error "Oops, symlist name %S not found" name))
;; key)))

;;-----------------------------------------------------------------------------
