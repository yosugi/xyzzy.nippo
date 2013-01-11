; nippo-mode
; programmed by yosugi

(provide "nippo")
(in-package "editor")

(export '(nippo-mode *nippo-mode-map* *nippo-mode-hook*
		  *nippo-save-with-mail* *nippo-default-category*
		  *nippo-log-separate-format* *nippo-directory*
		  *nippo-smtp-server* *nippo-smtp-port*))

; TODO: ���ϐ�
; *nippo-replace-alist*
(defvar *nippo-mode-version* "0.2.0" "�o�[�W����")
(defvar *nippo-mode-name* "nippo" "���̃��[�h�̖��O")
(defvar *nippo-pframe-name* *nippo-mode-name* "�t���[���̖��O")

(defvar *nippo-mode-hook* nil "nippo-mode �t�b�N")
(defvar *nippo-save-with-mail* nil "���[�����M���ɕۑ����邩")

(defvar *nippo-directory* "~/.nippo" "����u����")
(defvar *nippo-default-category* "nippo" "�ŏ��ɏo�Ă���J�e�S��")

(defvar *nippo-smtp-server* nil "smtp �T�[�o")
(defvar *nippo-smtp-port* "25" "smtp �|�[�g")

; �e�t�@�C����
(defvar *nippo-recent-filename* "recent.txt" "�Ō�ɏ���������")
(defvar *nippo-log-filename* "log.txt" "����̃��O")
(defvar *nippo-template-filename* "template.txt" "���[���̃e���v���[�g")

; �e�t�@�C���ւ̃p�X
(defvar *nippo-recent-filepath* nil "�Ō�ɏ���������")
(defvar *nippo-log-filepath* nil "����̃��O")
(defvar *nippo-template-filepath* nil "���[���̃e���v���[�g")

