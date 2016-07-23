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

tomorrow=~/bin/tomorrow.ksh
YYYY=${1:-$(date +%Y)}
N=1

while read DDMM QQQ hash rest; do
	if [[ ${DDMM} = '#' ]]; then
		echo "${DDMM} ${QQQ} ${hash} ${rest}"
		continue
	fi
	if [[ ${rest} = *[*]* ]]; then
		set -- $(${tomorrow} -s ' ' -$N "${YYYY}")
		DD=$1 MM=$2
		(( N += 1 ))
	else
		DD=${DDMM%??} MM=${DDMM#??}
	fi
	QQQ=$(${tomorrow} -Y -d 0 -n "$DD $MM $YYYY")
	echo "${DD}${MM} ${QQQ} ${hash} ${rest}"
done << EOF
# Calendrier des jours feries pour ${YYYY}
# jourmoi quantiemedujour # commentaire
# L'ordre chronologique est indispensable
0101 001 # 1 de l'an
1304 103 # *Lundi de Paques
0105 121 # Fete du Travail
0805 128 # Victoire 1945
2105 141 # *Ascension
0106 152 # *Lundi de Pentecote
1407 195 # Fete Nationale
1508 227 # Assomption
0111 305 # Toussaint
1111 315 # Armistice 1918
2512 358 # Noel
EOF
