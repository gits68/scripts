[[ $# = 0 ]] && set -- *
find "$@" -name _ -prune -o \( -name '*.avi' -exec /programs/MediaInfo/MediaInfoCli.exe {} + \) |
iconv -f latin1 -t utf-8 |
awk -F': ' '/Complete name/{n=$2}/Packed bitstream/{print n}' |
tr '\n' '\0' |
xargs -0 ~/bin/mmcl.sh
