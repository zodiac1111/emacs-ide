;;; eide-popup.el --- Emacs-IDE, popup

;; Copyright (C) 2005-2009 Cédric Marie

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(provide 'eide-popup)

(defvar eide-popup-menu nil)
(defvar eide-popup-menu-actions-list nil)
(defvar eide-popup-menu-separator-flag nil)

(setq eide-confirm-dialog
      '(("yes" . "y")
        ("no"  . "n")))

(setq eide-message-dialog
      '(("continue" . "c")))


;;;; ==========================================================================
;;;; INTERNAL FUNCTIONS
;;;; ==========================================================================

;; ----------------------------------------------------------------------------
;; Initialize a popup menu.
;;
;; output : eide-popup-menu : empty menu.
;;          eide-popup-menu-actions-list : empty actions list.
;; ----------------------------------------------------------------------------
(defun eide-l-popup-menu-init ()
  (setq eide-popup-menu nil)
  (setq eide-popup-menu-actions-list nil)
  (if (not eide-option-menu-buffer-popup-groups-flags)
    (setq eide-popup-menu-separator-flag nil)))

;; ----------------------------------------------------------------------------
;; Add an action in action list (for popup menu).
;;
;; input  : p-action-name : action name in menu.
;;          p-action-function : action function.
;;          p-enabled-flag : t if this action is enabled.
;;          eide-popup-menu-actions-list : actions list.
;; output : eide-popup-menu-actions-list : updated actions list.
;; ----------------------------------------------------------------------------
(defun eide-l-popup-menu-add-action (p-action-name p-action-function p-enabled-flag)
  (if (> (length p-action-name) 120)
    (setq p-action-name (concat (substring p-action-name 0 120) " [...]")))
  (if p-enabled-flag
    (setq eide-popup-menu-actions-list (append (list (cons p-action-name p-action-function)) eide-popup-menu-actions-list))
    (setq eide-popup-menu-actions-list (append (list p-action-name) eide-popup-menu-actions-list))))

;; ----------------------------------------------------------------------------
;; Add action list to popup menu.
;;
;; input  : p-actions-list-name : name of actions list.
;;          eide-popup-menu : popup menu.
;;          eide-popup-menu-actions-list : actions list.
;; output : eide-popup-menu : updated popup menu.
;;          eide-popup-menu-actions-list : empty actions list.
;; ----------------------------------------------------------------------------
(defun eide-l-popup-menu-close-action-list (p-actions-list-name)
  (if eide-popup-menu-actions-list
    (if eide-option-menu-buffer-popup-groups-flags
      (setq eide-popup-menu (append (list (cons p-actions-list-name eide-popup-menu-actions-list)) eide-popup-menu))
      (progn
        (if eide-popup-menu-separator-flag
          (setq eide-popup-menu (append (list (cons "-" "-")) eide-popup-menu))
          ;;(setq eide-popup-menu (append (append (list (cons "-" "-")) eide-popup-menu-actions-list) eide-popup-menu))
          (setq eide-popup-menu-separator-flag t))
        (setq eide-popup-menu (append eide-popup-menu-actions-list eide-popup-menu)))))
  (setq eide-popup-menu-actions-list nil))

;; ----------------------------------------------------------------------------
;; Open popup menu.
;;
;; input  : p-menu-title : title of popup menu.
;;          eide-popup-menu : popup menu.
;; ----------------------------------------------------------------------------
(defun eide-l-popup-menu-open (p-menu-title)
  (if eide-popup-menu
    (progn
      (setq eide-popup-menu (reverse eide-popup-menu))

      (if (not eide-option-menu-buffer-popup-groups-flags)
        (setq eide-popup-menu (list (cons "single group" eide-popup-menu))))

      (setq l-result (x-popup-menu t (cons p-menu-title eide-popup-menu)))
      (if (bufferp l-result)
        (switch-to-buffer l-result)
        (eval (car (read-from-string l-result)))))))

;; ----------------------------------------------------------------------------
;; Open popup menu with the list of other projects.
;;
;; input  : eide-compare-other-projects-list : other projects list.
;; ----------------------------------------------------------------------------
(defun eide-l-popup-open-menu-for-another-project ()
  (eide-compare-build-other-projects-list)
  (if eide-compare-other-projects-list
    (progn
      (eide-l-popup-menu-init)
      (dolist (l-project eide-compare-other-projects-list)
        (eide-l-popup-menu-add-action (car l-project) (concat "(eide-compare-select-another-project \"" (car l-project) "\" \"" (cdr l-project) "\")") t))
      (eide-l-popup-menu-close-action-list "Other projects")
      (eide-l-popup-menu-open "Select another project :"))
    ;; eide-root-directory                             : <...>/current_project/
    ;; directory-file-name removes last "/"            : <...>/current_project
    ;; file-name-directory removes last directory name : <...>/
    (eide-popup-message (concat "There is no other project in " (file-name-directory (directory-file-name eide-root-directory))))))


;;;; ==========================================================================
;;;; FUNCTIONS
;;;; ==========================================================================

;; ----------------------------------------------------------------------------
;; Prompt for a confirmation.
;;
;; input  : p-string : question to be answered yes or no.
;; return : t = "yes", nil = "no".
;; ----------------------------------------------------------------------------
(defun eide-popup-question-yes-or-no-p (p-string)
  ;;(yes-or-no-p p-string))
  (string-equal (x-popup-dialog t (cons p-string eide-confirm-dialog)) "y"))

