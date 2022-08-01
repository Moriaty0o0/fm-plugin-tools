;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: CL-USER; Base: 10 -*-
;;; $Header: /usr/local/cvsrep/fm-plugin-tools/deliver.lisp,v 1.16 2010/07/22 09:38:05 edi Exp $

;;; Copyright (c) 2006-2010, Dr. Edmund Weitz.  All rights reserved.

;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:

;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.

;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.

;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :cl-user)

(lw:load-all-patches)

(defvar *system-homedir*
  #+win32 #p"C:/" #-win32 (user-homedir-pathname))

;;; The following lines added by ql:add-to-init-file:
#+(not quicklisp)
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

;;; cl-fad
(ql:quickload :cl-fad)

;;; Local ASDF repositories, it's fine some directorie do not exist.
(dolist (i '("Lisp/fm-plugin-tools/"))
  (pushnew (merge-pathnames i *system-homedir*)
           asdf:*central-registry* :test #'equal))

(defvar *asdf-system* :fm-plugin-example
  "The ASDF system which contains the code for the plug-in.  It should
depend on FM-PLUGIN-TOOLS.")

(defvar *default-name* "FMPLisp"
  "Default plugin execution name when no command-line arguments are given.")

(defvar *capi-required-p* #+:win32 t #+:macosx nil
  "Whether the plug-in needs CAPI.")

(defvar *mp-required-p* nil
  "Whether the plug-in needs MP.  This is only relevant if
*CAPI-REQUIRED-P* is NIL.")

(defvar *deliver-level* 5
  ;; level 0 is good for development - for deployment you most likely
  ;; want higher values for a much smaller DLL file
  "Delivery level for the delivered DLL.")

(defvar *start-function* 'lw:do-nothing
  "The start function of the delivered DLL.")

;; load the code
(asdf:load-system *asdf-system*)

(fm:set-product-name)

(defvar *versioninfo*
  `(:binary-version ,(logior (ash (or (first fm:*plugin-version*) 0) 48)
                             (ash (or (second fm:*plugin-version*) 0) 32)
                             (ash (or (third fm:*plugin-version*) 0) 16)
                             (or (fourth fm:*plugin-version*) 0))
    :version-string ,(fm:version-string)
    :company-name ,fm:*company-name*
    :product-name ,fm:*product-name*
    :file-description ,fm:*plugin-help-text*
    :legal-copyright ,fm:*copyright-message*))

;; check if plug-in ID is valid
(fm:check-plugin-id)

;; load necessary code for WRITE-MACOS-APPLICATION-BUNDLE
#+:macosx
(compile-file (example-file "configuration/macos-application-bundle")
              :output-file :temp
              :load t)

(defvar *template* (merge-pathnames "Template.fmplugin/" *load-pathname*))

;; create shared library
(lw:deliver *start-function*
            ;; we assume this is called from the build script
            #+:win32
            (format nil #-:lispworks-64bit "~A.fmx"
                        #+:lispworks-64bit "~A.fmx64"
                    (or (fourth sys:*line-arguments-list*) *default-name*))
            #+:macosx
            (write-macos-application-bundle
             (format nil "~A/~A.fmplugin"
                     (fifth sys:*line-arguments-list*)
                     (fourth sys:*line-arguments-list*))
             :template-bundle (make-pathname :name nil
                                             :type nil
                                             :version nil
                                             :defaults *template*)
             :identifier fm:*plugin-bundle-identifier*
             :version (fm:version-string)             
             :executable-name (fourth sys:*line-arguments-list*)
             :package-type "BNDL"
             :extension "fmplugin"
             :document-types nil)
            *deliver-level*
            ;; we need a loadable bundle, not a Mach-O shared library
	    #+:macosx #+:macosx
	    :image-type :bundle
            :keep-symbols fm:*symbols-to-keep*
            :keep-lisp-reader t
            :keep-debug-mode (or fm:*log-backtraces-p* (< *deliver-level* 5))
            :versioninfo *versioninfo*
            :dll-exports '("FMExternCallProc")
            :interface (and *capi-required-p* :capi)
            :multiprocessing (or *capi-required-p* *mp-required-p*))

