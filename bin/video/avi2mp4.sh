#!/usr/bin/sh
alias mediainfo='/programs/MediaInfo/MediaInfoCli.exe'
shopt -s extglob
trap exit HUP INT QUIT TERM
_exit() { : ; }
trap _exit EXIT
run() {
	typeset arg= args=$1
	shift
	for arg; do
		case $arg in
		-*|\<|\>) args="$args $arg" ;;
		*\'*) args="$args \"$arg\"" ;;
		# *\'*) args=${args//"'"/\\"'"}; args="$args '$arg'" ;;
		*) args="$args '$arg'" ;;
		esac
	done
	echo ">>> $args" >&3
	eval "$args"
}
exec 3>&1
optt=s: optd= optf= optF=0 optm=0 optn=0 optM=0 optl= opta= opts= opto= optS=0
while getopts a:d:f:Fl:mMno:St:x c; do
case $c in
a) opta=$OPTARG ;;
d) optd=$OPTARG ;;
f) optf=$OPTARG ;;
F) optF=1 ;;
l) optl=$OPTARG ;;
m) optm=1 ;;
M) optM=1 ;;
n) optn=1 ;;
o) opto=$OPTARG ;;
s) opts=$OPTARG ;;
S) optS=1 ;;
t) optt=$OPTARG ;;
x) set -x ;;
*) echo "\
usage: ${0##*/} [-FMmnSx] [-a audio] [-d delay] [-f fps] [-l lang]
		[-s subtitle] [-t x:] [-o dir] [file...]
    -F	force overwrite existing .mp4
    -M  force extract through mp4box
    -m	force extract through mkvmerge/mkvextract
    -n  keep temp files
    -s  no subtitle
    -x	trace