;; ----------------------------------------------------------------------------
;; Display a message.
;;
;; input  : p-string : message.
;; ----------------------------------------------------------------------------
(defun eide-popup-message (p-string)
  (x-popup-dialog t (cons p-string eide-message-dialog)))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to project.
;;
;; input  : eide-project-name : project name.
;;          eide-compare-other-project-name : other project name (for
;;              comparison).
;;          eide-root-directory : project root directory.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu ()
  (let ((popup-header ""))
    (eide-l-popup-menu-init)
    (if eide-project-name
      ;; Project already created
      (progn
        (eide-l-popup-menu-add-action (concat "Compile (1) : " (eide-project-get-full-command "compile_command_1")) "(eide-project-compile-1)" t)
        (eide-l-popup-menu-add-action (concat "Compile (2) : " (eide-project-get-full-command "compile_command_2")) "(eide-project-compile-2)" t)
        (eide-l-popup-menu-add-action (concat "Run (1) : " (eide-project-get-full-command "run_command_1")) "(eide-project-run-1)" t)
        (eide-l-popup-menu-add-action (concat "Run (2) : " (eide-project-get-full-command "run_command_2")) "(eide-project-run-2)" t)
        (eide-l-popup-menu-add-action (concat "Debug (1) : " (eide-config-get-project-value "debug_command_1")) "(eide-project-debug-1)" t)
        (eide-l-popup-menu-add-action (concat "Debug (2) : " (eide-config-get-project-value "debug_command_2")) "(eide-project-debug-2)" t)
        (eide-l-popup-menu-close-action-list "Execute")
        (if eide-option-use-cscope-flag
          (eide-l-popup-menu-add-action "Update cscope list of files" "(eide-project-update-cscope-list-of-files)" t))
        (if (or (not eide-option-use-cscope-flag) eide-option-use-cscope-and-tags-flag)
          (eide-l-popup-menu-add-action "Update tags" "(eide-project-update-tags)" t))
        (eide-l-popup-menu-close-action-list "Update")
        (if eide-compare-other-project-name
          (eide-l-popup-menu-add-action (concat "Select another project for comparison (current : \"" eide-compare-other-project-name "\")") "(eide-l-popup-open-menu-for-another-project)" t)
          (eide-l-popup-menu-add-action "Select another project for comparison" "(eide-l-popup-open-menu-for-another-project)" t))
        (eide-l-popup-menu-close-action-list "Projects comparison")
        (eide-l-popup-menu-add-action "Project configuration" "(eide-config-open-project-file)" t)
        (eide-l-popup-menu-add-action "Project notes" "(eide-config-open-project-notes-file)" t)
        (eide-l-popup-menu-close-action-list "Configuration")
        (eide-l-popup-menu-add-action "Delete project" "(eide-project-delete)" t)
        (eide-l-popup-menu-close-action-list "Destroy")
        (setq popup-header (concat "Project : " eide-project-name)))
      ;; Project not created yet
      (progn
        (eide-l-popup-menu-add-action "Create project" "(eide-project-create)" t)
        (eide-l-popup-menu-close-action-list "Create")
        (setq popup-header (concat "Root directory : " eide-root-directory))))

    (eide-l-popup-menu-add-action "Options" "(eide-config-open-options-file)" t)
    (eide-l-popup-menu-close-action-list "User config")

    (eide-l-popup-menu-add-action "Help" "(eide-help-open)" t)
    (eide-l-popup-menu-close-action-list "Help")

    (eide-l-popup-menu-open popup-header)))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to selected directory.
