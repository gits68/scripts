#!/usr/bin/sh

shopt -s extglob

mediainfo=/programs/MediaInfo/MediaInfoCli.exe
avimuxgui=/programs/megui/tools/avimux_gui/AVIMux_GUI.exe

trap exit HUP INT QUIT TERM
# _exit() { [[ -n ${tmp} ]] && rm -f "${tmp}" "${mp3}" "${cfg}"; tmp=; }
_exit() { : ; }
trap _exit EXIT

(( $# )) || set -- *.mp4
for mp4; do
	[[ ${mp4} = /* ]] || mp4=$PWD/${mp4}
	mp4=$(cygpath -w "${mp4}")
	echo "<<< ${mp4}"
	[[ ${mp4} = *.mp4 ]] || continue
	delay=0 exta=
	eval $("${mediainfo}" "${mp4}" | awk '
	/Delay relative to video/ { sub(/ms/,"",$NF); delay = $NF; next }
	/Codec ID/&&/MP3|mp3|55|6B/ { exta = "mp3"; next }
	END {
		if (exta) print "exta=" exta
		if (delay) print "delay=" delay
	}')
	[[ ${exta} = mp3 ]] || continue
	case ${file} in
	*.ENG*.FR*|*VOST*) langa=English ;;
	*.ENG|*[-.\ ]VO*) langa=English ;;
	*) langa=French ;;
	esac
	langa=${langa}
	echo delay=$delay langa=$langa
	file=${mp4%.mp4}
	avi=${file}.avi
	[[ -f ${avi} ]] && echo "=== ${avi}" && continue
	[[ -n ${WTEMP} ]] && file=${WTEMP}\\${file##*[/\\]}
	cfg=${file}.mux
	tmp=${file}_track1.avi
	mp3=${file}_track2.mp3
	mp4box -avi 1 -out "${tmp}" "${mp4}"
	mp4box -raw 2 -out "${mp3}" "${mp4}"
	[[ -f ${mp3} ]] || continue
	cat > "${cfg}" << EOF
CLEAR
LOAD ${tmp}
LOAD ${mp3}
SELECT FILE 1
ADD VIDEOSOURCE
DESELECT FILE 1
SET OUTPUT OPTIONS
WITH SET OPTION
WITH AUDIO
NAME 1 ${langa}
END WITH
DELAY 1 ${delay}
NUMBERING OFF
CLOSEAPP 1
DONEDLG 0
OVERWRITEDLG 0
ALL AUDIO 1
PRELOAD 200
OPENDML 0
RECLISTS 0
AUDIO INTERLEAVE 4 FR
END WITH
SET INPUT OPTIONS
WITH SET OPTION
MP3 VERIFY CBR ALWAYS
MP3 VERIFY RESDLG OFF
AVI FIXDX50 1
END WITH
START ${avi}
EOF
	echo ">>> ${avi}"
	unix2dos -q "${cfg}"
	"${avimuxgui}" "${cfg}"
	_exit
done
