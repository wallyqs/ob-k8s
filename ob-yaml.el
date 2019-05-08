;;; ob-yaml.el --- org-babel functions for Kubernetes YAML evaluation

;; Copyright (C) 2019 Waldemar Quevedo
;; Author: Waldemar Quevedo, based on ob-ruby and ob-java by Eric Schulte

;; This file is not part of GNU Emacs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org Babel support for evaluating Kubernetes YAML.

;;; Code:

(require 'ob)
(eval-when-compile (require 'cl))

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("yaml" . "yml"))

(defvar org-babel-default-header-args:k8s '())

(defcustom org-babel-k8s-hline-to "nil"
  "Replace hlines in incoming tables with this when translating to racket."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'string)

(defcustom org-babel-k8s-nil-to 'hline
  "Replace 'nil' in racket tables with this before returning."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defvar org-babel-k8s-command "kubectl"
  "Name of command to use for executing racket code.")

(defun org-babel-execute:yaml (body params)
  "Execute a block of Kubernetes YAML code with Babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((result-params (cdr (assoc :result-params params)))
         (result-type   (cdr (assoc :result-type params)))
         (src-file (org-babel-temp-file "k8s-"))
         (result (progn (with-temp-file src-file (insert body))
                        (org-babel-eval
                         (concat org-babel-k8s-command " apply -f " src-file) ""))))

    (org-babel-reassemble-table
     (org-babel-result-cond result-params
       result
       (org-babel-k8s-table-or-string result))
     (org-babel-pick-name (cdr (assoc :colname-names params))
                          (cdr (assoc :colnames params)))
     (org-babel-pick-name (cdr (assoc :rowname-names params))
                          (cdr (assoc :rownames params))))))

(defun org-babel-k8s-table-or-string (results)
  "Convert RESULTS into an appropriate elisp value.
If RESULTS look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (let ((res (org-babel-script-escape results)))
    (if (listp res)
        (mapcar (lambda (el) (if (equal el 'nil)
                            org-babel-racket-nil-to el))
                res)
      res)))

(provide 'ob-yaml)

;;; ob-yaml.el ends here
