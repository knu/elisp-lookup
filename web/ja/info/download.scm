(set! %load-path (cons "../.." %load-path))
(use-modules (htmlgen))

(define name "Download Sites")
(define subtitle "��������ɥ����Ȱ���")
(define date "$Date$")

(define summary
  (p "Lookup ��Ϣ�Υ��������֤ϰʲ��ΤȤ���˥ߥ顼����Ƥ��ޤ���"
     "���᤯�Υ����Ȥ�����ǥ�������ɤ��Ʋ�������"))

(define subbody
  (string-append
   (h3 "Sourceforge")
   (ul
    (li (href "http://download.sourceforge.net/lookup/") "(lookup-1.x �Τ�)"))

   (h3 "Ring Servers")
   (ul
    (li (href "ftp://core.ring.gr.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.etl.go.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.asahi-net.or.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.crl.go.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.astem.or.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.jah.ne.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.nacsis.ac.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.exp.fujixerox.co.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.so-net.ne.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.ip-kyoto.ad.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.iwate-pu.ac.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.shibaura-it.ac.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.ocn.ad.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.htcn.ne.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.omp.ad.jp/pub/text/elisp/lookup/"))
    (li (href "ftp://ring.jec.ad.jp/pub/text/elisp/lookup/"))
    )))

(load "../subpage.scm")
