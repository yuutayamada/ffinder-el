;;; ffinder.el --- Function finder -*- lexical-binding: t; -*-

;; Copyright (C) 2015 by Yuta Yamada

;; Author: Yuta Yamada <cokesboy"at"gmail.com>
;; URL: https://github.com/yuutayamada/ffinder-el
;; Version: 0.0.1
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: find function

;;; License:
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; Commentary:

;;; Code:
(require 'cl-lib)

(defvar ffinder-functions '((go-mode . godef-jump)
                            ;; You may need "cabal install hasktags"
                            ;; https://github.com/haskell/haskell-mode/wiki/Haskell-Interactive-Mode-Tags
                            (haskell-mode . haskell-mode-jump-to-def-or-tag)
                            (c-mode . ggtags-find-tag-dwim)
                            (c++-mode . ggtags-find-tag-dwim)
                            (arduino-mode . ggtags-find-tag-dwim)
                            (emacs-lisp-mode . xref-find-definitions)))

(defvar ffinder-data-stack '())

;;;###autoload
(defun ffinder-jump ()
  "Jump to definition of function."
  (interactive)
  (let ((func (assoc-default major-mode ffinder-functions)))
    (if (null func)
        (error "Jump function not found")
      (ffinder-add-property `((,(buffer-name) . ,(point))))
      (cl-case func
        ((xref-find-definitions ggtags-find-tag-dwim)
         (funcall func (thing-at-point 'symbol)))
        (t (call-interactively func))))))

(defun ffinder-add-property (prop)
  "Add PROP as data of buffer name and cursor point."
  (if (null (assoc-default major-mode ffinder-data-stack))
      (setq ffinder-data-stack `((,major-mode . ,prop)))
    (cl-loop for (mode . data) in ffinder-data-stack
             if (eq major-mode mode)
             collect (cons major-mode (append prop data)) into resent
             else collect (list mode data) into rest-of-data
             finally (setq ffinder-data-stack (append resent rest-of-data)))))

;;;###autoload
(defun ffinder-jump-to-begging ()
  "Jump to the first place and reset data stack."
  (interactive)
  (let ((data (last (or (assoc-default major-mode ffinder-data-stack)
                        (cdar ffinder-data-stack)))))
    (cl-destructuring-bind ((file . point)) data
      (let ((buffer (get-buffer file)))
        (when (bufferp buffer)
          (switch-to-buffer buffer)
          (ffinder-clear-data-stack))))))

(defun ffinder-clear-data-stack (&optional mode)
  "Clear data stack.  You can specify specific major MODE."
  (cl-loop for data in ffinder-data-stack
           unless (eq (or mode major-mode) (car data))
           collect data into stack
           finally (setq ffinder-data-stack stack)))

(provide 'ffinder)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; ffinder.el ends here
