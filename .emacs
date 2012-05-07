<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>EmacsWiki: powerline.el</title><link rel="alternate" type="application/wiki" title="Edit this page" href="http://www.emacswiki.org/emacs?action=edit;id=powerline.el" /><link type="text/css" rel="stylesheet" href="/emacs/wiki.css" /><meta name="robots" content="INDEX,FOLLOW" /><link rel="alternate" type="application/rss+xml" title="EmacsWiki" href="http://www.emacswiki.org/emacs?action=rss" /><link rel="alternate" type="application/rss+xml" title="EmacsWiki: powerline.el" href="http://www.emacswiki.org/emacs?action=rss;rcidonly=powerline.el" />
<link rel="alternate" type="application/rss+xml"
      title="Emacs Wiki with page content"
      href="http://www.emacswiki.org/emacs/full.rss" />
<link rel="alternate" type="application/rss+xml"
      title="Emacs Wiki with page content and diff"
      href="http://www.emacswiki.org/emacs/full-diff.rss" />
<link rel="alternate" type="application/rss+xml"
      title="Emacs Wiki including minor differences"
      href="http://www.emacswiki.org/emacs/minor-edits.rss" />
<link rel="alternate" type="application/rss+xml"
      title="Changes for powerline.el only"
      href="http://www.emacswiki.org/emacs?action=rss;rcidonly=powerline.el" />
<script type="text/javascript">
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-2101513-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
</script>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/></head><body class="http://www.emacswiki.org/emacs"><div class="header"><a class="logo" href="http://www.emacswiki.org/emacs/SiteMap"><img class="logo" src="/emacs_logo.png" alt="[Home]" /></a><span class="gotobar bar"><a class="local" href="http://www.emacswiki.org/emacs/SiteMap">SiteMap</a> <a class="local" href="http://www.emacswiki.org/emacs/Search">Search</a> <a class="local" href="http://www.emacswiki.org/emacs/ElispArea">ElispArea</a> <a class="local" href="http://www.emacswiki.org/emacs/HowTo">HowTo</a> <a class="local" href="http://www.emacswiki.org/emacs/Glossary">Glossary</a> <a class="local" href="http://www.emacswiki.org/emacs/RecentChanges">RecentChanges</a> <a class="local" href="http://www.emacswiki.org/emacs/News">News</a> <a class="local" href="http://www.emacswiki.org/emacs/Problems">Problems</a> <a class="local" href="http://www.emacswiki.org/emacs/Suggestions">Suggestions</a> </span>
<!-- Google CSE Search Box Begins  -->
<form class="tiny" action="http://www.google.com/cse" id="searchbox_004774160799092323420:6-ff2s0o6yi"><p>
<input type="hidden" name="cx" value="004774160799092323420:6-ff2s0o6yi" />
<input type="text" name="q" size="25" />
<input type="submit" name="sa" value="Search" />
</p></form>
<script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=searchbox_004774160799092323420%3A6-ff2s0o6yi"></script>
<!-- Google CSE Search Box Ends -->
<h1><a title="Click to search for references to this page" rel="nofollow" href="http://www.google.com/cse?cx=004774160799092323420:6-ff2s0o6yi&amp;q=%22powerline.el%22">powerline.el</a></h1></div><div class="wrapper"><div class="content browse"><p class="download"><a href="http://www.emacswiki.org/emacs/download/powerline.el">Download</a></p><pre class="code"><span class="linecomment">;;; powerline.el</span>

(defvar powerline-color1)
(defvar powerline-color2)

(setq powerline-color1 "<span class="quote">grey22</span>")
(setq powerline-color2 "<span class="quote">grey40</span>")

(set-face-attribute 'mode-line nil
                    :background "<span class="quote">OliveDrab3</span>"
                    :box nil)
(set-face-attribute 'mode-line-inactive nil
                    :box nil)

(scroll-bar-mode -1)

