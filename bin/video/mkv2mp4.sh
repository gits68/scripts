#!/usr/bin/sh

shopt -s extglob

avidemux='/cygdrive/c/Program Files/Avidemux 2.6 - 32 bits/avidemux.exe'
mediainfo='/cygdrive/c/Program Files/MediaInfo/MediaInfoCli.exe'

(( $# )) || set -- *.avi *.mkv

for in; do
	[[ $in = *.mkv ]] || continue
	out=${in%.mkv}.mp4
	[[ -f $out ]] && continue
	tmp="${WTEMP:-D:\\Temp}\\${out##*[\\/]}"
	delay=$("$mediainfo" "$in" |
		awk '/Delay relative to video/{sub(/ms$/,"")
		     print ($NF < 0 ? $NF : "+" $NF);exit}')
	echo "$in (${delay:-0})"
	"$avidemux" --nogui \
		--force-alt-h264 \
		--audio-codec COPY \
		--audio-delay ${delay:-0} \
		--video-codec COPY \
		--output-format MP4 \
		--load "$in" \
		--save "$tmp" \
		--quit &&
	cp --backup=t -- "$tmp" "$out" &&
	rm -- "$tmp"
done