;;
;; input  : eide-menu-files-list : list of opened files.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-directory ()
  (interactive)
  (eide-windows-select-window-menu)
  (move-to-window-line (cdr (last (mouse-position))))

  (let ((l-directory-name-in-title (eide-menu-get-directory-name-on-current-line)) (l-directory-name nil))
    (setq l-directory-name (if (string-equal l-directory-name-in-title "./")
                             ""
                             l-directory-name-in-title))
    (eide-l-popup-menu-init)
    (eide-l-popup-menu-add-action "Close all files from this directory" (concat "(eide-menu-directory-close \"" l-directory-name "\")") t)

    (let ((l-buffer-read-only-flag nil) (l-buffer-read-write-flag nil) (l-buffer-status-none-flag nil) (l-buffer-status-new-flag nil) (l-buffer-status-ref-flag nil))
      ;; Parse list of opened buffers, and find the ones located in this
      ;; directory, to check, for every possible property (read only, REF file,
      ;; ...) if at least one of them matches.
      (dolist (l-buffer eide-menu-files-list)
        (if (eide-menu-is-file-in-directory-p l-buffer l-directory-name)
          ;; The buffer is located in the directory
          (save-excursion
            (set-buffer l-buffer)
            ;; Check all properties
            (if buffer-read-only
              (setq l-buffer-read-only-flag t)
              (setq l-buffer-read-write-flag t))
            (let ((l-buffer-status (eide-edit-get-buffer-status)))
              (if (string-equal l-buffer-status "")
                (setq l-buffer-status-none-flag t)
                (if (string-equal l-buffer-status "new")
                  (setq l-buffer-status-new-flag t)
                  (if (string-equal l-buffer-status "ref")
                    (setq l-buffer-status-ref-flag t))))))))
      ;; Actions are enabled only if it can apply to one buffer at least
      (eide-l-popup-menu-add-action "Set all files read/write" (concat "(eide-edit-action-on-directory 'eide-edit-set-rw \"" l-directory-name "\")") l-buffer-read-only-flag)
      (eide-l-popup-menu-add-action "Set all files read only" (concat "(eide-edit-action-on-directory 'eide-edit-set-r \"" l-directory-name "\")") l-buffer-read-write-flag)
      (eide-l-popup-menu-add-action "Backup original files (REF) to work on copies (NEW)" (concat "(eide-edit-action-on-directory 'eide-edit-make-ref-file \"" l-directory-name "\")") l-buffer-status-none-flag)
      (eide-l-popup-menu-add-action "Switch to REF files" (concat "(eide-edit-action-on-directory 'eide-edit-use-ref-file \"" l-directory-name "\")") l-buffer-status-new-flag)
      (eide-l-popup-menu-add-action "Discard REF files" (concat "(eide-edit-action-on-directory 'eide-edit-discard-ref-file \"" l-directory-name "\" \"discard all REF files\")") l-buffer-status-new-flag)
      (eide-l-popup-menu-add-action "Restore REF files" (concat "(eide-edit-action-on-directory 'eide-edit-restore-ref-file \"" l-directory-name "\" \"restore all REF files\")") l-buffer-status-new-flag)
      (eide-l-popup-menu-add-action "Switch to NEW files" (concat "(eide-edit-action-on-directory 'eide-edit-use-new-file \"" l-directory-name "\")") l-buffer-status-ref-flag)
      (eide-l-popup-menu-add-action "Discard NEW files" (concat "(eide-edit-action-on-directory 'eide-edit-discard-new-file \"" l-directory-name "\" \"discard all NEW files\")") l-buffer-status-ref-flag)
      (eide-l-popup-menu-close-action-list "Edit")

      (eide-l-popup-menu-add-action "Untabify and indent all read/write files" (concat "(eide-edit-action-on-directory 'eide-edit-untabify-and-indent \"" l-directory-name "\" \"untabify and indent all read/write files\")") l-buffer-read-write-flag)
      (eide-l-popup-menu-add-action "Delete trailing spaces in all read/write files" (concat "(eide-edit-action-on-directory 'eide-edit-delete-trailing-spaces \"" l-directory-name "\" \"delete trailing spaces in all read/write files\")") l-buffer-read-write-flag)
      (eide-l-popup-menu-add-action "Convert end of line in all read/write files : DOS to UNIX" (concat "(eide-edit-action-on-directory 'eide-edit-dos-to-unix \"" l-directory-name "\" \"convert end of line (DOS to UNIX) in all read/write files\")") l-buffer-read-write-flag)
      (eide-l-popup-menu-add-action "Convert end of line in all read/write files : UNIX to DOS" (concat "(eide-edit-action-on-directory 'eide-edit-unix-to-dos \"" l-directory-name "\" \"convert end of line (UNIX to DOS) in all read/write files\")") l-buffer-read-write-flag)
      (eide-l-popup-menu-close-action-list "Clean"))

    (eide-l-popup-menu-open l-directory-name-in-title)))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to selected file.
