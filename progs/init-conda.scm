(define (python-serialize lan t)
  (with u (pre-serialize lan t)
    (with s (texmacs->code (stree->tree u) "SourceCode")
      (string-append  s  "\n<EOF>\n"))))

(define (python-entry)
  (if (url-exists? "$TEXMACS_HOME_PATH/plugins/tmpy")
      (string-append (getenv "TEXMACS_HOME_PATH")
                     "/plugins/tmpy/session/tm_python.py")
      (string-append (getenv "TEXMACS_PATH")
                     "/plugins/tmpy/session/tm_python.py")))

(define (conda-env-export env)
  (var-eval-system (string-append "conda env export -n " env)))

(define (conda-path env)
  (substring
    (car (filter (lambda (str) (string-starts? str "prefix: "))
                 (string-split (conda-env-export env) #\nl)))
    (string-length "prefix: ")))

(define (conda-versions)
  (map (lambda (x) (first (string-split x #\space)))
       (filter
        (lambda (x) (not (string-starts? x "#")))
        (string-split (var-eval-system "conda env list") #\nl))))

(define (conda-versions-paths)
  (map (lambda (x) (with l (string-split x #\space) 
                     `(,(first l) ,(last l))))
     (filter
       (lambda (x) (not (string-starts? (string-trim-spaces x) "#")))
       (string-split (var-eval-system "conda env list") #\nl))))

(define (conda-name-to-launcher env)
  (string-append (conda-path env)
                 "/bin/python "
                 (python-entry)))

(define (conda-launcher x)
 (string-append (cadr x)
                "/bin/python "
                (python-entry)))

(define (other-conda-launchers)
  (map (lambda (x) (list :launch (car x) (conda-launcher x)))
       (filter
         (lambda (x) (and (not (== (car x) "base")) (file-exists? (cadr x))))
         (conda-versions-paths))))

(define (conda-launchers)
  (cons (list :launch (conda-name-to-launcher "base"))
    (other-conda-launchers)))

(plugin-configure python 
  (:require (url-exists-in-path? "conda"))
  (:versions (conda-versions))
  ,@(conda-launchers)
  (:serializer ,python-serialize)
  (:session "Python")
  (:scripts "Python"))