(defun arrow-left-xpm
  (color1 color2)
  "<span class="quote">Return an XPM left arrow string representing.</span>"
  (create-image
   (format "<span class="quote">/* XPM */
static char * arrow_left[] = {
\"12 18 2 1\",
\". c %s\",
\"  c %s\",
\".           \",
\"..          \",
\"...         \",
\"....        \",
\".....       \",
\"......      \",
\".......     \",
\"........    \",
\".........   \",
\".........   \",
\"........    \",
\".......     \",
\"......      \",
\".....       \",
\"....        \",
\"...         \",
\"..          \",
\".           \"};</span>"
           (if color1 color1 "<span class="quote">None</span>")
           (if color2 color2 "<span class="quote">None</span>"))
   'xpm t :ascent 'center))

(defun arrow-right-xpm
  (color1 color2)
  "<span class="quote">Return an XPM right arrow string representing.</span>"
  (create-image
   (format "<span class="quote">/* XPM */
static char * arrow_right[] = {
\"12 18 2 1\",
\". c %s\",
\"  c %s\",
\"           .\",
\"          ..\",
\"         ...\",
\"        ....\",
\"       .....\",
\"      ......\",
\"     .......\",
\"    ........\",
\"   .........\",
\"   .........\",
\"    ........\",
\"     .......\",
\"      ......\",
\"       .....\",
\"        ....\",
\"         ...\",
\"          ..\",
\"           .\"};</span>"
           (if color2 color2 "<span class="quote">None</span>")
           (if color1 color1 "<span class="quote">None</span>"))
   'xpm t :ascent 'center))

(defun curve-right-xpm
  (color1 color2)
  "<span class="quote">Return an XPM right curve string representing.</span>"
  (create-image
   (format "<span class="quote">/* XPM */
static char * curve_right[] = {
\"12 18 2 1\",
\". c %s\",
\"  c %s\",
\"           .\",
\"         ...\",
\"         ...\",
\"       .....\",
\"       .....\",
\"       .....\",
\"      ......\",
\"      ......\",
\"      ......\",
\"      ......\",
\"      ......\",
\"      ......\",
\"       .....\",
\"       .....\",
\"       .....\",
\"         ...\",
\"         ...\",
\"           .\"};</span>"
           (if color2 color2 "<span class="quote">None</span>")
           (if color1 color1 "<span class="quote">None</span>"))
   'xpm t :ascent 'center))

(defun curve-left-xpm
  (color1 color2)
  "<span class="quote">Return an XPM left curve string representing.</span>"
  (create-image
   (format "<span class="quote">/* XPM */
static char * curve_left[] = {
\"12 18 2 1\",
\". c %s\",
\"  c %s\",
\".           \",
\"...         \",
\"...         \",
\".....       \",
\".....       \",
\".....       \",
\"......      \",
\"......      \",
\"......      \",
\"......      \",
\"......      \",
\"......      \",
\".....       \",
\".....       \",
\".....       \",
\"...         \",
\"...         \",
\".           \"};</span>"
           (if color1 color1 "<span class="quote">None</span>")
           (if color2 color2 "<span class="quote">None</span>"))
   'xpm t :ascent 'center))

(defun make-xpm
  (name color1 color2 data)
  "<span class="quote">Return an XPM image for lol data</span>"
  (create-image
   (concat
    (format "<span class="quote">/* XPM */
static char * %s[] = {
\"%i %i 2 1\",
\". c %s\",
\"  c %s\",
</span>"
            (downcase (replace-regexp-in-string "<span class="quote"> </span>" "<span class="quote">_</span>" name))
            (length (car data))
            (length data)
            (if color1 color1 "<span class="quote">None</span>")
            (if color2 color2 "<span class="quote">None</span>"))
    (let ((len  (length data))
          (idx  0))
      (apply 'concat
             (mapcar '(lambda (dl)
                        (setq idx (+ idx 1))
                        (concat
                         "<span class="quote">\"</span>"
                         (concat
                          (mapcar '(lambda (d)
                                     (if (eq d 0)
                                         (string-to-char "<span class="quote"> </span>")
                                       (string-to-char "<span class="quote">.</span>")))
                                  dl))
                         (if (eq idx len)
                             "<span class="quote">\"};</span>"
                           "<span class="quote">\",\n</span>")))
                     data))))
   'xpm t :ascent 'center))

(defun half-xpm
  (color1 color2)
  (make-xpm "<span class="quote">half</span>" color1 color2
            (make-list 18
                       (append (make-list 6 0)
                               (make-list 6 1)))))

(defun percent-xpm
  (pmax pmin we ws width color1 color2)
  (let* ((fs   (if (eq pmin ws)
                   0
                 (round (* 17 (/ (float ws) (float pmax))))))
         (fe   (if (eq pmax we)
                   17
                 (round (* 17 (/ (float we) (float pmax))))))
         (o    nil)
         (i    0))
    (while (&lt; i 18)
      (setq o (cons
               (if (and (&lt;= fs i)
                        (&lt;= i fe))
                   (append (list 0) (make-list width 1) (list 0))
                 (append (list 0) (make-list width 0) (list 0)))
               o))
      (setq i (+ i 1)))
    (make-xpm "<span class="quote">percent</span>" color1 color2 (reverse o))))


<span class="linecomment">;; from memoize.el @ http://nullprogram.com/blog/2010/07/26/</span>
(defun memoize (func)
  "<span class="quote">Memoize the given function. If argument is a symbol then
install the memoized function over the original function.</span>"
  (typecase func
    (symbol (fset func (memoize-wrap (symbol-function func))) func)
    (function (memoize-wrap func))))

(defun memoize-wrap (func)
  "<span class="quote">Return the memoized version of the given function.</span>"
  (let ((table-sym (gensym))
	(val-sym (gensym))
	(args-sym (gensym)))
    (set table-sym (make-hash-table :test 'equal))
    `(lambda (&rest ,args-sym)
       ,(concat (documentation func) "<span class="quote">\n(memoized function)</span>")
       (let ((,val-sym (gethash ,args-sym ,table-sym)))
	 (if ,val-sym
	     ,val-sym
	   (puthash ,args-sym (apply ,func ,args-sym) ,table-sym))))))

(memoize 'arrow-left-xpm)
(memoize 'arrow-right-xpm)
(memoize 'curve-left-xpm)
(memoize 'curve-right-xpm)
(memoize 'half-xpm)
(memoize 'percent-xpm)



(defvar powerline-minor-modes nil)
(defvar powerline-arrow-shape 'arrow)
(defun powerline-make-face
  (bg &optional fg)
  (if bg
      (let ((cface (intern (concat "<span class="quote">powerline-</span>"
                                   bg
                                   "<span class="quote">-</span>"
                                   (if fg
                                       (format "<span class="quote">%s</span>" fg)
                                     "<span class="quote">white</span>")))))
        (make-face cface)2
        (if fg
            (if (eq fg 0)
                (set-face-attribute cface nil
                                    :background bg
                                    :box nil)
              (set-face-attribute cface nil
                                  :foreground fg
                                  :background bg
                                  :box nil))
          (set-face-attribute cface nil
                            :foreground "<span class="quote">white</span>"
                            :background bg
                            :box nil))
        cface)
    nil))
(defun powerline-make-left
  (string color1 &optional color2 localmap)
  (let ((plface (powerline-make-face color1))
        (arrow  (and color2 (not (string= color1 color2)))))
    (concat
     (if (or (not string) (string= string "<span class="quote"></span>"))
         "<span class="quote"></span>"
       (propertize "<span class="quote"> </span>" 'face plface))
     (if string
         (if localmap
             (propertize string 'face plface 'mouse-face plface 'local-map localmap)
           (propertize string 'face plface))
       "<span class="quote"></span>")
     (if arrow
         (propertize "<span class="quote"> </span>" 'face plface)
       "<span class="quote"></span>")
     (if arrow
         (propertize "<span class="quote"> </span>" 'display
                     (cond ((eq powerline-arrow-shape 'arrow)
                            (arrow-left-xpm color1 color2))
                           ((eq powerline-arrow-shape 'curve)
                            (curve-left-xpm color1 color2))
                           ((eq powerline-arrow-shape 'half)
                            (half-xpm color2 color1))
                           (t
                            (arrow-left-xpm color1 color2)))
                     'local-map (make-mode-line-mouse-map
                                 'mouse-1 (lambda () (interactive)
                                            (setq powerline-arrow-shape
                                                  (cond ((eq powerline-arrow-shape 'arrow) 'curve)
                                                        ((eq powerline-arrow-shape 'curve) 'half)
                                                        ((eq powerline-arrow-shape 'half)  'arrow)
                                                        (t                                 'arrow)))
                                            (redraw-modeline))))
       "<span class="quote"></span>"))))
(defun powerline-make-right
  (string color2 &optional color1 localmap)
  (let ((plface (powerline-make-face color2))
        (arrow  (and color1 (not (string= color1 color2)))))
    (concat
     (if arrow
       (propertize "<span class="quote"> </span>" 'display
                   (cond ((eq powerline-arrow-shape 'arrow)
                          (arrow-right-xpm color1 color2))
                         ((eq powerline-arrow-shape 'curve)
                          (curve-right-xpm color1 color2))
                         ((eq powerline-arrow-shape 'half)
                          (half-xpm color2 color1))
                         (t
                          (arrow-right-xpm color1 color2)))
                   'local-map (make-mode-line-mouse-map
                               'mouse-1 (lambda () (interactive)
                                          (setq powerline-arrow-shape
                                                (cond ((eq powerline-arrow-shape 'arrow) 'curve)
                                                      ((eq powerline-arrow-shape 'curve) 'half)
                                                      ((eq powerline-arrow-shape 'half)  'arrow)
                                                      (t                                 'arrow)))
                                          (redraw-modeline))))
       "<span class="quote"></span>")
     (if arrow
         (propertize "<span class="quote"> </span>" 'face plface)
       "<span class="quote"></span>")
     (if string
         (if localmap
             (propertize string 'face plface 'mouse-face plface 'local-map localmap)
           (propertize string 'face plface))
       "<span class="quote"></span>")
     (if (or (not string) (string= string "<span class="quote"></span>"))
         "<span class="quote"></span>"
       (propertize "<span class="quote"> </span>" 'face plface)))))
(defun powerline-make-fill
  (color)
  <span class="linecomment">;; justify right by filling with spaces to right fringe, 20 should be calculated</span>
  (let ((plface (powerline-make-face color)))
    (if (eq 'right (get-scroll-bar-mode))
        (propertize "<span class="quote"> </span>" 'display '((space :align-to (- right-fringe 21)))
                    'face plface)
      (propertize "<span class="quote"> </span>" 'display '((space :align-to (- right-fringe 24)))
                  'face plface))))
(defun powerline-make-text
  (string color &optional fg localmap)
  (let ((plface (powerline-make-face color)))
    (if string
        (if localmap
            (propertize string 'face plface 'mouse-face plface 'local-map localmap)
          (propertize string 'face plface))
      "<span class="quote"></span>")))
(defun powerline-make (side string color1 &optional color2 localmap)
  (cond ((and (eq side 'right) color2) (powerline-make-right  string color1 color2 localmap))
        ((and (eq side 'left) color2)  (powerline-make-left   string color1 color2 localmap))
        ((eq side 'left)               (powerline-make-left   string color1 color1 localmap))
        ((eq side 'right)              (powerline-make-right  string color1 color1 localmap))
        (t                             (powerline-make-text   string color1 localmap))))
(defmacro defpowerline (name string)
  `(defun ,(intern (concat "<span class="quote">powerline-</span>" (symbol-name name)))
     (side color1 &optional color2)
     (powerline-make side
                     ,string
                     color1 color2)))
(defun powerline-mouse (click-group click-type string)
  (cond ((eq click-group 'minor)
         (cond ((eq click-type 'menu)
                `(lambda (event)
                   (interactive "<span class="quote">@e</span>")
                   (minor-mode-menu-from-indicator ,string)))
               ((eq click-type 'help)
                `(lambda (event)
                   (interactive "<span class="quote">@e</span>")
                   (describe-minor-mode-from-indicator ,string)))
               (t
                `(lambda (event)
                   (interactive "<span class="quote">@e</span>")
                    nil))))
        (t
         `(lambda (event)
            (interactive "<span class="quote">@e</span>")
            nil))))

(defpowerline arrow       "<span class="quote"></span>")
(defpowerline buffer-id   (propertize (car (propertized-buffer-identification "<span class="quote">%12b</span>"))
                                      'face (powerline-make-face color1)))
(defvar powerline-buffer-size-suffix t)
(defpowerline buffer-size (propertize
                            (if powerline-buffer-size-suffix
                                "<span class="quote">%I</span>"
                              "<span class="quote">%i</span>")
                            'local-map (make-mode-line-mouse-map
                                        'mouse-1 (lambda () (interactive)
                                                   (setq powerline-buffer-size-suffix
                                                         (not powerline-buffer-size-suffix))
                                                   (redraw-modeline)))))
(defpowerline rmw         "<span class="quote">%*</span>")
(defpowerline major-mode  (propertize mode-name
                                      'help-echo "<span class="quote">Major mode\n\ mouse-1: Display major mode menu\n\ mouse-2: Show help for major mode\n\ mouse-3: Toggle minor modes</span>"
                                      'local-map (let ((map (make-sparse-keymap)))
                                                   (define-key map [mode-line down-mouse-1]
                                                     `(menu-item ,(purecopy "<span class="quote">Menu Bar</span>") ignore
                                                                 :filter (lambda (_) (mouse-menu-major-mode-map))))
                                                   (define-key map [mode-line mouse-2] 'describe-mode)
                                                   (define-key map [mode-line down-mouse-3] mode-line-mode-menu)
                                                   map)))
(defpowerline process      mode-line-process)
(defpowerline minor-modes (let ((mms (split-string (format-mode-line minor-mode-alist))))
                            (apply 'concat
                                   (mapcar '(lambda (mm)
                                              (propertize (if (string= (car mms)
                                                                       mm)
                                                              mm
                                                            (concat "<span class="quote"> </span>" mm))
                                                          'help-echo "<span class="quote">Minor mode\n mouse-1: Display minor mode menu\n mouse-2: Show help for minor mode\n mouse-3: Toggle minor modes</span>"
                                                          'local-map (let ((map (make-sparse-keymap)))
                                                                       (define-key map [mode-line down-mouse-1]   (powerline-mouse 'minor 'menu mm))
                                                                       (define-key map [mode-line mouse-2]        (powerline-mouse 'minor 'help mm))
                                                                       (define-key map [mode-line down-mouse-3]   (powerline-mouse 'minor 'menu mm))
                                                                       (define-key map [header-line down-mouse-3] (powerline-mouse 'minor 'menu mm))
                                                                       map)))
                                           mms))))
(defpowerline row         "<span class="quote">%4l</span>")
(defpowerline column      "<span class="quote">%3c</span>")
(defpowerline percent     "<span class="quote">%6p</span>")
(defpowerline narrow      (let (real-point-min real-point-max)
                            (save-excursion
                              (save-restriction
                                (widen)
                                (setq real-point-min (point-min) real-point-max (point-max))))
                            (when (or (/= real-point-min (point-min))
                                      (/= real-point-max (point-max)))
                              (propertize "<span class="quote">Narrow</span>"
                                          'help-echo "<span class="quote">mouse-1: Remove narrowing from the current buffer</span>"
                                          'local-map (make-mode-line-mouse-map
                                                      'mouse-1 'mode-line-widen)))))
(defpowerline status      "<span class="quote">%s</span>")
(defpowerline global      global-mode-string)
(defpowerline emacsclient mode-line-client)
(defpowerline vc          (when (and (buffer-file-name (current-buffer))
                                     vc-mode)
                                  vc-mode-line))
(defpowerline percent-xpm (propertize "<span class="quote">  </span>"
                                      'display
                                      (let (pmax
                                            pmin
                                            (ws (window-start))
                                            (we (window-end)))
                                        (save-restriction
                                          (widen)
                                          (setq pmax (point-max))
                                          (setq pmin (point-min)))
                                        (percent-xpm pmax pmin we ws 15 color1 color2))))

(setq-default mode-line-format
              (list "<span class="quote">%e</span>"
                    '(:eval (concat
                             (powerline-rmw            'left   nil  )
                             (powerline-buffer-size    'left   nil  )
                             (powerline-buffer-id      'left   nil  powerline-color1  )
                             (powerline-major-mode     'left        powerline-color1  )
                             (powerline-process        'text        powerline-color1  )
                             (powerline-minor-modes    'left        powerline-color1  )
                             (powerline-narrow         'left        powerline-color1  powerline-color2  )
                             (powerline-global         'center                        powerline-color2  )
                             (powerline-vc             'center                        powerline-color2  )
                             (powerline-make-fill                                     powerline-color2  )
                             (powerline-row            'right       powerline-color1  powerline-color2  )
                             (powerline-make-text      "<span class="quote">:</span>"          powerline-color1  )
                             (powerline-column         'right       powerline-color1  )
                             (powerline-percent        'right  nil  powerline-color1  )
                             (powerline-percent-xpm    'text   nil  powerline-color1  )
                             (powerline-make-text      "<span class="quote">  </span>"    nil  )))))

(provide 'powerline)</pre></div><div class="wrapper close"></div></div><div class="footer"><hr /><span class="gotobar bar"><a class="local" href="http://www.emacswiki.org/emacs/SiteMap">SiteMap</a> <a class="local" href="http://www.emacswiki.org/emacs/Search">Search</a> <a class="local" href="http://www.emacswiki.org/emacs/ElispArea">ElispArea</a> <a class="local" href="http://www.emacswiki.org/emacs/HowTo">HowTo</a> <a class="local" href="http://www.emacswiki.org/emacs/Glossary">Glossary</a> <a class="local" href="http://www.emacswiki.org/emacs/RecentChanges">RecentChanges</a> <a class="local" href="http://www.emacswiki.org/emacs/News">News</a> <a class="local" href="http://www.emacswiki.org/emacs/Problems">Problems</a> <a class="local" href="http://www.emacswiki.org/emacs/Suggestions">Suggestions</a> </span><span class="translation bar"><br />  <a class="translation new" rel="nofollow" href="http://www.emacswiki.org/emacs?action=translate;id=powerline.el;missing=de_es_fr_it_ja_ko_pt_ru_se_zh">Add Translation</a></span><span class="edit bar"><br /> <a class="comment local" href="http://www.emacswiki.org/emacs/Comments_on_powerline.el">Talk</a> <a class="edit" accesskey="e" title="Click to edit this page" rel="nofollow" href="http://www.emacswiki.org/emacs?action=edit;id=powerline.el">Edit this page</a> <a class="history" rel="nofollow" href="http://www.emacswiki.org/emacs?action=history;id=powerline.el">View other revisions</a> <a class="admin" rel="nofollow" href="http://www.emacswiki.org/emacs?action=admin;id=powerline.el">Administration</a></span><!-- test --><span class="time"><br /> Last edited 2012-03-17 04:59 UTC by <a class="author" title="from 173-164-144-41-SFBA.hfc.comcastbusiness.net" href="http://www.emacswiki.org/emacs/liillliillliiii">liillliillliiii</a> <a class="diff" rel="nofollow" href="http://www.emacswiki.org/emacs?action=browse;diff=2;id=powerline.el">(diff)</a></span><div style="float:right; margin-left:1ex;">
<!-- Creative Commons License -->
<a href="http://creativecommons.org/licenses/GPL/2.0/"><img alt="CC-GNU GPL" style="border:none" src="/pics/cc-GPL-a.png" /></a>
<!-- /Creative Commons License -->
</div>

<!--
<rdf:RDF xmlns="http://web.resource.org/cc/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<Work rdf:about="">
   <license rdf:resource="http://creativecommons.org/licenses/GPL/2.0/" />
  <dc:type rdf:resource="http://purl.org/dc/dcmitype/Software" />
</Work>

<License rdf:about="http://creativecommons.org/licenses/GPL/2.0/">
   <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
   <permits rdf:resource="http://web.resource.org/cc/Distribution" />
   <requires rdf:resource="http://web.resource.org/cc/Notice" />
   <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
   <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
   <requires rdf:resource="http://web.resource.org/cc/SourceCode" />
</License>
</rdf:RDF>
-->

<p class="legal">
This work is licensed to you under version 2 of the
<a href="http://www.gnu.org/">GNU</a> <a href="/GPL">General Public License</a>.
Alternatively, you may choose to receive this work under any other
license that grants the right to use, copy, modify, and/or distribute
the work, as long as that license imposes the restriction that
derivative works have to grant the same rights and impose the same
restriction. For example, you may choose to receive this work under
the
<a href="http://www.gnu.org/">GNU</a>
<a href="/FDL">Free Documentation License</a>, the
<a href="http://creativecommons.org/">CreativeCommons</a>
<a href="http://creativecommons.org/licenses/sa/1.0/">ShareAlike</a>
License, the XEmacs manual license, or
<a href="/OLD">similar licenses</a>.
</p>
</div>
</body>
</html>
