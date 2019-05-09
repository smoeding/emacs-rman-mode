;;; rman-mode.el --- RMAN scripts mode -*- lexical-binding: t; -*-
;;
;; Filename:    rman-mode.el
;; Description: A major mode to edit Oracle RMAN scripts
;; Author:      Stefan Möding
;; Maintainer:  Stefan Möding
;; Version:     1.0
;; Time-stamp:  <2019-05-09 13:41:44 stm>
;; Keywords:    Oracle, RMAN
;;
;; Copyright (c) 2019 Stefan Möding
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above
;;    copyright notice, this list of conditions and the following
;;    disclaimer in the documentation and/or other materials provided
;;    with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
;; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR
;; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
;; USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
;; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
;; OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;; 2019-05-05 stm
;;     Initial version.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Provides font-locking, indentation support for RMAN scripts.
;;
;; If you're installing manually, you should add this to your .emacs
;; file after putting it on your load path:
;;
;;    (autoload 'rman-mode "rman-mode" "Major mode for RMAN files" t)
;;    (add-to-list 'auto-mode-alist '("\\.rman\\'" . rman-mode))
;;
;;; Code:

(require 'rx)

;;
;; customization
;;

(defgroup rman nil
  "Major mode for editing RMAN files."
  :prefix "rman-"
  :group 'languages)

(defcustom rman-indent-level 2
  "Indentation of RMAN statements with respect to containing block."
  :type 'integer
  :group 'rman)


;;
;; mode map
;;

(defvar rman-mode-map
  (let ((map (make-keymap)))
    map)
  "Keymap for `rman-mode'.")


;;
;; syntax table
;;

(defvar rman-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?# "<"     st)
    (modify-syntax-entry ?\n ">"    st)
    (modify-syntax-entry ?\' "\"'"  st)
    (modify-syntax-entry ?\" "\"\"" st)
    st)
  "Syntax table for `rman-mode'.")


;;
;; commands & keywords used by font-lock and indentation
;;

(defconst rman-commands-regexp
  (regexp-opt '("advise" "allocate" "backup" "catalog" "change"
                "configure" "connect" "convert" "create" "crosscheck"
                "delete" "describe" "drop" "duplicate" "execute" "exit"
                "flashback" "grant" "host" "import" "list" "print"
                "quit" "recover" "register" "release" "repair" "replace"
                "report" "reset" "restore" "resync" "revoke" "rman"
                "run" "send" "set" "show" "shutdown" "spool" "sql"
                "startup" "switch" "transport" "unregister" "upgrade"
                "validate")
              'words)
  "Command keywords used in `rman-mode'.")

(defconst rman-keywords-regexp
  (regexp-opt '("abort" "accessible" "active" "advise" "adviseid"
                "aes128" "aes192" "aes256" "affinity" "after"
                "algorithm" "all" "allocate" "allow" "alter" "and"
                "append" "applied" "archivelog" "area" "as" "at" "atall"
                "autobackup" "autolocate" "auxiliary" "auxname"
                "available" "backed" "backup" "backuppiece" "backups"
                "backupset" "before" "between" "block" "blockrecover"
                "blocks" "by" "cancel" "catalog" "change" "channel"
                "check" "checksyntax" "clear" "clone" "clonename"
                "clone_cf" "closed" "cmdfile" "command" "comment"
                "compatible" "completed" "compressed" "compression"
                "configure" "connect" "consistent" "controlfile"
                "controlfilecopy" "convert" "copies" "copy" "corruption"
                "create" "critical" "crosscheck" "cumulative" "current"
                "database" "datafile" "datafilecopy" "datapump" "days"
                "dba" "dbid" "db_file_name_convert" "db_name"
                "db_recovery_file_dest" "db_unique_name" "debug"
                "decryption" "default" "define" "delete" "deletion"
                "destination" "detail" "device" "directory" "disk"
                "diskratio" "display" "dorecover" "drop" "dump" "duplex"
                "duplicate" "duration" "echo" "encryption" "exclude"
                "execute" "exit" "expired" "export" "failover" "failure"
                "files" "files" "filesperset" "final" "flashback" "for"
                "force" "foreign" "forever" "format" "from" "full" "get"
                "global" "grant" "group" "guarantee" "header" "high"
                "high" "host" "id" "identified" "identifier" "immediate"
                "import" "inaccessible" "incarnation" "include"
                "including" "incremental" "input" "instance" "io" "job"
                "kbytes" "keep" "krb" "level" "libparm" "library" "like"
                "limit" "list" "load" "log" "logfile" "logical" "logs"
                "logscn" "logseq" "low" "maintenance" "mask"
                "maxcorrupt" "maxdays" "maxopenfiles" "maxpiecesize"
                "maxseq" "maxsetsize" "maxsize" "method" "minimize"
                "misc" "mount" "msglog" "msgno" "name" "names" "need"
                "new" "new-line" "newname" "no" "nocatalog" "nocfau"
                "nochecksum" "nodevals" "noduplicates" "noexclude"
                "nofilenamecheck" "nofileupdate" "nokeep" "nologs"
                "nomount" "none" "noparallel" "noprompt" "noredo"
                "normal" "not" "null" "obsolete" "of" "off" "offline"
                "on" "only" "open" "optimization" "option" "or" "orphan"
                "packages" "parallel" "parallelism"
                "parallelmediarestore" "parameter"
                "parameter_value_convert" "parms" "partial" "password"
                "pfile" "pipe" "platform" "plsql" "plus" "point"
                "policy" "pool" "preview" "primary" "print" "priority"
                "privileges" "proxy" "put" "quit" "rate" "rcvcat"
                "rcvman" "readonly" "readrate" "recall" "recover"
                "recoverable" "recovery" "redundancy" "register"
                "release" "reload" "remove" "renormalize" "repair"
                "repairid" "replace" "replicate" "report" "reset"
                "resetlogs" "restart" "restore" "restricted" "resync"
                "retention" "reuse" "revoke" "rpc" "rpctest" "run"
                "save" "schema" "scn" "script" "section" "send"
                "sequence" "set" "setlimit" "setsize" "shipped" "show"
                "shutdown" "since" "size" "skip" "slaxdebug" "snapshot"
                "spfile" "spool" "sql" "standby" "start" "startup"
                "step" "summary" "switch" "tablespace" "tablespaces"
                "tag" "target" "tdes168" "tempfile" "test" "thread"
                "time" "timeout" "times" "to" "trace" "transactional"
                "transport" "type" "unavailable" "uncatalog" "undo"
                "unlimited" "unrecoverable" "unregister" "until" "up"
                "upgrade" "using" "validate" "verbose" "virtual"
                "window" "with")
              'words)
  "Keywords used in `rman-mode'.")


;;
;; font-lock
;;

(defvar rman-font-lock-keywords
  `(("@@?[[:alnum:][:punct:]]+" . font-lock-constant-face)
    (,rman-keywords-regexp . font-lock-keyword-face)))


;;
;; indentation
;;

(defun rman-indent-line ()
  "Indent current line of RMAN code."
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
        (indent (condition-case nil (max (rman-calculate-indentation) 0)
                  (error 0))))
    (if savep
        (save-excursion (indent-line-to indent))
      (indent-line-to indent))))

(defun rman-calculate-indentation ()
  "Return the column to which the current line should be indented."
  (save-excursion
    (back-to-indentation)
    (let ((first-char (char-after)))
      (beginning-of-line 0)

      ;; go back to previous non-empty line
      (while (and (not (bobp)) (looking-at-p "^[[:blank:]]*\(#.*\)?$"))
        (forward-line -1))

      (back-to-indentation)
      (let ((command-p (looking-at-p rman-commands-regexp))
            (indentcol (current-indentation)))
        (end-of-line)

        ;; skip backwards over comment
        (while (nth 4 (syntax-ppss))
          (backward-char))

        ;; skip backwards over whitespace
        (while (looking-at "[[:blank:]\n]")
          (backward-char))

        (cond ((bobp) 0)

              ;; previous line opens a block
              ((looking-at-p "{")
               (+ indentcol rman-indent-level))

              ;; current line closes a block
              ((char-equal first-char ?})
               (- indentcol rman-indent-level))

              ;; previous line starts a command and continues
              ((and command-p (not (looking-at-p ";")))
               (+ indentcol rman-indent-level))

              ;; current line ends a continued command
              ((and (not command-p) (looking-at-p ";"))
               (- indentcol rman-indent-level))

              ;; default is to keep indentation
              (t indentcol))))))


;;
;; rman mode
;;

(defvar rman-mode-hook nil)

;;;###autoload
(define-derived-mode rman-mode prog-mode "RMAN"
  "Major mode for editing RMAN files.

Turning on RMAN mode runs the normal hook `rman-mode-hook'.

\\{rman-mode-map}"
  :syntax-table rman-mode-syntax-table

  ;; comments
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq-local comment-start-skip "#+\\s-*")

  ;; font lock
  (setq-local font-lock-defaults '(rman-font-lock-keywords nil t))

  ;; indentation
  (setq-local indent-line-function 'rman-indent-line)

  ;; misc mode settings
  (setq-local require-final-newline mode-require-final-newline))


(provide 'rman)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; rman-mode.el ends here
