(load "header.scm")

(define title "Lookup - a Search Interface")
(define title-logo "/lookup/images/title.png")
(define updated "$Date$")

(define lookup-stable
  ##(a #:href "http://download.sourceforge.net/lookup/lookup-1.3.tar.gz"
      "Lookup 1.3"))
(define lookup-unstable
  ##(a #:href "DIST/beta/lookup-1.99.1.tar.gz" "Lookup 1.99.1"))

(load "news.scm")

(define main
  (string-append
   ##(h1 "What is Lookup")
   ##(blockquote
     ##(p "Lookup �� Emacs ���ǥ��������ѤǤ��뼭�񸡺����󥿡��ե������Ǥ���"
	 "���Τ� CD-ROM �����ͥåȥ���μ��񥵡��Ф�Ϥᡢ"
	 "�͡��ʾ��󸻤����ñ����������Ǽ��񸡺����Ԥʤ��ޤ���"))

   ##(h1 "Latest Release")
   ##(unless
     ##(li "Stable version: " lookup-stable ", " ##(a #:href "eblook/" "eblook-1.3"))
     ##(li "Unstable version: " lookup-unstable)
     ##(li "Contribution: "
	  ##(a #:href "http://www.aist-nara.ac.jp/~masata-y/autolookup/index.html" "Auto Lookup") ", "
	  ##(a #:href "contrib/sdicf.el.sass.patch" "sass patch")))

   ##(h1 "Dictionary News")
   news))

(define footer
  ##(p ##(a #:href "http://www2.valinux.com/adbouncer.phtml?f_s=468x60&f_p=478"
	    ##(img #:src "http://www2.valinux.com/adserver.phtml?f_s=468x60&f_p=478"
		   #:alt "Member of the VA Affiliate Underground"
		   #:width 468 #:height 60 #:border 0))))

(load "template.scm")