"; exit 1 ;;
esac
done
shift $(( OPTIND - 1 ))
(( $# )) || set -- *.avi *.mkv *.flv *.ts
for avi; do
	[[ ${avi} = \*.@(avi|mkv|mp4|flv|ts) ]] && continue
	[[ ${avi} = *.@(avi|mkv|mp4|flv|ts) ]] || continue
	#[[ ${avi} = *"'"* ]] && avi=${avi//"'"/\\"'"}
	file=${avi%.@(avi|mkv|mp4|flv|ts)}; ofile=${file}
	[[ ${avi} = *.mp4 ]] && file=${file}-muxed
	mp4=${file}.mp4
	[[ -n ${opto} ]] && mp4=${opto}/${mp4##*/}
	(( ! optF )) && [[ -f ${mp4} ]] && continue
	echo "===>>> "${avi}" <<<==="
	[[ ${avi} = *.mkv ]] && rc=-1 || rc=${optm}
	[[ -f ${ofile}.fr.srt ]] && srt="${ofile}.fr.srt" || srt=
	case ${file} in
	*.ENG*.FR*|*VOST*) langv=fra langa=eng ;;
	*.ENG|*[-.\ ]VO*) langv=eng langa=eng ;;
	*) langv=fra langa=${optl:-fra} ;;
	esac
	langv=:lang=${langv} langa=:lang=${langa}
	fps= delay= exta= extv=avi mpeg4= exts= reason= chap=
	eval $(mediainfo "${avi}" |
	awk -v optd=${optd} -v optf=${optf} -v opta=${opta} -v opts=${opts} '
/^Video$/ { getline; idv = $NF ~ /[(]/ ? "" : $NF; next }
/^Audio$/ { getline; if (!ida) ida = $NF ~ /[(]/ ? "" : $NF; next }
/^Text/ { getline; if (!ids) ids = $NF; next }
/^Menu$/ { chap = " "; next }
/Frame rate/&&/fps$/ { fps = $(NF-(1+/\//)); next }
/Delay relative to video/ { sub(/ms/,"",$NF); delay = $NF; next }
/Matrix/&&/Custom/ { extv = " "; reason = "\"Custom Matrix\""; next }
/Format|Codec ID/&&/DIV3/ { extv = " "; ; reason = "DIV3"; next }
/Format/&&/AVC/ { extv = "264"; next }
/Format/&&/HEVC/ { extv = "265"; next }
/Format/&&/AAC/ { exta = "aac"; next }
/Format/&&/AC-3/ { exta = "ac3"; next }
/Format/&&/UTF-8/ { exts = "srt"; next }
/Format/&&/Layer 2/ { exta = "mp2"; next }
/Codec ID/&&/MP3|mp3|55|6[9B]/ { exta = "mp3"; cid=$NF; next }
/Format/&&/WMA/ { exta = "wma"; next }
/Format/&&/Vorbis/ { exta = "ogg"; next }
END {
	_1 = idv != "" && idv
	if (reason) { print "reason=" reason; exit }
	if (optd) delay = optd
	if (optf) fps = optf
	print "idv=" ((idv != "" ? idv : 0) - _1)
	print "ida=" (opta != "" ? opta : ((ida != "" ? ida : 1) - _1))
	if (cid) print "cid=" cid
	if (ids) print "ids=" (opts != "" ? opts : (ids - _1))
	if (exta) print "exta=" exta
	if (extv) print "extv=" extv
	if (exta ~ /mp3|wma|ogg/) print "mpeg4=:mpeg4"
	if (exts) print "exts=" exts
	if (delay) print "delay=:delay=" delay
	if (fps) print "fps=:fps=" fps " tsc=:timescale=" fps * 1000
	if (chap) print "chap=:chap"
}
')
	[[ -n ${reason} ]] && echo "$reason" && continue
	[[ -z ${extv} ]] && continue
	(( ${optS} )) && exts=
	(( rc < 0 )) && orc=${rc} || orc=
	[[ -n ${optM} || ${extv} = 26[45] || ${exts} = srt || -n ${chap} ]] && rc=${orc:-1}
	comment="${idv}:${extv}${fps}${tsc}${langv} ${ida}:${exta}${delay}${langa}${mpeg4}${ids:+ ${ids}:${exts}}${chap:+ ${chap}}"
	echo "${comment}${cid:+ ($cid)}"
	_fps=${fps}
	if (( ! rc )); then
		run \
		mp4box -tmp "${optt}\\temp" \
		       -add "${avi}#video${langa}${_fps}${tsc}:name=" \
		       -add "${avi}#audio${langv}${delay}${mpeg4}:name=" \
		       ${srt:+-add "${srt}#trackid=1:lang=fra:name="} \
		       -itags "comment=${comment}" \
		       -new "${mp4}"
		rc=$?
	fi
	if (( rc )); then
		[[ -z ${exta}${extv} ]] && continue
		[[ -n ${exts} ]] && srt="${ofile}.fr.srt"
		[[ -n ${chap} ]] && chap="${ofile}.chap"
		mkv="s:\\temp\\${file##*/}.mkv"
		vid="e:\\temp\\${file##*/}_${fps#:}.${extv}"
		aud="e:\\temp\\${file##*/}_${delay#:}.${exta}"
		wav= ac3=
		(( optn )) ||
		_exit() {
			[[ -z ${mkv} ]] && return
			(( rc < 0 )) || rm -f "${mkv}"
			[[ -n ${avi} ]] && rm -f "${vid}"
			rm -f "${aud}";
			for file in "${wav}" "${mp3}" "${ac3}" "${chap}"; do
				[[ -n ${file} ]] && rm -f "${file}"
			done
			mkv= # eof
		}
		if [[ ${exta} = @(wma|ogg) ]]; then
			aud=${aud%.${exta}}; wav=${aud}.wav aud=${aud}.mp3
			run \
			ffmpeg -hide_banner -v info -i "${avi}" -vn -y "${wav}"
			run \
			lame --abr 96 -h "${wav}" "${aud}" 2>&1 |
			egrep -v '%|--|\[.+\]'
			vid=${avi}; avi=
			#mkvmerge -o "${mkv}" -A "${avi}" --compression 0:none --default-duration 0:${fps#:fps=}fps
			#mkvextract tracks "${mkv}" "0:${vid}"
		elif (( optM )); then
			(( idv += 1, ida += 1 ))
			run \
			mp4box -avi ${idv} -out "${vid}" "${avi}"
			run \
			mp4box -raw ${ida} -out "${aud}" "${avi}"
		else
			(( rc < 0 )) && mkv=${avi} || { : idv=0 ida=1;
			run \
			mkvmerge -o "${mkv}" "${avi}" --compression 0:none --default-duration 0:${fps#:fps=}fps; }
			run \
			mkvextract tracks "${mkv}" "${idv}:${vid}" "${ida}:${aud}" ${exts:+"${ids}:${srt}"}
			[[ -n ${chap} ]] &&
			run \
			mkvextract chapters "${mkv}" -s \> "${chap}"
			#[[ ${exta} = mp3 ]] &&
			#mp3=${aud} && aud=${aud/.${exta}/.mp4} &&
			#ffmpeg -i "${mp3}" -vn -acodec copy "${aud}"
			if [[ ${exta} = ac3 ]]; then
				ac3=${aud}
				wav=${aud/.${exta}/.wav}
				aud=${aud/.${exta}/.aac}
				run \
				ffmpeg -hide_banner -v info -i "${ac3}" -vn -y "${wav}"
				run \
				neroAacEnc -ignorelength -lc -br 128000 -if "${wav}" -of "${aud}"
			fi
		fi
		run \
		mp4box -tmp "d:\\temp" \
		       -add "${vid}#trackid=1${langv}${_fps}${tsc}:name=" \
		       -add "${aud}#trackid=1${langa}${delay}${mpeg4}:name=" \
		       ${srt:+-add "${srt}#trackid=1:lang=fra:name="} \
		       ${chap:+-add "${chap}:chap"} \
		       -itags "comment=${comment}" \
		       -new "${mp4}"
		_exit
	fi
done

# eof
