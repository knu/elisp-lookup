(set! %load-path (cons "../.." %load-path))
(use-modules (htmlgen))

(define name "Related Links")
(define subtitle "Lookup TIPS")
(define date "$Date$")

(define summary (p "Lookup ��Ȥ���Ǥ����ʾ���"))

(define subbody
  (string-append
   (ul
    (li "�Ƕ�� Emacs ���ȡ�<tt>lookup-pattern</tt>"
	"��ɽ�������ǥե���Ȥ�ʸ����� <tt>M-n</tt>"
	"���Խ������褦�ˤʤ롣����äȽ����������Ȥ���������")
    (li "�ѿ� <tt>gc-cons-threshold</tt> ���ͤ�ǥե���Ȥ���"
	"�礭�����Ƥ�����(10�ܤ��餤)��GC �����٤����äƥץ�����"
	"�ɤ߹��ߡ��¹�®�٤����ʤ��᤯�ʤ롣")
    (li "EPWUTIL �� catdump ��Ȥä�ʣ���� EPWING ������ĤΥǥ��쥯�ȥ��"
	"�ޤȤ��ȡ�eblook �Υץ�������ĤǺѤ�Τǥ����ƥ����٤�"
	"�������������뤫�⡣"))))

(load "../subpage.scm")
