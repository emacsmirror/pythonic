;;; pythonic.el --- Utility functions for writing pythonic emacs package.

;; Copyright (C) 2015 by Artem Malyshev

;; Author: Artem Malyshev <proofit404@gmail.com>
;; URL: https://github.com/proofit404/pythonic
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (f "0.17.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See the README for more details.

;;; Code:

(require 'python)
(require 'tramp)
(require 'dash)
(require 'f)

(defvaralias 'pythonic-env
  (if (boundp 'python-shell-virtualenv-root)
      'python-shell-virtualenv-root
    'python-shell-virtualenv-path)
  "Alias to `python.el' virtualenv variable.")

(defun pythonic-remote-p ()
  "Determine remote or local virtual environment."
  (if pythonic-env
      (tramp-tramp-file-p pythonic-env)
    (tramp-tramp-file-p python-shell-interpreter)))

(defun pythonic-file-name (file)
  "Normalized FILE location with out tramp prefix."
  (if (tramp-tramp-file-p file)
      (tramp-file-name-localname
       (tramp-dissect-file-name file))
    file))

(defun pythonic-executable ()
  "Python executable."
  (let* ((windowsp (eq system-type 'windows-nt))
         (python (if windowsp "pythonw" "python"))
         (bin (if windowsp "Scripts" "bin")))
    (if pythonic-env
        (f-join (pythonic-file-name pythonic-env) bin python)
      (pythonic-file-name python-shell-interpreter))))

(defun pythonic-command ()
  "Get command name to start python process."
  (if (pythonic-remote-p)
      "ssh"
    (pythonic-executable)))

(defun pythonic-args (&rest args)
  "Get python process ARGS."
  (if (pythonic-remote-p)
      (let (remote-args)
        (when python-shell-extra-pythonpaths
          (add-to-list 'remote-args "env" t)
          (add-to-list 'remote-args
                       (format "PYTHONPATH=%s"
                               (s-join ":" python-shell-extra-pythonpaths))
                       t))
        (add-to-list 'remote-args (pythonic-executable) t)
        (append remote-args args))
    args))

(defun pythonic-default-directory (from-directory)
  "Generate `default-directory' FROM-DIRECTORY."
  (or from-directory "~"))

(cl-defun call-pythonic (&key file buffer display args cwd)
  "Pythonic wrapper around `call-process'.

FILE is the input file. BUFFER is the output destination. DISPLAY
specifies to redisplay BUFFER on new output. ARGS is the list of
arguments passed to `call-process'. CWD will be working directory
for running process."
  (let ((default-directory (pythonic-default-directory cwd)))
    (apply 'process-file
           (pythonic-command)
           file
           buffer
           display
           (apply 'pythonic-args args))))

(cl-defun start-pythonic (&key process buffer args cwd)
  "Pythonic wrapper around `start-process'.

PROCESS is a name of the created process. BUFFER is a output
destination. ARGS are the list of args passed to
`start-process'. CWD will be working directory for running
process."
  (let ((default-directory (pythonic-default-directory cwd)))
    (apply 'start-file-process
           process
           buffer
           (pythonic-command)
           (apply 'pythonic-args args))))

;;;###autoload
(defun pythonic-activate (virtualenv)
  "Activate python VIRTUALENV."
  (interactive "DEnv: ")
  (setq pythonic-env virtualenv))

;;;###autoload
(defun pythonic-deactivate ()
  "Deactivate python virtual environment."
  (interactive)
  (setq pythonic-env nil))

(provide 'pythonic)

;;; pythonic.el ends here
