(set! %load-path (cons "../.." %load-path))
(use-modules (htmlgen))

(define name "OS/2 Bitmap")
(define subtitle "OS/2 �� bitmap-mule�Υե���Ȥ�Ȥ���ˡ")
(define date "$Date$")

(define summary (p "by Masaru Nomiya &lt;nomiya@pp.iij4u.or.jp&gt;"))

(define subbody
  (string-append
   (ol
    (li "bitmp-mule8.2.tar.gz ��Ÿ��")
    (li "cd bitmap-mule-8.2")
    (li "make install"
	(p "���󥹥ȡ������"
	   (pre "While compiling toplevel forms in file g:/bitmap-mule-8.2/gnus-bitmap.el:\n"
		"!! End of file during parsing")
	   "�Ȥ�����å�������ɽ�������Ȼפ��ޤ��������ˤ��뤳�ȤϤʤ��褦�Ǥ���"))
    (li "mkfontdir��¹ԡ�fonts.dir��������Ƥ����١�"
	(p "../X11/lib/fonts/misc�Τ褦�˥ե���Ȥ�¿������Ȥ���Ǥϡ�"
	   "6. �˼��� fonts.dir ���Խ���Ȥ��ѻ��ˤʤ�ޤ��Τǡ�"
	   "pcf.gz �����ե������ bdf �����ե���������Υǥ��쥯�ȥ��"
	   "���Ѥ���Τ��ɤ��Ǥ��礦�������ξ��ϡ�"
	   "bitmap-mule-8.2/font �Ǽ¹Ԥ��ޤ�����"))
    (li "bdf2mfn �����Ƥ� bdf �����ե���Ȥ� mfn �����ե���Ȥ��Ѵ�")
    (li "fonts.dir ���Խ�"
	(p "fonts.dir����̣�ϡ�"
	   (pre "etl7x14-bitmap.pcf.gz -etl-fixed-medium-r-normal--14-105-100-100-m-70-bitmap.7x14-0\netc.")
	   "�Ȥ����褦��"
	   (pre "pcf.gz�����ե����̾���أ̣ƣķ����ե����̾")
	   "�ȤʤäƤ��ޤ����������"
	   (pre "�أ̣ƣķ����ե����̾���ɥ饤�֡��ǥ��쥯�ȥ��ޤ�mfn�����ե�����̾")
	   "�Ĥޤꡢ"
	   (pre "-etl-fixed-medium-r-normal--14-105-100-100-m-70-bitmap.7x14-0 g:/bitmap-mule-8.2/font/etl7x14-bitmap.mfn")
	   "�Ȥ��ä����˽񤭴����롣���θ塢�ե�����̾�� FONTSET.OS2"
	   "�Ȥ��Ƥ����HOME������롣")))

   (p "����mfn�����ե�������Ѥ���Τϡ�emacs-20.2 for OS/2�����󤫤�ǡ�"
      "���Ƥξ��������Ȥ��ΤǤϤ���ޤ���ʾܺ٤ϡ����Ȥ���Emacs"
      "����°��Readme�򻲾Ȥ��Ʋ������ˡ�")))

(load "../subpage.scm")
