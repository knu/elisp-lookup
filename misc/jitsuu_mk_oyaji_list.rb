#! ruby -Ks

# make_oyaji_list.rb
# ���ʂ̖{���f�[�^�Ɛe���������o�����X�g����
# �ǂݕt�����o�����X�g�𐶐�����

# simplify_font: �����\�L�̃t�H���g�w����ȗ�������
def simplify_font(kanji)
    kanji.gsub!(/<\/ST>/, "�t")
    kanji.gsub!(/<ST,(12|13|14|51)>/, "�s<\\1>")
    kanji.gsub!(/<ST,2([45])>/, "�s<2\\1>")
    kanji.gsub!(/<ST,(11|3[345]|41)>/, "�s<11>")
    kanji.gsub!(/<ST,[0-9]+>/, "�s")
    kanji.gsub!(/�s(�m|�n|�i|�j)�t/,'\1')
end
#def simplify_font(kanji)
#    kanji.gsub!(/<\/ST>/, "")
#    kanji.gsub!(/<ST,(12|13|14|51)>/, "<\\1>")
#    kanji.gsub!(/<ST,2([45])>/, "<2\\1>")
#    kanji.gsub!(/<ST,(11|3[345]|41)>/, "<11>")
#    kanji.gsub!(/<ST,[0-9]+>/, "")
#end

# decrypt: dat/lst�G���g���̓��e�𕽕��ɂ���
def decrypt(ent, len)
    # �擪����4�̔{���o�C�g�̂������A4�o�C�g���Ƃ�
    # 4�o�C�gBE�̒l�Ƃ݂Ȃ���0xffffffff��XOR���A
    # �����0x8831b311�𕄍��Ȃ����Z����
    len4 = len & ~3
    arr = ent[0, len4].unpack("N*")
    arr.length.times { |i|
	arr[i] = ((arr[i] ^ 0xffffffff) + 0x8831b311) & 0xffffffff
    }
    ent[0, len4] = arr.pack("N*")

    # �]��̃o�C�g��0xff��XOR����
    i = len4
    while i < len
	ent[i] ^= 0xff
	i += 1
    end

    # 0x00��0xff�̒��O�܂ł����ʂƂ��ĕԂ�
    i = 0
    while i < len && ent[i] != 0x00 && ent[i] != 0xff
	i += 1
    end
    return ent[0, i]
end

# get_yomi: dat�G���g����2�s��(�ǂ�)�����o��
def get_yomi(ent)
    n1 = ent.index(0x0d)
    n2 = ent.index(0x0d, n1 + 1)
    return ent[n1 + 1 ... n2]
end

# add_yomi_tag: <yomi>�^�O���G���g���ɕt������B
def add_yomi_tag(yomi)
  yomi.gsub!(/�n|�E/,'\&<yomi>')
  yomi.gsub!(/(�@?�m���P�n)|�E|�i|\z/,'</yomi>\&')
end

# ���C��

# dat/lst�t�@�C����
HONMON_DAT = "dat/honmon.dat"
OYAJI_LST = "lst/oyaji.lst"

# dat/lst�t�@�C�����I�[�v������
if ARGV[0] == nil then
    STDERR.print "Usage: make_oyaji_list.rb data_directory\n"
    exit(1)
end
dat_path = ARGV[0] + "/" + HONMON_DAT
lst_path = ARGV[0] + "/" + OYAJI_LST
begin
    datf = File.open(dat_path, "rb")
    lstf = File.open(lst_path, "rb")
rescue
    STDERR.print "Can't open dat/lst files\n"
    exit 1
end

# dat/lst�G���g�������擾����
ent_num = datf.read(4).unpack("V1")[0]

# dat�G���g���\��ǂݍ���
dat_pos = Array.new(ent_num)
dat_len = Array.new(ent_num)
ent_num.times { |i|
    dat_pos[i] = datf.read(4).unpack("V1")[0]
    dat_len[i] = datf.read(4).unpack("V1")[0]
}

# lst�G���g���T�C�Y/������T�C�Y���擾����
lstf.seek(16, IO::SEEK_SET)
lst_ent_len = lstf.read(4).unpack("V1")[0]
lst_str_len = lstf.read(4).unpack("V1")[0]
lstf.seek(32, IO::SEEK_SET)

# dat/lst�G���g����S���ǂ݁A
# �G���g���ԍ��ƂƂ��ɐ��`���ďo�͂���
ent_num.times { |i|
    # lst�G���g����ǂ�ŕ����ɂ���
    list = lstf.read(lst_str_len)
    list = decrypt(list, lst_str_len)
    dummy = lstf.read(lst_ent_len - lst_str_len)

    # �����\�L�̃t�H���g�w����ȗ�������
    simplify_font(list)

    # dat�G���g����ǂ�ŕ����ɂ��A2�s�ڂ��������o��
    # �{���ŕK�v�Ȃ̂�2�s�ڂ����Ȃ̂Ő擪160�o�C�g�����ǂ�
    datf.seek(dat_pos[i], IO::SEEK_SET)
    data = datf.read(160)
    data = decrypt(data, 160)
    data = get_yomi(data)
    data = add_yomi_tag(data)

    # lst�G���g����dat�G���g�����o�͂���
    printf "%04d %s %s\n", i+1, list, data
}

# ��n��
datf.close
lstf.close
