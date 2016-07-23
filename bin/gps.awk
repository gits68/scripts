#!/usr/bin/awk -f
#
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

BEGIN {
	split("N S", nsa); split("E W", eoa)
	CONVFMT = "%04.1f"
	fmt = "%.8f"
	epsilon = .00000001
}
function round(l, n) { return +(+(l "e+" n) "e-" n) }
function l2dms(l, t,	n, d, m, s) {
	n = t[1+(l<0)]
	if (l < 0) l = -l
	d = int(l)
	l -= int(l)
	l *= 60
	m = int(l)
	l -= int(l)
	l *= 60
	s = round(l, 2)
	if (s == 60) { m++; s -= 60 }
	return d "°" m "'" s "''" n
}
function dms2l(n, d, m, s,	l, t) {
	return n * (d + (m / 60) + (s / 3600))
}
function l2l(l, a, m, n,	s, o, x, t) {
	s = o = l2dms(l, a)
	x = o ~ m ? n : -n
	gsub(/[^-.0-9]/, " ", o)
	split(o, t)
	return dms2l(x, t[1], t[2], t[3])
}
/./ {
	ns = /N/ ? 1 : -1
	eo = /[OW]/ ? -1 : 1
	gsub(/[^-.0-9]/, " ")
	if (NF != 6) {
		nss = l2dms($1, nsa)
		eos = l2dms($2, eoa)
		nsn = l2l($1, nsa, "N", 1)
		eon = l2l($2, eoa, "[OW]", -1)
		printf fmt " " fmt "\n", nsn, eon
		print nss, eos
	} else {
		nsn = dms2l(ns, $1, $2, $3)
		eon = dms2l(eo, $4, $5, $6)
		nss = l2dms(nsn, nsa)
		eos = l2dms(eon, eoa)
		printf fmt " " fmt "\n", nsn, eon
		print nss, eos
	}
}

# eof
