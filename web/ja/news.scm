(define items
  '(
    ("ndic sass support" "2000-11-11"
     "Yoishiro Okabe ����ˤ�ꡢndic �� sass �򥵥ݡ��Ȥ��뤿���"
     ##(a #:href "contrib/sdicf.el.sass.patch" "�ѥå�")
     "����������ޤ�����")

    ("Auto Lookup ��꡼��" "2000-10-13"
     ##(a #:href "http://www.aist-nara.ac.jp/~masata-y/autolookup/index.html"
	  "Auto Lookup")
     "�ϡ�Lookup ��Ȥäƥ������벼�α�ñ���ưŪ��Ĵ�٤ƥߥ˥Хåե���"
     "��̤�ɽ�����Ƥ����ץ����Ǥ���")

    ("FreePWING �ˤ�� JIS X 4081 �ǳƼＭ��" "2000-09-01"
     ##(a #:href "http://openlab.ring.gr.jp/edict/fpw/"
	  "FreePWING ��������ۥڡ���")
     "���ŻҼ��񥪡��ץ��ܤ˺�������ޤ�����")

    ("srd-fpw 1.1.1" "2000-08-25"
     ##(a #:href "http://openlab.ring.gr.jp/edict/srd-fpw/" "srd-fpw")
     "�Ȥϡ����شۡإ�����ϥ����Ѹ켭ŵ�٤� EPWING �������Ѵ����뤿���"
     "������ץȤǤ���")

    ("��ǽ�����ǡֿ����¡��±��漭ŵ��" "2000-07-12"
     "DeAGOSTINI��PC Success���� 24 ��(1324��)����Ͽ�Ȥ��ơ�"
     "����ҡֿ����¡��±��漭ŵ�פε�ǽ�����Ǥ��դ��Ƥ��뤽���Ǥ���"
     "�������׸���������ޤ��󤬡�Lookup �Ǥ����ѽ����褦�Ǥ���")

    ("mypaedia-fpw 1.4.1" "2000-07-14"
     ##(a #:href "http://openlab.ring.gr.jp/edict/mypaedia-fpw/"
	  "mypaedia-fpw")
     "�Ȥϡ�ʿ�޼Ҥξ���ɴ�ʻ�ŵ�إޥ��ڥǥ����٤� EPWING �������Ѵ�����"
     "����Υ�����ץȤǤ���DeAGOSTINI ����ȯ�䤵��Ƥ����PC Success�٤�"
     "�ϴ���(500��)�ˤϡ��إޥ��ڥǥ���99�٤ε�ǽ�����Ǥ���°���Ƥ��ޤ���")

    ("FreePWING 1.2.1" "2000-07-07"
     ##(a #:href "http://www.sra.co.jp/people/m-kasahr/freepwing/" "FreePWING")
     "�Ȥϡ��ƼＭ��ǡ����� EPWING �������Ѵ����뤿��Υġ���Ǥ���"
     "�����Ĥ��Υե꡼�ʼ���ǡ������������Ƥ��ޤ���")

    ("wdic-fpw 1.1" "2000-06-24"
     ##(a #:href "http://member.nifty.ne.jp/~satomii/freepwing/indexj.html"
	  "wdic-fpw")
     "�Ȥϡ��ե꡼���̿��Ѹ콸"
     "��" ##(a #:href "http://www.wdic.org/" "�̿��Ѹ�δ����μ�") "�٤�"
     "EPWING �������Ѵ����뤿��Υ�����ץȤǤ���")

    ("Unix �ǻȤ����ŻҼ������" "2000-05-09"
     ##(a #:href "http://openlab.ring.gr.jp/edict/" "�ŻҼ��񥪡��ץ���")
     "���顢"
     ##(a #:href "http://openlab.ring.gr.jp/edict/info.html"
	  "Unix �ʤɤǻȤ����ŻҼ���ξ���")
     "����������Ƥ��ޤ������줫���ŻҼ�����㤪���ȻפäƤ�������"
     "�ɤ��ŻҼ�����㤪�����¤äƤ������ϥ����å����Ƥߤޤ��礦��")
    ))

(define (news-item->html item)
  (let ((title (car item))
	(date (cadr item))
	(info (apply string-append
		     (map (lambda (x) (eval x (current-module)))
			  (cddr item)))))
    ##(li ##(p ##(font #:color "#3366cc" ##(b title))
	       " (" date ")" ##(br info)))))

(define news
  ##(ul (apply string-append (map news-item->html items))))