; ����{����u�����鎞�̃^�O
(defvar *nippo-contents-tag* "$CONTENTS" "�{���u���p�^�O")

; ���O�̋�؂�s
(defvar *nippo-log-separate-format* nil "���O�̋�؂�s")

;; �L�[�}�b�v�̒�`
(defvar *nippo-mode-map* nil "nippo-mode �L�[�}�b�v")
(unless *nippo-mode-map*
  (setq *nippo-mode-map* (make-sparse-keymap))
  ; �Z�[�u & ���[�����M
  (define-key *nippo-mode-map* '(#\C-c #\C-c) 'send-nippo-mail)
  ; �Z�[�u
  (define-key *nippo-mode-map* '(#\C-x #\C-s) 'save-nippo-files))

; �J�����g�o�b�t�@��u������
; replace-alist �� �L�[���u������^�O(������)�ŁA
; �l���u����̕����񖔂͕������Ԃ� S ��
(defun replace-buffer-tag (replace-alist)
  "�J�����g�o�b�t�@��u������"

  ; �n�b�V����������Ēu��
  (mapcar
   #'(lambda (replace-element)
	   (let ((tag (car replace-element))
			 (replacement (cdr replace-element)))
		 (beginning-of-buffer)
		 (replace-buffer tag
						 (eval replacement)
						 :regexp nil)))
   replace-alist))

; header-string: �ǉ����镶����
; �߂�l: nil ���s, t ����
(defun nippo-add-header (header-string)
  "�w�b�_�ǉ�"
  (beginning-of-buffer)

  ; �o�b�t�@����s�����Ă���(��s��������w�b�_�͏I���)
  (while (progn
		   (setq current-line (buffer-substring (progn (goto-bol) (point))
												(progn (goto-eol) (point))))
		   (> (length current-line) 0))

	; ��s������O�Ƀt�@�C�����I�������G���[
	(if (null (forward-line)) (return-from nipp-add-header)))

  ; �w�b�_���I��������A��s�̑O�ɕ����������
  (insert header-string))

;TODO: ���֐�
;(nippo-add-replacement)

(defun send-nippo-mail ()
  "���񃁁[���𑗐M"
  (interactive)

  ; �ꉞ�m�F�����Ƃ�
  (if (not (yes-or-no-p "���[���𑗐M���܂���"))
	  (return-from send-nippo-mail))

  ; recent-buffer: ���݂̃o�b�t�@(*nippo-recent-filename* �̃p�b�t�@�ł��鎖������)
  ; template-buffer: �e���|�����o�b�t�@
  (let ((recent-buffer (selected-buffer)) template-buffer)

	; �e���|�����o�b�t�@�����
	(set-buffer (get-buffer-create "*nippo-send-mail*"))
	(setq template-buffer (selected-buffer))

	;; �e���|�����o�b�t�@�̊e��ݒ�
	(erase-buffer (selected-buffer))
	(kill-all-local-variables)
	(make-local-variable 'need-not-save)
	(setq need-not-save t)						; �Z�[�u����K�v�Ȃ�
	(set-buffer-modified-p nil)					; �ύX���ꂽ���o���Ȃ��Ă悵
	(change-fileio-encoding *encoding-jis*)		; ���[���Ȃ̂œ��o�͂� jis ��

	;; ����΃��[���p�e���v���[�g�t�@�C���ǂݍ���
	(if (file-exist-p *nippo-template-filepath*)
		(with-open-file (fp *nippo-template-filepath* :direction :input)
		  (let (line)
			(while (setq line (read-line fp nil))
			  (insert (format nil "~A~%" line)))))

	  ; �Ȃ���ΏI��
	  (progn
		(message-box "�e���v���[�g�t�@�C��������܂���")
		(return-from send-nippo-mail)))

	;; �w�b�_�ǉ�����
	(nippo-add-header
	 (concat
	  (format nil "Date: ~A~%" (format-date-string "%a, %d %b %Y %H:%M:%S %Z"))
	  (format nil "Content-Type: text/plain; charset=ISO-2022-JP~%")
	  (format nil "Mime-Version: 1.0~%")
	  (format nil "X-Mailer: nippo-mode ~A on xyzzy-~A~%"
			  *nippo-mode-version* (software-version))
	  (format nil "X-Yzzy-Version: ~A~%" (software-version))))

	;; ����{����u��
	(beginning-of-buffer)
	(when (scan-buffer *nippo-contents-tag*)
	  (delete-char (length *nippo-contents-tag*))

	  ; ���݈ʒu���珑�����݊J�n
	  (with-output-to-buffer (template-buffer (point))
		(with-input-from-buffer (recent-buffer)
		  (let (line)
			(while (setq line (read-line *standard-input* nil))
			  (map-internal-to-jis (format nil "~A~%" line) *standard-output*))))))

	;; alist ������Ēu��
	(let ((replace-alist))
	  (macrolet ((pushnew-alist (replace-element); replace-alist)
				   `(pushnew ,replace-element replace-alist :key #'car)))
		(pushnew-alist '("$DATE" . (format-date-string "%Y\/%m\/%d")))
		(pushnew-alist '("$YEAR" . (format-date-string "%Y")))
		(pushnew-alist '("$MONTH" . (format-date-string "%m")))
		(pushnew-alist '("$HOGE" . "hoge"))
		(pushnew-alist '("$DAY" . (format-date-string "%d"))))
	  (replace-buffer-tag replace-alist))

	; �w�b�_���� mail from �� ���M����擾
	(let ((recipients (get-mail-header template-buffer '("to" "cc" "bcc")))
		  (mail-from (get-mail-header template-buffer '("from"))))

	  ; from �� to �������Ȃ���΃G���[
	  (unless (and recipients mail-from)
		(message-box "�w�b�_�� from �� to ������܂���")
		(return-from send-nippo-mail))

	  ; ���[���A�h���X�𒊏o
	  (let* ((get-address
			  #'(lambda (str)
				  (string-match "\\([a-zA-Z0-9_.-]+@[a-zA-Z0-9_.-]+\\)" (cdr str))
				  (match-string 1)))

			 ; from �͈�����Ȃ̂� car ���Ă���
			 (from (car (mapcar get-address mail-from)))
			 (to-list (mapcar get-address recipients)))

		;; �o�b�t�@�̃w�b�_������ base64 �G���R�[�h����
		(encode-mail-header template-buffer)

		;; ���[���𑗐M
		(long-operation
		  (message "~A" "sending...")
		  (unless (send-mail *nippo-smtp-server* *nippo-smtp-port*
							 (buffer-substring (point-min) (point-max))
							 from
							 to-list)

			; ���M�Ɏ��s�����烁�b�Z�[�W��\�����ďI��
			(message "~A" "sending...failed")
			(message-box "���M�ł��܂���ł���")
			(return-from send-nippo-mail))

		  ; ����܂���
		  (message "~A" "sending...done"))))

	; ���̃o�b�t�@�ɖ߂��āA���M�p�o�b�t�@�͍폜
	(set-buffer recent-buffer)
	(delete-buffer template-buffer)

	; ���M���Ƀ��O��ۑ�
	(if *nippo-save-with-mail*
		(save-nippo-files))))

(defun save-nippo-files ()
  "����t�@�C�����Z�[�u"
  (interactive)

  ; ���݂̃o�b�t�@�̓��e�� nippo-recent.txt �ɕۑ�
  (save-buffer *encoding-jis* *eol-crlf*)

  ; �Θb�I�ɌĂ΂ꂽ���̂݊m�F�_�C�A���O���o��
  (if (and (interactive-p)
		   (not (yes-or-no-p "���O��ۑ����܂���")))
	  (return-from save-nippo-files))

  ; nippo-log.txt �ɃZ�p���[�^�E�w�b�_����������
  (with-open-file (fp *nippo-log-filename*
					  :direction :output
					  :if-exists :append
					  :if-does-not-exist :create)

	(format fp "~%~A~%"
			(format-date-string (or *nippo-log-separate-format*
									"= ����: %y�N%m��%d��(%v)"))))

  ; ���݂̃o�b�t�@�̓��e�� log.txt �ɒǉ���������
  (append-file *nippo-log-filename* t *encoding-sjis* *eol-crlf*)
  (message "~A~%" "save complete"))

(defun chop (str)
  "��������󂯎���āA�Ō�̈ꕶ�������������̂�Ԃ�"
  (if (stringp str)
	  (substring str 0 (- (length str) 1))))

(defun nippo-mode ()
  "nippo-template ��ǂݍ���ŐV�����t���[���ŕ\��"
  (interactive)
  ; �e��t�@�C����ǂݍ��ރf�B���N�g��������
  ; nippo-category-dir: �J�e�S���̃f�B���N�g����
  (let (nippo-category-dir)
	(let (category)

	  ; ~/.nippo �ȉ��ɂ���f�B���N�g�������擾
	  (setq category
			(completing-read "category: "

							 ; �f�B���N�g�����X�g���� "/" �������������⊮�Ώ�
							 (mapcar #'(lambda (dir) (chop dir))
									 ; *nippo-directory* �ȉ��̃f�B���N�g�����擾
									 (directory *nippo-directory* :directory-only t))
							 :case-fold t
							 :default *nippo-default-category*))

	  ; �f�B���N�g������ݒ�
	  (setq nippo-category-dir (merge-pathnames category *nippo-directory*)))

	; �e�t�@�C�����̐ݒ�
	(setq *nippo-recent-filepath*
		  (merge-pathnames *nippo-recent-filename* nippo-category-dir))
	(setq *nippo-log-filepath*
		  (merge-pathnames *nippo-log-filename* nippo-category-dir))
	(setq *nippo-template-filepath*
		  (merge-pathnames *nippo-template-filename* nippo-category-dir)))

  ; �V�����t���[��������Ė��O��t����
  (new-pseudo-frame *nippo-pframe-name*)

  ; ���O�ɏ������t�@�C����ǂݍ���
  (find-file *nippo-recent-filepath*)
  (kill-all-local-variables)

  ; ���[�h�p�̐ݒ�
  (setq mode-name "nippo")
  (setq buffer-mode 'nippo-mode)
  (use-keymap *nippo-mode-map*)
  (run-hooks '*nippo-mode-hook*))

; host: MTA
; port: �|�[�g
; send-str: ���M���镶����
; mail-from: mail from
; recipients : ���M��(����)
(defun send-mail (host port send-str mail-from recipients)
  "���[���𑗐M����"
  ; �|�[�g�ԍ����Ȃ���΃f�t�H���g�l������
  (if (null port) (setq port 25))
  (with-open-stream (stream (connect host port))

	; command �𑗐M���Ċ��҂��鉞���R�[�h������
	(flet ((send-cmd (command expect-code)
			 (let (ret-code)
			   
			   ; nil �łȂ���� command �𑗐M
			   (unless (null command)
				 (format stream "~A" command))

			   ; �������󂯎��
			   (let ((reply (read-line stream nil)))
				 (with-open-file (fp "~/log.txt"
									 :direction :output
									 :if-exists :append
									 :if-does-not-exist :create)
				   (format fp "send: ~A~%" command)
				   (format fp "recv: ~A~%" reply))

				 ; ���������҂���R�[�h�łȂ���΃G���[
				 (if (equal (substring reply 0 3) (format nil "~3,'0D" expect-code))
					 reply
				   (return-from send-mail))))))

	  ; ���[���𑗐M����
	  (send-cmd nil 220)	; �ڑ��������̉���������
	  (send-cmd (format nil "HELO ~A\n" (socket-stream-local-name stream)) 250)
	  (send-cmd (format nil "MAIL FROM: <~A>\n" mail-from) 250)

	  ; rcpt to �𑗂�
	  (mapcar #'(lambda (recipient)
				  (send-cmd (format nil "RCPT TO: <~A>\n" recipient) 250))

			  ; ������Ȃ烊�X�g�ɂ��A���X�g�Ȃ炻�̂܂ܓn��
			  (if (stringp recipients)
				  (list recipients)
				recipients))

	  ; �h�b�g�X�^�b�t�B���O���Ė{���𑗐M
	  (send-cmd (format nil "DATA\r\n") 354)
	  (with-input-from-string (instr send-str)
		(let (line)

		  ; �����񂪂�������s���ǂݍ���
		  (while (setq line (read-line instr nil))

			; �h�b�g�X�^�b�t�B���O������
			(if (equal "." line)
				(format stream "..~%")
			  (format stream "~A~%" line)))))
	  
	  ; �Ō�� . �𑗐M���ďI��
	  (send-cmd ".\n" 250)
	  (send-cmd "QUIT\n" 221))))

;; �w�b�_�� ascii �ȊO�̕���������� base64 �� mime �G���R�[�h����
;; �w�肳�ꂽ�o�b�t�@��ǂݍ���ŁA�����̓��e������������
;; �����R�[�h�� JIS �ł��鎖������
;; folding �Ȃǂ͍l�����Ă��Ȃ�
(defun encode-mail-header (buffer)
  "���[���w�b�_�̃G���R�[�h"

  ; ���̃o�b�t�@��ۑ����Ƃ�
  (let ((old-buffer (selected-buffer)))
	(set-buffer buffer)
	(goto-char (point-min))

	; �ŏ��̈�s�����擾
	(let ((current-line (buffer-substring (progn (goto-bol) (point))
										  (progn (goto-eol) (point)))))

	  ; �o�b�t�@����s�����Ă���(��s��������w�b�_�͏I���)
	  (while (> (length current-line) 0)

		; �w�b�_�̏����Ƀ}�b�`���Ȃ������玟��
		(when (string-match
			   (concat "[" ed::*ascii-chars-range* "]+:[ \t]*\\(.*\\)$")
			   current-line)

		  ; field-body: �w�b�_�̓��e(':' �̌�)
		  ; begin-body: �w�b�_�{�f�B�̐擪�|�C���g
		  (let ((field-body (match-string 1))
				(begin-body (match-beginning 1)))

			; ascii �ȊO�̂��̂������Ă���΃G���R�[�h���ď���������
			(unless (string-match
					 (concat "^[" ed::*ascii-chars-range* " \t]+$")
					 field-body)

			  ; �w�b�_�{�f�B�̈ʒu�Ɉړ����āA���݈ʒu��ۑ�
			  (goto-bol) (forward-char begin-body)
			  (let ((begin-body-buffer (point)))

				; �w�b�_ body ���폜
				(delete-region begin-body-buffer (progn (goto-eol) (point)))
				(goto-char begin-body-buffer)

				; base64 & mime �G���R�[�h�������̂�}��
				(insert (concat "=?ISO-2022-JP?B?"

								; �Ō�ɉ��s������̂� trim ���Ƃ�
								(string-trim "\n" (si::base64-encode field-body))
								"?="))))))

		; 1 �s���Ɉړ�(�ŏI�s�������炻���ŏI��)
		(if (null (forward-line)) (return))

		; ���̍s���擾
		(setq current-line (buffer-substring (progn (goto-bol) (point))
											 (progn (goto-eol) (point))))
		(goto-bol)))

	; ���̃o�b�t�@�ɖ߂�
	(set-buffer old-buffer)))

; buffer: ����Ă���o�b�t�@
; headers: ����Ă���w�b�_���̃��X�g(nil �Ȃ�S������Ă���)
(defun get-mail-header (buffer headers)
  "���[���̃w�b�_���擾"
  ; ���̃o�b�t�@��ۑ����Ƃ�
  (let ((old-buffer (selected-buffer)))
	(set-buffer buffer)
	(goto-char (point-min))

	; �ŏ��̈�s�����擾
	(let ((current-line (buffer-substring (progn (goto-bol) (point))
										  (progn (goto-eol) (point))))
		  (header-alist nil))

	  ; �o�b�t�@����s�����Ă���(��s��������w�b�_�͏I���)
	  (while (> (length current-line) 0)
		; �w�b�_�̏����Ƀ}�b�`���Ȃ������玟��
		(when (string-match
			   (concat "\\([" ed::*ascii-chars-range* "]+\\):[ \t]*\\(.*\\)$")
			   current-line)

		  ; �w�b�_���ƒl��g�ɂ����A�z���X�g�����
		  (push (cons (match-string 1) (match-string 2)) header-alist))

		; 1 �s���Ɉړ�(�ŏI�s�������炻���ŏI��)
		(if (null (forward-line)) (return))
		; ���̍s���擾
		(setq current-line (buffer-substring (progn (goto-bol) (point))
											 (progn (goto-eol) (point)))))

	  ; ���N�G�X�g���������w�b�_�̂ݕԂ�
	  (if headers
		  (intersection header-alist headers :test #'(lambda (x y)
													   (equalp (car x) y)))
		header-alist))))
