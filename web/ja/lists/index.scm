(set! %load-path (cons "../.." %load-path))
(use-modules (htmlgen))

(define name "Mailing Lists")
(define subtitle "�᡼��󥰥ꥹ�Ȱ���")
(define date "$Date$")

(define summary
  (p "Lookup �˴�Ϣ���ơ��ʲ��Τ����Ĥ��Υ᡼��󥰥ꥹ�Ȥ�����ޤ���"))

(define subbody
  (string-append
   (dl
    (dt "lookup-ja@ring.gr.jp")
    (dd "Lookup �˴ؤ������򴹤�Ԥʤ�����Υ᡼��󥰥ꥹ�ȤǤ���"
	"���ä��˾��������ϡ�"
	(href "lookup-ja-request@ring.gr.jp"
	      "mailto:lookup-ja-request@ring.gr.jp")
	"���Ƥˡ���ʸ�� \"subscribe\" �Ƚ񤤤��᡼������äƲ�������")
    (ul
     (li (href "����������" "http://news.ring.gr.jp/news/openlab.lookup-ja/"))
     (li (href "�˥塼�����롼��" "news://news.ring.gr.jp/ring.openlab.lookup-ja")))
    (br)
    (dt (href "edict ML" "/openlab/edict/"))
    (dd "�ŻҼ�����̤ˤĤ��ƾ���򴹤�Ԥʤ�����Υ᡼��󥰥ꥹ�ȤǤ���"
	"Lookup �˴ط���������Ȥ�����ή��ޤ���")
    (ul
     (li (href "����������" "http://news.ring.gr.jp/news/openlab.edict/"))
     (li (href "�˥塼�����롼��" "news://news.ring.gr.jp/ring.openlab.edict")))
    (br)
    (dt (href "NDTPD" "http://www.sra.co.jp/people/m-kasahr/ndtpd/"))
    (dd "NDTPD �Υ᡼��󥰥ꥹ�ȤǤ� Lookup ��Ϣ�����꤬�Ф뤳�Ȥ�����ޤ���"
	"�ä˻��Τ� CD-ROM ��������Ѥ��Ƥ����硢NDTPD �Υ᡼��󥰥ꥹ�Ȥˤ�"
	"���ä���뤳�Ȥ򤪴��ᤷ�ޤ���"))))

(load "../subpage.scm")