;;
;; input  : eide-compare-other-project-name : other project name (for
;;              comparison).
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-file ()
  (interactive)
  (eide-windows-select-window-menu)
  (move-to-window-line (cdr (last (mouse-position))))

  (setq l-buffer (eide-menu-get-buffer-name-on-current-line))
  (eide-l-popup-menu-init)

  (save-excursion
    (set-buffer l-buffer)
    (setq l-buffer-status (eide-edit-get-buffer-status))

    ;; Check buffer status (r/w)
    (if buffer-read-only
      (setq l-buffer-rw-flag nil)
      (setq l-buffer-rw-flag t)))

  (eide-l-popup-menu-add-action "Close" (concat "(eide-menu-file-close \"" l-buffer "\")") t)

  ;; Option "Set read/write"
  (if l-buffer-rw-flag
    (eide-l-popup-menu-add-action "Set read only" (concat "(eide-edit-action-on-file 'eide-edit-set-r \"" l-buffer "\")") t)
    (eide-l-popup-menu-add-action "Set read/write" (concat "(eide-edit-action-on-file 'eide-edit-set-rw \"" l-buffer "\")") t))

  (eide-l-popup-menu-close-action-list "File")

  ;; Option for "edit"
  (if (string-equal l-buffer-status "ref")
    (eide-l-popup-menu-add-action "Switch to NEW file" (concat "(eide-edit-action-on-file 'eide-edit-use-new-file \"" l-buffer "\")") t)
    (if (string-equal l-buffer-status "new")
      (eide-l-popup-menu-add-action "Switch to REF file" (concat "(eide-edit-action-on-file 'eide-edit-use-ref-file \"" l-buffer "\")") t)
      (eide-l-popup-menu-add-action "Backup original file (REF) to work on a copy (NEW)" (concat "(eide-edit-action-on-file 'eide-edit-make-ref-file \"" l-buffer "\")") t)))

  (if (string-equal l-buffer-status "ref")
    (eide-l-popup-menu-add-action "Discard NEW file" (concat "(eide-edit-action-on-file 'eide-edit-discard-new-file \"" l-buffer "\" \"discard NEW file\")") t)
    (if (string-equal l-buffer-status "new")
      (progn
        (eide-l-popup-menu-add-action "Discard REF file" (concat "(eide-edit-action-on-file 'eide-edit-discard-ref-file \"" l-buffer "\" \"discard REF file\")") t)
        (eide-l-popup-menu-add-action "Restore REF file" (concat "(eide-edit-action-on-file 'eide-edit-restore-ref-file \"" l-buffer "\" \"restore REF file\")") t))))

  (eide-l-popup-menu-close-action-list "Edit")

  (eide-l-popup-menu-add-action "Untabify and indent" (concat "(eide-edit-action-on-file 'eide-edit-untabify-and-indent \"" l-buffer "\" \"untabify and indent this file\")") l-buffer-rw-flag)
  (eide-l-popup-menu-add-action "Delete trailing spaces" (concat "(eide-edit-action-on-file 'eide-edit-delete-trailing-spaces \"" l-buffer "\" \"delete trailing spaces\")") l-buffer-rw-flag)

  (eide-l-popup-menu-add-action "Convert end of line : DOS to UNIX" (concat "(eide-edit-action-on-file 'eide-edit-dos-to-unix \"" l-buffer "\" \"convert end of line (DOS to UNIX)\")") l-buffer-rw-flag)
  (eide-l-popup-menu-add-action "Convert end of line : UNIX to DOS" (concat "(eide-edit-action-on-file 'eide-edit-unix-to-dos \"" l-buffer "\" \"convert end of line (UNIX to DOS)\")") l-buffer-rw-flag)

  (eide-l-popup-menu-close-action-list "Clean")

  ;; Option for "compare"
  (if (string-equal l-buffer-status "ref")
    (eide-l-popup-menu-add-action "Compare REF and NEW files" (concat "(eide-compare-with-new-file \"" l-buffer "\")") t)
    (if (string-equal l-buffer-status "new")
      (eide-l-popup-menu-add-action "Compare REF and NEW files" (concat "(eide-compare-with-ref-file \"" l-buffer "\")") t)))

  (if eide-compare-other-project-name
    (eide-l-popup-menu-add-action (concat "Compare with file in project \"" eide-compare-other-project-name "\"") (concat "(eide-compare-with-other-project \"" l-buffer "\")") t))

  (eide-l-popup-menu-close-action-list "Compare")

  (eide-l-popup-menu-open l-buffer))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to "compile" tab.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-compile ()
  (interactive)
  (eide-l-popup-menu-init)
  (eide-l-popup-menu-add-action (concat "Compile (1) : " (eide-project-get-full-command "compile_command_1")) "(eide-project-compile-1)" t)
  (eide-l-popup-menu-add-action (concat "Compile (2) : " (eide-project-get-full-command "compile_command_2")) "(eide-project-compile-2)" t)
  (eide-l-popup-menu-close-action-list "Execute")
  (eide-l-popup-menu-open "Compile"))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to "run" tab.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-run ()
  (interactive)
  (eide-l-popup-menu-init)
  (eide-l-popup-menu-add-action (concat "Run (1) : " (eide-project-get-full-command "run_command_1")) "(eide-project-run-1)" t)
  (eide-l-popup-menu-add-action (concat "Run (2) : " (eide-project-get-full-command "run_command_2")) "(eide-project-run-2)" t)
  (eide-l-popup-menu-close-action-list "Execute")
  (eide-l-popup-menu-open "Run"))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to "debug" tab.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-debug ()
  (interactive)
  (eide-l-popup-menu-init)
  (eide-l-popup-menu-add-action (concat "Debug (1) : " (eide-config-get-project-value "debug_command_1")) "(eide-project-debug-1)" t)
  (eide-l-popup-menu-add-action (concat "Debug (2) : " (eide-config-get-project-value "debug_command_2")) "(eide-project-debug-2)" t)
  (eide-l-popup-menu-close-action-list "Execute")
  (eide-l-popup-menu-open "Debug"))

