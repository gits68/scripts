#!/usr/local/bin/bash
set -- "$@" \
	.BDRip		' Bdrip' \
	.DivX		' Divx' \
	.DVB		' Dvb' \
	.DVDRip		' Dvdrip' \
	.ENG		' Eng' \
	.FASTSUB	' Fastsub' \
	.FiNAL		' Final' \
	.FRENCH		' French' \
	.HDTV		' Hdtv'\
	.LD		' Ld' \
	.PDTV		' Pdtv' \
	.PROPER		' Proper' \
	.REPACK		' Repack' \
	.SUBFRENCH	' Subfrench' \
	.SWE		' Swe' \
	.UNCENSORED	' Uncensored' \
	.VOSTFR		' Vostfr' \
	.WEB-DL		' Web-dl' \
	.WEBRip		' Webrip' \
	.x264		' x264' \
	.XviD		' Xvix' \
	.-.sub		' - Sub' \
	-ADDiCTiON	'[- ]Addiction' \
	-ADVRIP		'[- ]Advrip' \
	-AHDTV		'[- ]Ahdtv' \
	-AK69		'[- ]Ak69' \
	-AMB3R		'[- ]Amb3r' \
	-ARK01		'[- ]Ark01' \
	-ASPHiXiAS	'[- ]Asphixias' \
	-AUTHORiTY	'[- ]Authority' \
	-BaLLanTeAm	'[- ]Ballanteam' \
	-BAWLS		'[- ]Bawls' \
	-BRAD		'[- ]Brad' \
	-clo2		'[- ]Clo2' \
	-DEAL		'[- ]Deal' \
	-ELiTE		'[- ]Elite' \
	-EPZ		'[- ]Epz' \
	-F4ST		'[- ]F4st' \
	-FDS		'[- ]Fds' \
	-FiXi0N		'[- ]Fixion' \
	-FreeTeam	'[- ]Freeteam' \
	-FRiES		'[- ]Fries' \
	-FTX		'[- ]Ftx' \
	-HYBRiS		'[- ]Hybris' \
	-HTO		'[- ]HTO' \
	.iNTERNAL	'[- ]Internal' \
	-iWire		'[- ]Iwire' \
	-JMT		'[- ]Jmt' \
	-LiBERTY	'[- ]Liberty' \
	-LVT		'[- ]Lvt' \
	-MACK4		'[- ]Mack4' \
	-MiND		'[- ]Mind' \
	-Neor24		'[- ]Neor24' \
	-PANZeR		'[- ]PANZeR' \
	-PEPiTO		'[- ]Pepito' \
	-Phoenician14	'[- ]Phoenician14' \
	-PROGRESSiV	'[- ]Progressiv' \
	-PROTEiGON	'[- ]Proteigon' \
	-Rikou		'[- ]Rikou' \
	-RNT		'[- ]Rnt' \
	-Ryotox		'[- ]Ryotox' \
	-SALEM		'[- ]Salem' \
	-SH0W		'[- ]Sh0w' \
	-Snow		'[- ]Snow' \
	-SODAPOP	'[- ]Sodapop' \
	-S0LD13R	'[- ]Sold13r' \
	-SRiZ		'[- ]Sriz' \
	-SSL		'[- ]Ssl' \
	-STG		'[- ]Stg' \
	-TeaM-CPS	'[- ]Team[- ]cps' \
	-TGN		'[- ]Tng' \
	-THR		'[- ]Thr' \
	-toubib12	'[- ]toubib12' \
	-Tras0H		'[- ]Tras0h' \
	-TRISH		'[- ]Trish' \
	-Tritium	'[- ]Tritium' \
	-VENUE		'[- ]VENUE' \
	-windz		'[- ]windz' \
	.FR		' Fr ' \
	'.\[emule-island.ru]' '.\[tvu.org.ru]' '-www.zone-telechargement.com' \
	S01E/1x S02E/2x S03E/3x S04E/4x S05E/5x S06E/6x S07E/7x S08E/8x S09E/9x \
	'/%c3%a0/à' '/%c3%a1/á' '/%c3%a2/â' '/%c3%a3/ã' '/%c3%a4/ä' '/%c3%a5/å' \
	'/%c3%a6/æ' '/%c3%a7/ç' '/%c3%b1/ñ' '/%c3%b8/ø' \
	'/%c3%a8/è' '/%c3%a9/é' '/%c3%aa/ê' '/%c3%ab/ë' \
	'/%c3%ac/ì' '/%c3%ad/í' '/%c3%ae/î' '/%c3%af/ï' \
	'/%c3%b2/ò' '/%c3%b3/ó' '/%c3%b4/ô' '/%c3%b5/õ' '/%c3%b6/ö' \
	'/%c3%b9/ù' '/%c3%ba/ú' '/%c3%bb/û' '/%c3%bc/ü' \
	'/%c3%bd/ý' '/%c3%bf/ÿ' \
	'/%c3%80/À' '/%c3%81/Á' '/%c3%82/Â' '/%c3%83/Ã' '/%c3%84/Ä' '/%c3%85/Å' \
	'/%c3%86/Æ' '/%c3%87/Ç' \
	'/%c3%88/È' '/%c3%89/É' '/%c3%8a/Ê' '/%c3%8b/Ë' \
	'/%c3%8c/Ì' '/%c3%8d/Í' '/%c3%8e/Î' '/%c3%8f/Ï' \
	'/%c3%90/Ð' '/%c3%91/Ñ' \
	'/%c3%92/Ò' '/%c3%93/Ó' '/%c3%94/Ô' '/%c3%95/Õ' '/%c3%96/Ö' \
	'/%c3%97/×' '/%c3%98/Ø' \
	'/%c3%99/Ù' '/%c3%9a/Ú' '/%c3%9b/Û' '/%c3%9c/Ü' \
	'/./ ' '/+( )/ '
shopt -s extglob
for i in *pdf *avi *mp4 *ogm *mkv *mpg *srt *jpg *nfo *txt *rar *zip; do
[[ $i = '*'* ]] && continue
[[ $i = *.* ]] && l=" ${i##*.}/.${i##*.}" || l=" ${i##* }/.${i##* }"
[[ $i = *[0-9]x[0-9]* ]] && m=" /. " || m=
j=$i
for k in "$@" "$l" "$m"; do
	[[ $k = *"'"* ]] && k=${k//"'"/\\"'"}
	[[ $k = "[-.a"]* ]] && continue # k="[-. ]${k#+([-.])}"
	[[ $k = */* ]] || k=$k/
	eval j=\${j/$k}
done
[[ "$i" != "$j" ]] && mv --backup=t -- "$i" "$j"
#[[ "$i" != "$j" ]] && echo "mv -- '$i' '$j'"
done
