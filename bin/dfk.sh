#!/bin/bash
#
# Copyright (c) 1995-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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

typeset re= re2= bs='h' si=1024 px=0 nh=0

if [[ $0 = *[kmgtpezy] ]]; then
	bs=${0#${0%?}}
	[[ ${bs} = 'k' ]] || bs=$(echo "${bs}" | tr a-z A-Z)
fi

while getopts 'd:f:HnphkmgMGTPEZY' c; do
case ${c} in
'd')
	re=${OPTARG}
	;;
'f')
	re2=${OPTARG}
	;;
'H')
	si=1000
	;;
'n')
	nh=1
	;;
'p')
	px=${px}1
	;;
'm')
	bs='M'
	;;
'g')
	bs='G'
	;;
[hkMGTPEZY])
	bs="${c}"
	;;
esac
done
shift $((OPTIND-1))

if [ $# -gt 0 ]; then
	local=0
else
	local=1
fi

typeset awk='awk' df='df' opts='-k' sl=20

case $(uname) in
'OSF1')
	[ -n "$sl" ] && sl=25
	[ ${local} = 1 ] && opts="${opts} -t advfs"
	;;
'SunOS')
	awk='nawk'
	[ ${local} = 1 ] && opts="${opts} -F ufs"
	;;
'HP-UX')
	df='bdf' opts=
	[ ${local} = 1 ] && opts="${opts} -l"
	;;
'IRIX'*|'Linux')
	opts='-kP'
	[ ${local} = 1 ] && opts="${opts} -l"
	;;
'AIX3')
	opts='-I'
	;;
'AIX'*)
	opts='-kP'
	;;
esac

${df} ${opts} ${1+"$@"} 2>&1 |
${awk} -v re="${re}" -v re2="${re2}" -v bs=${bs} \
       -v si=${si} -v sl=${sl} -v px=${px} -v nh=${nh} '
BEGIN {
	fmts = "kMGTPEZY"
	if (bs == "h") {
		ofs = "%6s "
		off = "%%5.1f%c "
		ofd = "%%5d%c "
	} else {
		len = length(fmts)
		for (i = 1; i <= len; i++) {
			fmt = substr(fmts, i, 1)
			szs [fmt] = si ^ (i - 1)
		}
		ofs = "%8s "
		off = "%8.2f "
		ofd = "%8d "
	}
	if (re ~ /^!/) {
		not = 1
		sub("!", "", re)
	}
	if (re2 ~ /^!/) {
		not = 1
		sub("!", "", re2)
	}
	ofr = "%-" sl "s "
	ofp = " %3d%% "
	if (!nh)
		printf (ofr ofs ofs ofs "%%used Mounted on\n", "Filesystem", \
			bs (si == 1000 ? "" : "i") "bytes", "used", "avail")
}

NR == 1 || (/df:/ && /Permission/) { next }

{
	domain = fs = $1
	mp = $NF
}

NF == 1 {
	getline
	$0 = fs $0
	mp = $NF
}

fs ~ /dev\/mapper\// {
	sub("-", "/", fs); sub("/mapper/", "/", fs)
	domain = fs
}

domain ~ /#/ {
	split(fs, a, "#")
	domain = a [1]
}

re && ((not && domain ~ re) || (! not && domain !~ re)) { next }
re2 && ((not && mp ~ re2) || (! not && mp !~ re2)) { next }

function format(sz,	i, fmt) {
	if (si == 1000)
		sz *= 1.024
	if (!sz) {
		fmt = ofs
	} else if (bs == "h") {
		for (i = 1; sz > si; i++)
			sz /= si
		fmt = sprintf(sz < 10 ? off : ofd, substr(fmts, i, 1))
		if (sz > 10)
			sz += 0.5
	} else {
		sz /= szs [bs]
		fmt = bs == "k" ? ofd : off;
	}
	return sprintf(fmt, sz)
}

{
	if (!px && length(fs) > sl) {
		print fs
		fs = ""
	}

	totals [domain] = (total = $2)
	useds [domain] += (used = $3)
	avails [domain] = (avail = $4)
	pct = $5

	oft = format(total)
	ofu = format(used)
	ofa = format(avail)
	if (px < 111)
		printf ofr oft ofu ofa ofp "%s\n", fs, pct, mp
	++rc
}

END {
	if (px == 11) exit !rc

	total = used = avail = 0
	for (domain in totals) {
		total += totals [domain]
		used += useds [domain]
		avail += avails [domain]
	}

	pct = total ? (used / total) * 100 : 0

	oft = format(total)
	ofu = format(used)
	ofa = format(avail)
	printf ofr oft ofu ofa ofp "\n", "", pct

	exit !rc
}
'

# eof
