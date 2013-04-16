 ##  follow: https://github.com/avodonosov/heroku-buildpack-cl2
 ##  follow: https://github.com/avodonosov/cl-openid-demo

  mjp@uberwald:~/src/cl$ git clone https://github.com/avodonosov/cl-openid-demo.git
  mjp@uberwald:~/src/cl$ cd cl-openid-demo/
  mjp@uberwald:~/src/cl/cl-openid-demo$ heroku create -s cedar --buildpack https://github.com/avodonosov/heroku-buildpack-cl2
  mjp@uberwald:~/src/cl/cl-openid-demo$ git push heroku master

  #   get something to work!!
  vi ./openid-demo.lisp
        <tr>
            <td style=\"vertical-align:top; padding-top: 40px;\">
              <a href=\"http://lispinsmallprojects.org/\" style=\"margin-left: 10ex\"><b>day dreaming about lispInSmallProjects contest</b></a></td></tr>
  mjp@uberwald:~/src/cl/cl-openid-demo$ git add openid-demo.lisp 
  mjp@uberwald:~/src/cl/cl-openid-demo$ git commit -m "add line about contest" .
  mjp@uberwald:~/src/cl/cl-openid-demo$ git push heroku master
  # see change here: http://lit-falls-8590.herokuapp.com

  #   update github
  vi README.md
  mjp@uberwald:~/src/cl/cl-openid-demo$ git add README.md
   # On branch master
   # Your branch is ahead of 'origin/master' by 2 commits.
   #
   # Changes to be committed:
   #   (use "git reset HEAD <file>..." to unstage)
   #
   #	modified:   README.md
  mjp@uberwald:~/src/cl/cl-openid-demo$ git push


This program demonstrates how to provide OpenID login in Common Lisp web applications.

See it running at Heroku: http://cl-openid-demo.herokuapp.com/
(with the help of [CL Heroku buildpack](https://github.com/avodonosov/heroku-buildpack-cl2/)).

Powered by [cl-open-id](http://common-lisp.net/project/cl-openid/).

_Temporary Hint: In Quicklisp 2013-02-17 cl-openid is broken. For your development
either get the previous Quicklisp dist by 
`(ql-dist:install-dist "http://beta.quicklisp.org/dist/quicklisp/2013-01-28/distinfo.txt" :replace t :prompt nil)`
or use the recent cl-openid from Darcs._

Author
------
  Anton Vodonosov, avodonosov@yandex.ru

Copying
-------

The code of cl-openid-demo is in public domain.

The directory jquery-openid contains the
[jQuery OpenID Plugin by Jarrett Vance] (http://jvance.com/pages/JQueryOpenIDPlugin.xhtml)
(with slight modification by me). The jQuey OpenID Plugin is under the
[Creative Commons Attribution License](https://creativecommons.org/licenses/by/3.0/).

The lisp mascot is a public domain image [by Contad Barski] (http://www.lisperati.com/logo.html).

