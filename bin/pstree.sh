#!/bin/sh
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

ps=ps opts=-ef userz=8 pidsz=5 startsz=8 timesz=6 cw=0 wmi=0 n=
case $(uname) in
AIX) COLUMNS=1024 export COLUMNS; pidsz=7 timesz=7 ;;
*BSD) opts='axwo "user pid ppid cpu start tt time command"' ;;
HP-UX) opts=-efx pidsz=5 ;;
Linux) startsz=5 timesz=8 n=-n ;;
CYGWIN*) [[ $1 != - ]] && type wmips.sh > /dev/null 2>&1 &&
	 ps=wmips.sh userz=16 wmi=1 n=-n || cw=1 n=-n
	[[ $1 = - ]] && shift; [[ $1 = 0 ]] && opts=-Wf ;;
esac
r=$(
# wmips.awk /tmp/ps; exit
$ps $opts
case $cw in (1)
	echo "root 0 0 ? 00:00:00 [kernel]"
	echo "root 1 0 ? 00:00:00 [cygwin]"
esac
)
(
echo "$r" |
head -1
echo "$r" |
tail $n +2 |
sort -k2n
) |
awk -v userz=${userz} -v pidsz=${pidsz} -v startsz=${startsz} -v timesz=${timesz} \
	 -v whichpid=$1 -v cw=${cw} -v wmi=${wmi} '
BEGIN {
	getline
	for (n = 1; n <= NF; n++)
		if ($n ~ /CO?M(MAN)?D/)
			break
	if (cw)
		fmt = "%-"userz"s %"pidsz"s %"pidsz"s %"startsz"s %-3s %s\\_ %s%s\n"
	else
		fmt = "%-"userz"s %"pidsz"s %"pidsz"s %"startsz"s %-7s %"timesz"s %s\\_ %s%s\n"
	head = fmt; sub("\\\\_ ", "", head)
	if (cw)
		printf head, $1, $2, $3, $5, $4, "", $6, ""
	else
		printf head, $1, $2, $3, $5, $6, $7, "", $8, ""
	rootuser = wmi ? "SYSTEM" : "root"
	firstpid = wmi ? 4 : 1
	if (0) { # was cw
		printed[0] = whichpid != 0
		starts[0] = "00:00:00"
		ttys[0] = "?"
		cmds[0] = "[kernel]"
		users[0] = users[1] = rootuser
		printed[1] = fathers[0] = fathers[1] = nchild[0] = 0
		children[0, nchild[0]++] = 1
		starts[1] = "00:00:00"
		ttys[1] = "?"
		cmds[1] = "[cygwin]"
		args[0] = args[1] = ""
	} else
		printed[0] = 1
}

! /^$/ {
	j = 0 # $1 ~ /"/
	pid = $(2+j)
	ppid = $(3+j)
	if (!(ppid in nchild))
		nchild[ppid] = 0
	printed[pid] = pid == 0 && whichpid != 0
	if (j)
		users[pid] = $1 " " $2
	else
		users[pid] = $1
	fathers[pid] = ppid
	children[ppid, nchild[ppid]++] = pid
	i = $(7 - (cw * 2) + j) !~ /:/
	if (i)
		starts[pid] = " " $(5+j) " " $(6+j)
	else
		starts[pid] = $(5+j)
	if (cw) {
		ttys[pid] = $4
		args[pid] = ""
	} else {
		ttys[pid] = $(6 + i + j)
		times[pid] = $(7 + i + j)
	}
	cmds[pid] = $(n + i + j)
	for (i += n + 1 + j; i <= NF; i++)
		if (cw)
			cmds[pid] = cmds[pid] " " $(i+j)
		else
			args[pid] = args[pid] " " $(i+j)
	if (wmi && $NF ~ /)/) {
		sub("[(]", "", $(NF-1))
		wmis[$(NF-1)] = pid
	}
}

function print_line(_pid, _prefix) {
	if (printed[_pid])
		return
	printed[_pid] = 1
	if (cw)
		printf fmt, users[_pid], _pid, fathers[_pid], \
			starts[_pid], ttys[_pid], \
			substr(_prefix, 1, length(_prefix)-2), \
			cmds[_pid], args[_pid]
	else
		printf fmt, users[_pid], _pid, fathers[_pid], \
			starts[_pid], ttys[_pid], times[_pid], \
			substr(_prefix, 1, length(_prefix)-2), \
			cmds[_pid], args[_pid]
}

function print_fathers(_pid, _prefix) {
#print "pf("_pid")"
	if (_pid && _pid in fathers && _pid != fathers[_pid])
		_prefix = "  " print_fathers(fathers[_pid], _prefix)
	else
		_prefix = "" # "  "
	print_line(_pid, _prefix)
	return _prefix # "  " _prefix
}

function print_children(_pid, _prefix,	_child) {
#print "pc("_pid")"
	print_line(_pid, _prefix)
	if (!(_pid in nchild))
		return
	for (_child = 0; _child < nchild[_pid] - 1; _child++)
		if (children[_pid, _child])
			print_children(children[_pid, _child], _prefix "  | ")
	if (children[_pid, _child])
		print_children(children[_pid, _child], _prefix "    ")
}

function print_tree(_pid,	_prefix) {
#print "pt("_pid")"
	if (_pid in fathers)
		_prefix = "  " print_fathers(fathers[_pid], "")
	else
		_prefix = "  "
	print_children(_pid, _prefix)
}

END {
	if (cw) { # was wmi
		for (pid in fathers) {
			ppid = fathers[pid]
			if (ppid in fathers) continue
#print ppid, fathers[ppid]
			fathers[ppid] = firstpid
			children[firstpid, nchild[firstpid]++] = ppid
			printed[ppid] = 0
			users[ppid] = rootuser
			starts[ppid] = "00:00:00"
			ttys[ppid] = "?"
			times[ppid] = "00:00"
			cmds[ppid]=  "<defunct>"
			args[ppid] = ""
		}
	}
	if (whichpid == "" || (whichpid == 0 && !(0 in cmds)))
		whichpid = firstpid
	if (whichpid in cmds)
		print_tree(whichpid)
	else if (wmi && whichpid in wmis)
		print_tree(wmis[whichpid])
	else
		for (pid in cmds)
			if (cmds[pid] ~ whichpid)
				print_tree(pid)
}'

# eof