;; ----------------------------------------------------------------------------
;; Open a popup menu related to "shell" tab.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-shell ()
  (interactive)
  (eide-l-popup-menu-init)
  (eide-l-popup-menu-add-action "Open shell" "(eide-shell-open)" t)
  (eide-l-popup-menu-close-action-list "Execute")
  (eide-l-popup-menu-open "Shell"))

;; ----------------------------------------------------------------------------
;; Open a popup menu to select a buffer to display in window "results".
;;
;; input  : eide-menu-grep-results-list : list of grep results.
;;          eide-menu-cscope-results-list : list of cscope results.
;;          eide-compilation-buffer : compilation buffer name.
;;          eide-execution-buffer : execution buffer name.
;;          eide-debug-buffer : debug buffer name.
;;          eide-shell-buffer : shell buffer name.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-search-results ()
  (eide-l-popup-menu-init)
  (if eide-menu-grep-results-list
    (progn
      (dolist (l-grep-result eide-menu-grep-results-list)
        ;; Protect \ in grep search buffer name
        (setq l-grep-result-parameter (replace-regexp-in-string "\\\\" "\\\\" l-grep-result t t))
        (eide-l-popup-menu-add-action l-grep-result (concat "(eide-search-view-result-buffer \"" l-grep-result-parameter "\")") t))
      (eide-l-popup-menu-close-action-list "Grep results")))
  (if eide-menu-cscope-results-list
    (progn
      (dolist (l-grep-result eide-menu-cscope-results-list)
        (eide-l-popup-menu-add-action l-grep-result (concat "(eide-search-view-result-buffer \"" l-grep-result "\")") t))
      (eide-l-popup-menu-close-action-list "Cscope results")))
  (eide-l-popup-menu-add-action "Compilation" (concat "(eide-search-view-result-buffer \"" eide-compilation-buffer "\")") eide-compilation-buffer)
  (eide-l-popup-menu-add-action "Execution" (concat "(eide-search-view-result-buffer \"" eide-execution-buffer "\")") eide-execution-buffer)
  (eide-l-popup-menu-add-action "Debug" (concat "(eide-search-view-result-buffer \"" eide-debug-buffer "\")") eide-debug-buffer)
  (eide-l-popup-menu-add-action "Shell" (concat "(eide-search-view-result-buffer \"" eide-shell-buffer "\")") eide-shell-buffer)
  (eide-l-popup-menu-close-action-list "Compilation / Execution / Debug / Shell")
  (eide-l-popup-menu-open "Switch to :"))

