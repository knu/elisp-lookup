(load "../header.scm")

(define subtitle "����Ƴ��������")
(define updated "$Date$")
(define summary "")

(define subbody
  ##(ol
     ##(li (href "ftp://ftp.m17n.org/pub/mule/apel/")
	   "����ǿ��Ǥ� APEL ���äƤ��롣"
	   ##(p "make install �ǥ��󥹥ȡ��롣"))

     ##(li (href "ftp://ftp.jpl.org/pub/elisp/bitmap/")
	   "����ǿ��Ǥ� bitmap-mule ���äƤ��롣"
	   ##(p "make install �ǥ��󥹥ȡ��롣")
	   ##(p "font/Makefile �� FONTDIR ��Ŭ���˽�������"
		"cd font; make install �ǥե���Ȥ򥤥󥹥ȡ��롣"))

     ##(li "~/.lookup �˼��Τ褦�˽񤤤Ƥ�����"
	   ##(pre "(setq lookup-use-bitmap t)"))))

(load "../subpage.scm")
