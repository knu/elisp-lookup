(set! %load-path (cons "../.." %load-path))
(use-modules (htmlgen))

(define name "Screenshot")
(define subtitle "�����꡼�󥷥�å�")
(define date "$Date$")

(define subbody
  (string-append
   (img "jitenban97.gif")
   (p "������������"
      (href "�ؼ���ŵ����97��" "http://www.ascii.co.jp/pb/jitenban/")
      "��긡����")
   (hr)
   (img "aiai.jpg")
   (p "ʿ�޼ҡإޥ��ڥǥ���99�٤�긡��")))

(load "../subpage.scm")
