(load "header.scm")

(define title "Lookup - a Search Interface")

(define lookup-stable (href "Lookup 1.3" "http://download.sourceforge.net/lookup/lookup-1.3.tar.gz"))
(define lookup-unstable (href "Lookup 1.99.0" "DIST/beta/lookup-1.99.0.tar.gz"))

(define news
  '(
    ("ndic sass support" "2000-11-11"
     ("Yoishiro Okabe ����ˤ�ꡢndic �� sass �򥵥ݡ��Ȥ��뤿���"
      (href "�ѥå�" "contrib/sdicf.el.sass.patch")
      "����������ޤ�����"))

    ("Auto Lookup ��꡼��" "2000-10-13"
     ((href "Auto Lookup"
	    "http://www.aist-nara.ac.jp/~masata-y/autolookup/index.html")
      "�ϡ�Lookup ��Ȥäƥ������벼�α�ñ���ưŪ��Ĵ�٤ƥߥ˥Хåե���"
      "��̤�ɽ�����Ƥ����ץ����Ǥ���"))

    ("FreePWING �ˤ�� JIS X 4081 �ǳƼＭ��" "2000-09-01"
     ((href "FreePWING ��������ۥڡ���"
	    "http://openlab.ring.gr.jp/edict/fpw/")
      "���ŻҼ��񥪡��ץ��ܤ˺�������ޤ�����"))

    ("srd-fpw 1.1.1" "2000-08-25"
     ((href "srd-fpw" "http://openlab.ring.gr.jp/edict/srd-fpw/")
      "�Ȥϡ����شۡإ�����ϥ����Ѹ켭ŵ�٤� EPWING �������Ѵ����뤿���"
      "������ץȤǤ���"))

    ("��ǽ�����ǡֿ����¡��±��漭ŵ��" "2000-07-12"
     ("DeAGOSTINI��PC Success���� 24 ��(1324��)����Ͽ�Ȥ��ơ�"
      "����ҡֿ����¡��±��漭ŵ�פε�ǽ�����Ǥ��դ��Ƥ��뤽���Ǥ���"
      "�������׸���������ޤ��󤬡�Lookup �Ǥ����ѽ����褦�Ǥ���"))

    ("mypaedia-fpw 1.4.1" "2000-07-14"
     ((href "mypaedia-fpw" "http://openlab.ring.gr.jp/edict/mypaedia-fpw/")
      "�Ȥϡ�ʿ�޼Ҥξ���ɴ�ʻ�ŵ�إޥ��ڥǥ����٤� EPWING �������Ѵ�����"
      "����Υ�����ץȤǤ���DeAGOSTINI ����ȯ�䤵��Ƥ����PC Success�٤�"
      "�ϴ���(500��)�ˤϡ��إޥ��ڥǥ���99�٤ε�ǽ�����Ǥ���°���Ƥ��ޤ���"))

    ("FreePWING 1.2.1" "2000-07-07"
     ((href "FreePWING" "http://www.sra.co.jp/people/m-kasahr/freepwing/")
      "�Ȥϡ��ƼＭ��ǡ����� EPWING �������Ѵ����뤿��Υġ���Ǥ���"
      "�����Ĥ��Υե꡼�ʼ���ǡ������������Ƥ��ޤ���"))

    ("wdic-fpw 1.1" "2000-06-24"
     ((href "wdic-fpw"
	    "http://member.nifty.ne.jp/~satomii/freepwing/indexj.html")
      "�Ȥϡ��ե꡼���̿��Ѹ콸"
      "��" (href "�̿��Ѹ�δ����μ�" "http://www.wdic.org/") "�٤�"
      "EPWING �������Ѵ����뤿��Υ�����ץȤǤ���"))

    ("Unix �ǻȤ����ŻҼ������" "2000-05-09"
     ((href "�ŻҼ��񥪡��ץ���" "http://openlab.ring.gr.jp/edict/") "���顢"
      (href "Unix �ʤɤǻȤ����ŻҼ���ξ���"
	    "http://openlab.ring.gr.jp/edict/info.html")
      "����������Ƥ��ޤ������줫���ŻҼ�����㤪���ȻפäƤ�������"
      "�ɤ��ŻҼ�����㤪�����¤äƤ������ϥ����å����Ƥߤޤ��礦��"))
    ))

(define body
  (string-append
   (h1 "What is Lookup")
   (quotation
    (p "Lookup �� Emacs ���ǥ��������ѤǤ��뼭�񸡺����󥿡��ե������Ǥ���"
       "���Τ� CD-ROM �����ͥåȥ���μ��񥵡��Ф�Ϥᡢ"
       "�͡��ʾ��󸻤����ñ����������Ǽ��񸡺����Ԥʤ��ޤ���"))

   (h1 "Latest Release")
   (ul (li "Stable version: " lookup-stable ", " (href "eblook-1.3" "eblook/"))
       (li "Unstable version: " lookup-unstable)
       (li "Contribution: "
	   (href "Auto Lookup" "http://www.aist-nara.ac.jp/~masata-y/autolookup/index.html") ", "
	   (href "sass patch" "contrib/sdicf.el.sass.patch")))

   (h1 "Dictionary News")
   (ul (map-append (lambda (data)
		     (let ((title (car data))
			   (date (cadr data))
			   (info (map-append (lambda (x) (eval x (current-module)))
					     (caddr data))))
		       (li (p (font #:color "#3366cc" (b title))
			      " (" date ")" (br info)))))
		   news))
   (hr)
   (address
    "Last modified: $Date$"
    "<br>Copyright (C) 2000 Keisuke Nishida &lt;knishida@ring.gr.jp&gt;"
    "<br>Graphics (C) 2000 Sumiya Sakoda")
   (p (href (img "http://www2.valinux.com/adserver.phtml?f_s=468x60&f_p=478"
		 #:alt "Member of the VA Affiliate Underground"
		 #:width 468 #:height 60 #:border 0)
	    "http://www2.valinux.com/adbouncer.phtml?f_s=468x60&f_p=478"))))

(load "menu.scm")

(print-html
 (table
  (tr #:valign "bottom"
   (td (img "/lookup/images/title.png" #:alt "Lookup"))
   (td "Language:"
       (href "English" "http://lookup.sourceforge.net/")
       (href "Japanese" "http://openlab.ring.gr.jp/lookup/"))))
 (table #:cellpadding "4"
  (tr #:valign "top"
   (td #:bgcolor "#cccccc" #:nowrap "" menu)
   (td body))))
