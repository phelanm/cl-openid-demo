;;; -*- Mode: LISP; Syntax: COMMON-LISP; indent-tabs-mode: nil; coding: utf-8;  -*-
;;; Copyright (C) 2013 Anton Vodonosov (avodonosov@yandex.ru)
;;; See README.md for details.

(defpackage :openid-demo
  (:use :cl)
  (:export :start))

(in-package :openid-demo)

(defun src-rel-path (subpath)
  (asdf:system-relative-pathname :openid-demo subpath))

(defclass demo-acceptor (hunchentoot:easy-acceptor)
  ((relying-party :type cl-openid:relying-party
                  :initarg :relying-party
                  :accessor relying-party
                  :initform (error ":relying-party is required"))))

(defun cur-user ()
  "Returns either NIL or a plist containing various
user account attributes, as created by MAKE-ACCOUNT."
  (and hunchentoot:*session*
       (hunchentoot:session-value 'cur-user)))

(hunchentoot:define-easy-handler (home :uri "/")
    ()
  (format nil
          "<!DOCTYPE HTML>
<html>
  <head><title>CL OpenID Demo</title></head>
  <body>
    <p>
      <table border=\"0\" cellspacing=\"10\">
        <tr>
            <td style=\"vertical-align:top;\">
              <img src=\"http://www.lisperati.com/lisplogo_alien_128.png\"/></td>
            <td style=\"vertical-align:top; padding-top: 40px\">
              Hello friend! You are authenticated as: ~:[<code>NIL</code>~;
              ~:*<pre><code>(~{~(~S~) ~S~^~% ~})</code></pre>~]</td>
            <td style=\"vertical-align:top; padding-top: 40px;\">
              <a href=\"/login\" style=\"margin-left: 10ex\"><b>(re)login</b></a></td></tr>
        <tr>
            <td style=\"vertical-align:top; padding-top: 40px;\">
              <a href=\"http://lispinsmallprojects.org/\" style=\"margin-left: 10ex\"><b>day dreaming about lispInSmallProjects contest</b></a></td></tr>
      </table>
    </p>
  </body>
</html>"
          (cur-user)))

(push (hunchentoot:create-folder-dispatcher-and-handler "/jquery-openid/"
                                                        (src-rel-path  "jquery-openid/"))
      hunchentoot:*dispatch-table*)

(hunchentoot:define-easy-handler (login :uri "/login")
    (openid_identifier)
  (if openid_identifier ;; form submited, initiate authentication      
      ;; We can request not only user identity, but also additional
      ;; attributes as email, first/last names, country, language, etc.
      ;; This may be done via OpenID extensions: 
      ;; OpenID Simple Registration Extension or OpenID Attribute Exchange Extension.
      ;; We use both extensions, for sure, as different providers may support
      ;; one extension but not another.
      (let ((attr-exchange '(:openid.ns.ax "http://openid.net/srv/ax/1.0"
                             :openid.ax.mode "fetch_request"
                             :openid.ax.type.email "http://axschema.org/contact/email"
                             :openid.ax.type.language "http://axschema.org/pref/language"
                             :openid.ax.type.country "http://axschema.org/contact/country/home"
                             :openid.ax.type.firstname "http://axschema.org/namePerson/first"
                             :openid.ax.type.lastname  "http://axschema.org/namePerson/last"
                             ;; choose the attributes you want to request
                             ;; in the followin comma separated list:
                             :openid.ax.required "email,language,country,firstname,lastname"
                             ;; attributes that we want but do not require may be requested
                             ;; as if_available, although for example Google doesn't support
                             ;; if_available today (see https://developers.google.com/accounts/docs/OpenID,
                             ;; section "Attribute exchange extension" for the list of what google support)
                             ;;
                             ;;:openid.ax.if_available ""
                             ))
            (simple-reg '(:openid.ns.sreg "http://openid.net/extensions/sreg/1.1"
                          :openid.sreg.optional "nickname,email,fullname,dob,gender,postcode,country,language,timezone")))
        (hunchentoot:REDIRECT            
         (cl-openid:initiate-authentication (relying-party hunchentoot:*acceptor*)
                                            openid_identifier
                                            :extra-parameters (append attr-exchange
                                                                      simple-reg))))
      ;; else - render the form
      (format nil
              "<!DOCTYPE HTML>
<html>
<head>
  <title>OpenID Login</title>
  <script type=\"text/javascript\" src=\"http://code.jquery.com/jquery-1.6.4.js\"></script>
  <script type=\"text/javascript\" src=\"/jquery-openid/jquery.openid.js\"></script>
  <link href=\"/jquery-openid/openid.css\" rel=\"stylesheet\" type=\"text/css\">
</head>
<body>
  ~A
</body>
</html>"
              (alexandria:read-file-into-string (src-rel-path "jquery-openid/login-form.html")))))

(defun make-account (open-id-identity response-message)
  "Unify attributes representation of the two extensions:
OpenID Simple Registration Extension or OpenID Attribute Exchange Extension.

RESPONSE-MESSAGE is an assoc-list representing OpenID provider response."
  (flet ((val (key)
           (cdr (assoc key response-message :test #'string=))))
    (list :claimed-id open-id-identity
          :email (or (val "openid.sreg.email") (val "openid.ext1.value.email"))
          :nickname (val "openid.sreg.nickname")
          :fullname (or (val "openid.sreg.fullname")
                        (and (val "openid.ext1.value.firstname")
                             (val "openid.ext1.value.lastname")
                             (format nil "~A ~A"
                                     (val "openid.ext1.value.firstname")
                                     (val "openid.ext1.value.lastname"))))
          :firstname (val "openid.ext1.value.firstname")
          :lastname (val "openid.ext1.value.lastname")
          :birthday (val "openid.sreg.dob")
          :country (or (val "openid.sreg.country") (val "openid.ext1.value.country"))
          :language (or (val "openid.sreg.language") (val "openid.ext1.value.language"))
          :timezone (val "openid.sreg.timezone")
          :postcode (val "openid.sreg.postcode")))

  ;; Note,
  ;; 
  ;; Simple Registration Extension defines only 9 attributes,
  ;; we use all of them - those starting with openid.sreg.
  ;; 
  ;; OpenID Attribute Exchange is an extensible framework, many attributes
  ;; are defined here: http://openid.net/specs/openid-attribute-properties-list-1_0-01.html
  ;; In our example we only use the attributes supported by Google  
  )

(hunchentoot:define-easy-handler (openid-rp :uri "/openid-rp")
    ()
  (let* (;; hunchentoot GET paremeters have the same 
         ;; representation as open-id message: an alist
         (message (hunchentoot:get-parameters hunchentoot:*request*)) 
         (absolute-reply-uri (puri:merge-uris (hunchentoot:request-uri hunchentoot:*request*) 
                                              (cl-openid:root-uri (relying-party hunchentoot:*acceptor*))))
         user-id-url
         authproc)
    (format t "response message: ~% ~{~s~^~% ~}~%" message)
    (finish-output)
    (handler-case 
        (setf (values user-id-url authproc) 
              (cl-openid:handle-indirect-response (relying-party hunchentoot:*acceptor*)
                                                  message
                                                  absolute-reply-uri))
      (cl-openid:openid-assertion-error (e)
        (RETURN-FROM openid-rp (format nil "Error: ~A ~A"
                                       (cl-openid:code e)
                                       e)))
      (t (e) (RETURN-FROM openid-rp (format nil "Error: ~A" e))))
    (if user-id-url
        (progn         
          ;; todo for cl-openid: return user ID as a string instead puri:uri
          (setf user-id-url (princ-to-string user-id-url))
          
          (setf (hunchentoot:session-value 'cur-user)
                (make-account user-id-url message))
          (hunchentoot:REDIRECT "/"))
        ;; else:
        "Access denied")))

(defun make-relying-party (public-host public-port)
  (let ((host-port (format nil "~A:~A" public-host public-port)))
    (make-instance 'cl-openid:relying-party
                   :root-uri (puri:uri (format nil 
                                               "http://~A/openid-rp"
                                               host-port))
                   :realm (puri:uri (format nil "http://~A"
                                            host-port)))
    ;; todo for cl-openid: allow the URIs to be just strings
    ))

(defun start (&key port public-host (public-port port))
  "
  PORT is the TCP port we open socket at.
  PUBLIC-HOST is the host name through wich user's browser access our application;
              you can use \"localhost\" during development.
  PUPLIC-PORT is the port on wich user's browser access our application
              (may be different from PORT for exmaple at Heroku)."

  (hunchentoot:start (make-instance 'demo-acceptor
                                    :port port
                                    :relying-party (make-relying-party public-host public-port))))