;; ----------------------------------------------------------------------------
;; Open a popup menu to select a search result to delete.
;;
;; input  : eide-menu-grep-results-list : list of grep results.
;;          eide-menu-cscope-results-list : list of cscope results.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-search-results-delete ()
  (eide-l-popup-menu-init)
  (if eide-menu-grep-results-list
    (progn
      (dolist (l-grep-result eide-menu-grep-results-list)
        ;; Protect \ in grep search buffer name
        (setq l-grep-result-parameter (replace-regexp-in-string "\\\\" "\\\\" l-grep-result t t))
        (eide-l-popup-menu-add-action (concat "Delete " l-grep-result) (concat "(eide-search-close-grep-buffer \"" l-grep-result-parameter "\")") t))
      (if (> (length eide-menu-grep-results-list) 1)
        (eide-l-popup-menu-add-action "Delete all grep results" "(eide-search-close-all-grep-buffers)" t))
      (eide-l-popup-menu-close-action-list "Grep results")))
  (if eide-menu-cscope-results-list
    (progn
      (dolist (l-grep-result eide-menu-cscope-results-list)
        (eide-l-popup-menu-add-action (concat "Delete " l-grep-result) (concat "(eide-search-close-cscope-buffer \"" l-grep-result "\")") t))
      (if (> (length eide-menu-cscope-results-list) 1)
        (eide-l-popup-menu-add-action "Delete all cscope results" "(eide-search-close-all-cscope-buffers)" t))
      (eide-l-popup-menu-close-action-list "Cscope results")))
  (eide-l-popup-menu-open "*** DELETE *** search results"))

;; ----------------------------------------------------------------------------
;; Open a popup menu to search for selected text.
;;
;; input  : eide-project-name : project name.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-search ()
  (eide-l-popup-menu-init)
  (setq string (buffer-substring-no-properties (region-beginning) (region-end)))
  (if eide-project-name
    (progn
      (eide-l-popup-menu-add-action "Go to definition" (concat "(eide-search-find-tag \"" string "\")") t)
      (eide-l-popup-menu-add-action "Find symbol" (concat "(eide-search-find-symbol \"" string "\")") t)
      (eide-l-popup-menu-add-action "Grep in whole project" (concat "(eide-search-grep-find \"" string "\")") t)))
  (eide-l-popup-menu-add-action "Grep in current directory" (concat "(eide-search-grep \"" string "\")") t)
  (eide-l-popup-menu-close-action-list "Search")
  (eide-l-popup-menu-open (concat "Search : " string)))

;; ----------------------------------------------------------------------------
;; Open a popup menu to clean selected lines.
;; ----------------------------------------------------------------------------
(defun eide-popup-open-menu-for-cleaning ()
  (eide-l-popup-menu-init)
  (eide-l-popup-menu-add-action "Untabify" "(progn (untabify (region-beginning) (region-end)) (save-buffer))" t)
  (eide-l-popup-menu-add-action "Indent" "(progn (indent-region (region-beginning) (region-end) nil) (save-buffer))" t)
  (eide-l-popup-menu-close-action-list "Cleaning")
  (eide-l-popup-menu-open "Clean selection"))

;;; eide-popup.el ends here