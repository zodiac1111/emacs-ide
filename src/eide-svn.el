;;; eide-svn.el --- Emacs-IDE, svn

;; Copyright (C) 2008-2012 Cédric Marie

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(provide 'eide-svn)

(require 'vc)

(defvar eide-svn-diff-full-command nil)

;;;; ==========================================================================
;;;; FUNCTIONS
;;;; ==========================================================================

;; ----------------------------------------------------------------------------
;; Check if current buffer is modified compared to svn repository.
;;
;; return : t or nil.
;; ----------------------------------------------------------------------------
(defun eide-svn-is-current-buffer-modified-p ()
  (if eide-config-show-svn-status-flag
    (if (and (file-exists-p buffer-file-name) (vc-svn-registered buffer-file-name))
      (let ((l-vc-backend (vc-backend buffer-file-name)) (l-state nil))
        ;; Temporary switch to SVN backend (in case the file is under several version control systems)
        (vc-switch-backend buffer-file-name 'SVN)
        ;; NB: vc-state doesn't use selected backend, vc-workfile-unchanged-p does!
        (setq l-state (not (vc-workfile-unchanged-p buffer-file-name)))
        ;; Switch back to previous backend
        (vc-switch-backend buffer-file-name l-vc-backend)
        l-state)
      nil)
    nil))

;; ----------------------------------------------------------------------------
;; Update buffers svn status (modified or not).
;;
;; input  : p-files-list : list of files to update (overrides
;;              eide-menu-files-list).
;;          eide-menu-files-list : list of open files.
;; ----------------------------------------------------------------------------
(defun eide-svn-update-files-status (&optional p-files-list)
  (if eide-config-show-svn-status-flag
    (save-excursion
      (let ((l-files-list nil))
        (if p-files-list
          (setq l-files-list p-files-list)
          (setq l-files-list eide-menu-files-list))
        (dolist (l-buffer-name l-files-list)
          (set-buffer l-buffer-name)
          (make-local-variable 'eide-menu-local-svn-modified-status-flag)
          (setq eide-menu-local-svn-modified-status-flag (eide-svn-is-current-buffer-modified-p)))))))

;; ----------------------------------------------------------------------------
;; Set svn diff command.
;;
;; input  : p-cmd : diff program.
;; output : eide-svn-diff-full-command : svn diff command.
;; ----------------------------------------------------------------------------
(defun eide-svn-set-diff-command (p-cmd)
  (if (string-equal p-cmd "")
    (setq eide-svn-diff-full-command nil)
    (setq eide-svn-diff-full-command (concat "svn diff --diff-cmd=" p-cmd " "))))

;; ----------------------------------------------------------------------------
;; Execute "svn diff" on current buffer.
;; ----------------------------------------------------------------------------
(defun eide-svn-diff ()
  (if (and eide-config-show-svn-status-flag eide-menu-local-svn-modified-status-flag)
    (if eide-svn-diff-full-command
      (shell-command (concat eide-svn-diff-full-command buffer-file-name))
      (let ((l-vc-backend (vc-backend buffer-file-name)))
        ;; Temporary switch to SVN backend (in case the file is under several version control systems)
        (vc-switch-backend buffer-file-name 'SVN)
        (save-excursion
          ;; svn diff
          (vc-diff nil))
        ;; Switch back to previous backend
        (vc-switch-backend buffer-file-name l-vc-backend)))))

;; ----------------------------------------------------------------------------
;; Execute "svn diff" on a directory.
;;
;; input  : p-directory-name : directory name.
;;          p-files-list-string : string containing files list.
;; ----------------------------------------------------------------------------
(defun eide-svn-diff-files-in-directory (p-directory-name p-files-list-string)
  (if eide-config-show-svn-status-flag
    (let ((l-full-directory-name nil))
      (if (string-match "^/" p-directory-name)
        (setq l-full-directory-name p-directory-name)
        (setq l-full-directory-name (concat eide-root-directory p-directory-name)))
      (if eide-svn-diff-full-command
        (shell-command (concat "cd " l-full-directory-name " && " eide-svn-diff-full-command p-files-list-string))
        (shell-command (concat "cd " l-full-directory-name " && svn diff " p-files-list-string))))))

;; ----------------------------------------------------------------------------
;; Execute "svn blame" on current buffer.
;; ----------------------------------------------------------------------------
(defun eide-svn-blame ()
  (if eide-config-show-svn-status-flag
    (let ((l-vc-backend (vc-backend buffer-file-name)))
      ;; Temporary switch to SVN backend (in case the file is under several version control systems)
      (vc-switch-backend buffer-file-name 'SVN)
      (save-excursion
        ;; svn blame
        (vc-annotate buffer-file-name (vc-working-revision buffer-file-name)))
      ;; Switch back to previous backend
      (vc-switch-backend buffer-file-name l-vc-backend))))

;; ----------------------------------------------------------------------------
;; Execute "svn revert" on current buffer.
;; ----------------------------------------------------------------------------
(defun eide-svn-revert ()
  (if (and eide-config-show-svn-status-flag eide-menu-local-svn-modified-status-flag)
    (let ((l-vc-backend (vc-backend buffer-file-name)))
      ;; Temporary switch to SVN backend (in case the file is under several version control systems)
      (vc-switch-backend buffer-file-name 'SVN)
      (save-excursion
        ;; svn revert
        (vc-revert-file buffer-file-name))
      ;; Switch back to previous backend
      (vc-switch-backend buffer-file-name l-vc-backend))))

;;; eide-svn.el ends here
