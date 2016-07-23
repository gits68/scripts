#!/bin/ksh
#
#ident	@(#) tomorrow.sh 1.8 (Cyrille.Lefevre@laposte.net) Wed Feb  1 14:46:03     2006
#
# Copyright (c) 2002-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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
# 3. The name of the authors and contributors may not be used to
#    endorse or promote products derived from this software without
#    specific prior written permission.
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

# Date calculations using Korn shell (ksh88)
# Gregorian calendar only.
# Tapani Tarvainen July 1998, May 2000
# This code is in the public domain.

# Julian Day Number from calendar date
function date2julian # day month year
{
	integer day=${1#0}
	integer month=${2#0}
	integer year=$3
	integer tmpmonth tmpyear jdate

	(( tmpmonth = 12 * year + month - 3 ))
	(( tmpyear = tmpmonth / 12 ))
	(( jdate = (734 * tmpmonth + 15) / 24 - 2 * tmpyear + \
		tmpyear / 4 - tmpyear / 100 + tmpyear / 400 + \
		day + 1721119 ))

	print -- ${jdate}
}

# Calendar date from Julian Day Number
function julian2date # julianday
{
	integer jdate=$1
	integer day month year tmpday centuries

	(( tmpday = jdate - 1721119 ))
	(( centuries = (4 * tmpday - 1) / 146097 ))
	(( tmpday += centuries - centuries/4 ))
	(( year = (4 * tmpday - 1) / 1461 ))
	(( tmpday -= (1461 * year) / 4 ))
	(( month = (10 * tmpday - 5) / 306 ))
	(( day = tmpday - (306 * month + 5) / 10 ))
	(( month += 2 ))
	(( year += month / 12 ))
	(( month = month % 12 + 1 ))

	print -- ${day} ${month} ${year}
}

function paques { # year
	integer year=$1
	integer n a c day month

	(( n = year - 1900 ))
	(( a = n % 19 ))
	(( c = ( a * 11 - ( ( a * 7 + 1 ) / 19 ) + 4 ) % 29 ))
	(( day = 25 - c - ( n - c + n / 4 + 31 ) % 7 + 31 ))
	(( month = 3 ))

	if (( day > 31 )); then
		(( day -= 31 ))
		(( month += 1 ))
	fi

	print -- ${day} ${month} ${year}
}

function ascension { # year
	integer year=$1
	typeset date

	print -- $(julian2date $(( $(date2julian $(paques ${year}) ) + 39 )) )
}

function pentecote { # year
	integer year=$1
	typeset date

	print -- $(julian2date $(( $(date2julian $(paques ${year}) ) + 49 )) )
}

# Day of week, Monday=1...Sunday=0
function dow   # day month year
{
	print -- $(( (($(date2julian $1 $2 $3) % 7) + 1) % 7 ))
}

function usage
{
	print -u2 "usage: ${basename} [-aAfjlruwWYz] [-s sep] [-dmy delta] [-np \"dd mm yyyy\"] [-123 yyyy]"
	print -u2 "options:"
	print -u2 "    -a       affiche les jours ou les mois symbolique (Mon, Jan, etc.)."
	print -u2 "    -A       affiche les jours ou les mois symbolique (Monday, January, etc.)."
	print -u2 "    -f       idem -a, en francais (Lundi, Janvier, etc.)."
	print -u2 "    -j       affiche la representation Julian de la date de reference."
	print -u2 "    -l       idem -a, en minuscule (mon, jan, etc.)."
	print -u2 "    -N       affiche nombre de jours du mois (28-31)."
	print -u2 "    -r       affiche la date a l'envers (YYYYMMDD)."
	print -u2 "    -u       idem -a, en majuscule (MON, JAN, etc.)."
	print -u2 "    -w|-D    affiche le jour de la semaine (0-6, 0=dimanche)."
	print -u2 "    -W       affiche le numero de la semaine de l'annee (01-54)."
	print -u2 "    -Y       affiche la numero du jour de l'annee (001-366)."
	print -u2 "    -z       affiche l'annee sur 2 chiffres (YY)."
	print -u2 "    -s sep   separateur entre les elements de la date (DDsepMMsepYYYY)."
	print -u2 "    -d delta nombre de jours a ajouter ou a soustraire (-delta, 1 par defaut)."
	print -u2 "    -m delta nombre de mois a ajouter ou a soustraire (-delta)."
	print -u2 "    -y delta nombre d'annees a ajouter ou a soustraire (-delta)."
	print -u2 "    -n date  date de reference (DD MM YYYY)."
	print -u2 "    -p date  affiche le nombre de jours entre -p date (DD MM YYYY) et -n date"
	print -u2 "             (-d 0 par defaut)."
	print -u2 "    -1 YYYY  Paques est la date de reference"
	print -u2 "             (-d 1 pour le lundi de Paques par defaut,"
	print -u2 "              -d -47 pour le mardi Gras, -d -46 pour le mercredi des Cendres,"
	print -u2 "              -d -6 pour le dimanche des Rameaux)."
	print -u2 "    -2 YYYY  l'Ascension est la date de reference (-d 0 par defaut)."
	print -u2 "    -3 YYYY  la Pentecote est la date de reference"
	print -u2 "             (-d 1 pour le lundi de Pentecote par defaut,"
	print -u2 "              -d 14 pour le Saint Sacrement)."
	exit 1
}

function main
{
	integer abbrev=0
	integer deltad=1
	integer deltam=0
	integer deltay=0
	integer dom=0
	integer dow=0
	integer doy=0
	integer julian=0
	typeset lang=en
	typeset format=short
	integer lower=0
	typeset now=$(date "+%d %m %Y")
	typeset past=
	integer reverse=0
	typeset sep=
	integer upper=0
	integer woy=0
	integer ylen=4

	while getopts aADd:fjlm:n:Np:rs:uWwYy:z1:2:3: c; do
	case ${c} in
	a) abbrev=1 ;;
	A) format=long ;;
	d) deltad=${OPTARG} ;;
	f) abbrev=1 lang=fr ;;
	j) julian=1 ;;
	l) abbrev=1 lower=1 ;;
	m) deltam=${OPTARG} ;;
	n) now=${OPTARG} ;;
	N) dom=1 ;;
	p) deltad=0 past=${OPTARG} ;;
	r) reverse=1 ;;
	s) sep=${OPTARG} ;;
	u) abbrev=1 upper=1 ;;
	w|D) dow=1 ;;
	W) woy=1 ;;
	Y) doy=1 ;;
	y) deltay=${OPTARG} ;;
	z) ylen=2 ;;
	1) now=$(paques ${OPTARG}) ;;
	2) deltad=0 now=$(ascension ${OPTARG}) ;;
	3) now=$(pentecote ${OPTARG}) ;;
	*) usage ;;
	esac
	done
	shift OPTIND-1

	if [[ -n ${past} ]]; then
		integer yesterday=$(date2julian ${past})
		integer tomorrow=$(date2julian ${now})
		print -- $(( tomorrow - yesterday + 1 ))
		exit
	fi

	if (( upper )); then
		typeset -u locale=
	elif (( lower )); then
		typeset -l locale=
	else
		typeset locale=
	fi

	set -A days_en_short Sun Mon Tue Wed Thu Fri Sat
	set -A days_fr_short Dim Lun Mar Mer Jeu Ven Sam
	set -A days_en_long Sunday Monday Tuesday Wednesday \
			    Thursday Friday Saturday
	set -A days_fr_long Dimanche Lundi Mardi Mercredi \
			    Jeudi Vendredi Samedi
	eval set -A days "\${days_${lang}_${format}[@]}"
	set -A months_en_short 0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
	set -A months_fr_short 0 Jan Fev Mars Avr Mai Juin Juil Aout Sept Oct Nov Dec
	set -A months_en_long 0 January Febuary March April May June July \
				August September Octorber November December
	set -A months_fr_long 0 Janvier Fevrier Mars Avril Mai Juin Juillet \
				Aout Septembre Octobre Novembre Decembre
	eval set -A months "\${months_${lang}_${format}[@]}"
	set -A _tomorrow $(julian2date $(( $(date2julian ${now}) + ${deltad} )))
	typeset -Z2 day=${_tomorrow[0]} month=${_tomorrow[1]}
	typeset -Z4 year=${_tomorrow[2]}

	if (( dom )); then
		dom=${month}
		day=1
		deltam=1
		deltay=0
	fi

	(( month += deltam ))
	if (( month <= 0 )); then
		(( month += 12 ))
		(( year -= 1 ))
	elif (( month > 12 )); then
		(( year += month / 12 ))
		(( month %= 12 ))
	fi
	(( year += deltay ))

	typeset -Z${ylen} year2=${year}

	if (( julian )); then
		print -- $(date2julian ${day} ${month} ${year})
	elif (( dow )); then
		dow=$(dow ${day} ${month} ${year})

		if (( abbrev )); then
			locale=${days[dow]}

			print -- "${locale}"
		else
			print -- "${dow}"
		fi
	elif (( dom || doy || woy )); then
		integer delta=1
		if (( dom )); then
			integer yesterday=$(date2julian 1 ${dom} ${year})
			delta=0
		else
			integer yesterday=$(date2julian 1 1 ${year})
		fi
		integer tomorrow=$(date2julian ${day} ${month} ${year})
		doy=$(( tomorrow - yesterday + delta ))
		
		if (( woy )); then
			dow=$(dow ${day} ${month} ${year})
			(( woy = doy / 7 + 2 - (dow > 4) ))
			typeset -Z2 woy
			print -- "${woy}"
		else
			typeset -Z3 doy
			print -- "${doy}"
		fi
	elif (( reverse && abbrev )); then
		locale=${months[month]}

		print -- "${year2}${sep}${locale}${sep}${day}"
	elif (( reverse )); then
		print -- "${year2}${sep}${month}${sep}${day}"
	elif (( abbrev )); then
		locale=${months[month]}

		print -- "${day}${sep}${locale}${sep}${year2}"
	else
		print -- "${day}${sep}${month}${sep}${year2}"
	fi
}

dirname=${0%/*}
basename=${0##*/}
basename=${basename%.*sh}

# typeset -ft date2julian
# typeset -ft julian2date
# typeset -ft dow
# typeset -ft main

main ${1+"$@"}

# eof
