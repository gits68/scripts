#!/usr/bin/sh
# Copyright (c) 2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

shopt -s extglob

mediainfo='/programs/MediaInfo/MediaInfoCli.exe'
avimuxgui='/programs/megui/tools/avimux_gui/AVIMux_GUI.exe'

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
