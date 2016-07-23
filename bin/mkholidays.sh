#!/bin/sh
#
# Copyright (c) 2006-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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

tomorrow=~/bin/tomorrow.sh
YYYY=${1:-$(date +%Y)}
N=1
TAB='	'
OIFS=$IFS
while read -r; do
	set -f
	IFS=$TAB
	set -- $REPLY
	IFS=$OIFS
	QQQ=$1 MMDD=$2 rest=$3
	set +f
	case ${QQQ} in '*'*)
		echo "${REPLY}"
		continue
	esac
	case ${rest} in
	"")
		set -- $REPLY
		echo "  $YYYY $2 $3"
		continue
		;;
	*[*]*)
		set -- $(${tomorrow} -s ' ' -$N "${YYYY}")
		DD=$1 MM=$2
		(( N += 1 ))
		;;
	*)
		set -- ${MMDD}
		MM=$1 DD=$2
		case ${MM} in
		Jan) MM=1 ;;
		Mar) MM=3 ;;
		Apr) MM=4 ;;
		May) MM=5 ;;
		Jun) MM=6 ;;
		Jul) MM=7 ;;
		Aug) MM=8 ;;
		Nov) MM=11 ;;
		Dec) MM=12 ;;
		esac
	esac
	QQQ=$(${tomorrow} -Y -d 0 -n "$DD $MM $YYYY")
	set -- $(${tomorrow} -a -d 0 -s ' ' -n "$DD $MM $YYYY")
	MM=$2
	echo "  ${QQQ}${TAB}${TAB}${MM} ${DD}${TAB}${TAB}${rest}"
done << EOF
* Prime/Nonprime Table for Accounting System
*
* Curr  Prime   Non-Prime
* Year  Start   Start
*
  2013  0800    1700
*
* Day of        Calendar        Company
* Year          Date            Holiday
*
    1		Jan 1		1 de l'an
  100		Apr 9		*Lundi de Paques
  122		May 1		Fete du Travail
  129		May 8		Victoire 1945
  138		May 17		*Ascension
  149		May 28		*Lundi de Pentecote
  196		Jul 14		Fete Nationale
  228		Aug 15		Assomption
  306		Nov 1		Toussaint
  316		Nov 11		Armistice 1918
  360		Dec 25		Noel
EOF
