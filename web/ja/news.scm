(define items
  '(
    ("�᡼��󥰥ꥹ�ȤΥ��ɥ쥹�ѹ�" "2001-06-19"
     ##(a #:href "lists/" "Lookup �᡼��󥰥ꥹ��")
     "�Υ��ɥ쥹���ڤ� subscribe/unsubscribe �λ������ѹ��ˤʤ�ޤ�����")

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
