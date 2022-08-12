;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: PREPARE-FM-PLUGIN-TOOLS; Base: 10 -*-
;;; $Header: /usr/local/cvsrep/fm-plugin-tools/prepare-fm-plugin-tools/specials.lisp,v 1.10 2010/07/22 09:38:10 edi Exp $

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

(in-package :prepare-fm-plugin-tools)

(defparameter *header-file-names*
  '("FMXExtern"
    "FMXClient"
    "FMXTypes"
    "FMXText"
    "FMXCalcEngine"
    "FMXBinaryData"
    "FMXTextStyle"
    "FMXData"
    "FMXDateTime"
    "FMXFixPt")
  "The list of all FMWrapper header files in the right order, so
that we process the needed typedes etc. first.")

(defvar *fmx-extern-location* nil
  "A pathname designator denoting where exactly FileMaker's
FMXExtern.h can be found.  You either set it here, or you'll get
a dialog asking for it.")

(defparameter *fli-file* (merge-pathnames "../fli.lisp"
                                          (load-time-value
                                            (or #.*compile-file-pathname* *load-pathname*)))
  "The target file \(to become a part of the FM-PLUGIN-TOOLS
system) which is generated by this library.")

(defparameter *typedefs*
  '((:bool . :boolean) ; Microsoft's BOOL
    (:boolean . (:boolean :char)) ; FileMaker's boolean
    ;; to prevent some `known' values (those that
    ;; just start with `FMX_') to switch to the
    ;; default in FIND-TYPE:
    (:short . :short) 
    (:long . :long))
  "An alist which maps C typedefs to the `real' types.")

(defparameter *positive-macros*
  '(#+:mswindows "defined( _MSC_VER )"
    #+:lispworks-64bit "defined( _M_X64)"
    #+:lispworks-64bit "defined( _LP64 )"
    #+:macosx "defined(__GNUC__) && (defined (__cplusplus) && __cplusplus >= 201103L)"
    )
  "C macros that are considered being defined as 1 in the SDK")

(defparameter *negative-macros*
  '(#+:macosx "defined( _MSC_VER )"
    #+:mswindows "defined(_MSC_VER) && _MSC_VER >= 1800"
    )
  "C macros that are considered being defined as 0 in the SDK")

(defvar *line-number* 0
  "The current line number when processing SDK headers in single-line mode.")
