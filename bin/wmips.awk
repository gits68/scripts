#!/usr/bin/awk -f
#! -*- awk -*-
#ident @(#) $Header: /package/cvs/exploitation/sbin/Attic/wmips.awk,v 1.1.2.6 2010/01/26 10:30:41 cle Exp $
# Copyright (c) 2009-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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


# getopt.awk --- do C library getopt(3) function in awk

# External variables:
#    OPTIND -- index in ARGV of first nonoption argument
#    OPTARG -- string value of argument to current option
#    OPTERR -- if nonzero, print our own diagnostic
#    OPTOPT -- current option letter

# Returns:
#    -1     at end of options
#    ?      for unrecognized option
#    <c>    a character representing the current option

# Private Data:
#    _optind  -- index in multi-flag option, e.g., -abc

BEGIN {
	OPTERR = OPTIND = 1

	if (OPTTEST) {
		while ((c = getopt(ARGC, ARGV, "ab:cd")) != -1)
			printf("c = <%c>, optarg = <%s>\n", c, OPTARG)
		printf("non-option arguments:\n")
		for (; OPTIND < ARGC; OPTIND++)
			printf("\tARGV[%d] = <%s>\n", OPTIND, ARGV[OPTIND])
	}
}

function getopt(argc, argv, options,	thisopt, i)
{
	if (length(options) == 0)
		return -1

	if (argv[OPTIND] == "--") {
		OPTIND++
		_optind = 0
		return -1
	} else if (argv[OPTIND] !~ /^-[^: \t\n\f\r\v\b]/) {
		_optind = 0
		return -1
	}

	if (_optind == 0)
		_optind = 2
	thisopt = substr(argv[OPTIND], _optind, 1)
	OPTOPT = thisopt
	i = index(options, thisopt)
	if (i == 0) {
		if (OPTERR)
			printf("%c -- invalid option\n", thisopt) > "/dev/stderr"
		if (_optind >= length(argv[OPTIND])) {
			OPTIND++
			_optind = 0
		} else
			_optind++
		return "?"
	}

	if (substr(options, i + 1, 1) == ":") {
		if (length(substr(argv[OPTIND], _optind + 1)) > 0)
			OPTARG = substr(argv[OPTIND], _optind + 1)
		else
			OPTARG = argv[++OPTIND]
		_optind = 0
	} else
		OPTARG = ""

	if (_optind == 0 || _optind >= length(argv[OPTIND])) {
		OPTIND++
		_optind = 0
	} else
		_optind++
	return thisopt
}

function exitnow(exit_status) {
	__runawk_exit_status = exit_status

	exit exit_status
}

END {
	if (__runawk_exit_status){
		exit __runawk_exit_status
	}
}

function tokenre(s, re) {
        NF = 0
        while (match(s, re)) {
                ++NF
                $NF = substr(s, RSTART, RLENGTH)
                s = substr(s, RSTART + RLENGTH)
        }
}

function tokenre0(re) {
        tokenre($0, re)
}

# eof

function usage(rc, opt, arg) {
	if (opt) {
		print arg ": invalid argument for option", opt > "/dev/stderr"
	}
# m|v == -s m, r|u == -s r, dev, pid
	print "usage: wmips [-AadefFHhLl] [-C unixcmd] [-S svc] [-W wincmd]\n" \
	      "             [-O|-o fmt] [-p pids] [-s sorts] [-u users]\n" \
	      "-ef is the default, -AadHLlOo options are currently ignored.\n" \
	      "-C, -S, -W, -p, -s and -u options may be repeated.\n" \
	      "-s c (cmp), m (vsz), r (cpu), u (user), i (ignorecase)\n" \
	      "pids and users may be a space ou comma separated list." > "/dev/stderr"
	exitnow(rc)
}
function s2an(s, a, n, r,	t, c, i) {
	if (s == "") return n
	if (r == "") r = "[ ,]"
	c = split(s, t, r)
	for (i = 1; i <= c; i++)
		a[++n] = t[i]
	return n
}
BEGIN {
	OPTERR = OPTIND = 1
	npids = nusers = nucmds = nsvcs = nwcmds = ncmps = 0; fmt = "f"
	while ((c = getopt(ARGC, ARGV, "AaC:defFHhLlO:o:p:s:S:u:W:")) != -1)
	if (c == "p")
		npids = s2an(OPTARG, apids, npids)
	else if (c == "u")
		nusers = s2an(OPTARG, ausers, nusers)
	else if (c == "C")
		aucmds[++nucmds] = OPTARG
	else if (c == "S")
		asvcs[++nsvcs] = OPTARG
	else if (c == "W") {
		if (OPTARG != "" && OPTARG ~ /\\/ && OPTARG !~ /\\\\/)
			gsub("\\\\", "\\\\", OPTARG)
		awcmds[++nwcmds] = OPTARG
	} else if (c ~ /[fF]/) {
		fmt = c
		if (c == "F")
			ncmps = s2an("m", acmps, ncmps)
	} else if (c == "s") {
		if (OPTARG !~ /^[cimu ,]+$/) # r
			usage(1, "s", OPTARG)
		ncmps = s2an(OPTARG, acmps, ncmps)
	} else if (c !~ /[AadefHLlOo]/)
		usage(c != "h")
	if (OPTIND != ARGC)
		usage(1)
	for (i = 1; i < OPTIND; i++)
		ARGV[i] = ""
	nano = 10000000
	year = strftime("%Y")
	today = strftime("%Y%m%d")
	ppid = PROCINFO["PPID"]
	smonths = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
	split(smonths, amonths)
	sfmts["f"] = "%-16s %5s %6s %2s %8s %3s %8s %s"
	sfmtf["f"] = "UID PID PPID NI STIME TTY TIME COMMAND"
	#sfmts["l"] = "%-16s %5s %6s %2s %8s %3s %8s %s\n"
	#sfmtf["l"] = "UID PID PPID NI STIME TTY TIME COMMAND"
 	sfmts["F"] = "%-16s %5s %6s %4.4s %6s %6s %8s %3s %8s %s"
	sfmtf["F"] = "UID PID PPID %MEM VSZ RSS STIME TTY TIME COMMAND"
	split(sfmts[fmt], afmts, / +/)
	nfmt = split(sfmtf[fmt], afmtf)
	for (i = 1; i <= nfmt; i++) afmth[afmtf[i]] = afmtf[i]
	ncmps = s2an("p", acmps, ncmps)
	f = 0
}
function pfmt(a,	str, sep, i) {
	str = sep = ""
	for (i = 1; i <= nfmt; i++) {
		str = str sep sprintf(afmts[i], a[afmtf[i]])
		sep = " "
	}
	print str
}
function trim(s) {
	sub("^ +", "", s)
	sub(" +$", "", s)
	return s
}
function unq(s) {
	return substr(s, 2, length(s) - 2)
}
function stime(t) {
	return substr(t, 1, 8) == today ? \
	       substr(t, 9, 2) ":" substr(t, 11, 2) ":" substr(t, 13, 2) : \
	       substr(t, 1, 4) == year ? \
	       amonths[substr(t, 5, 2) + 0] " " substr(t, 7, 2) :
	       substr(t, 1, 4)
	       # substr(t, 3, 2) "/" substr(t, 5, 2) "/" substr(t, 7, 2)
}
function etime(kt, ut,	t, s) {
	t = (kt / nano + ut / nano)
	d = strftime("%d", t, 1) - 1
	s = strftime("%H:%M", t, 1)
	return (d ? d "/" : "") s
}
function cmd(ep, cl, nm,	m, r, s, t) {
	if (ep == "" && cl == "") return nm
	if (ep == "" && cl != "") return cl
	match(cl, "(\"((\\\\|[A-Za-z]:)?[^\"]+)\"|((\\\\|[A-Za-z]:)?[^ ]+))")
	m = substr(cl, RSTART, RLENGTH)
	r = substr(cl, RSTART + RLENGTH + 1)
	t = m !~ /\\/ && m ~ ep ? cl : r
	s = t ? " " : ""
	q = ep ~ / / ? "\"" : ""
	return q ep q s t
}
/^[ \t]*$/ { next }
f == 1 && /^LastBootUpTime/ {
	LastBootUpTime = $NF
	next
}
f == 1 && /^LocalDateTime/ {
	# LocalDateTime = substr($NF, 1, 8)
	next
}
f == 1 && /^TotalVisibleMemorySize/ {
	TotalVisibleMemorySize = $NF
	next
}
f == 0 && /^ *PID.*COMMAND$/ {
	split($0, ufi)
	for (i in ufi) ufn[ufi[i]] = i
	f = 1
	next
}
f == 1 && /ServiceName/ {
	split($0, sfi)
	for (i in sfi) sfn[sfi[i]] = i
	f = 2
	next
}
f == 2 && /ProcessName/ {
	split($0, pfi)
	for (i in pfi) pfn[pfi[i]] = i
	f = 3
	next
}
f == 1 { # ps
	i = $1 !~ /[0-9]/
	ProcessId = $(ufn["PID"] + i)
	WindowsProcessId = $(ufn["WINPID"] + i)
	aProcessId2[WindowsProcessId] = ProcessId
	aParentProcessId2[ProcessId] = $(ufn["PPID"] + i)
	aWindowsProcessId2[ProcessId] = WindowsProcessId
	j = $(ufn["STIME"] + i) !~ /:/
	aStartTime2[ProcessId] = $(ufn["STIME"] + i)
	if (j) aStartTime2[ProcessId] = aStartTime2[ProcessId] " " $(ufn["STIME"] + i + j)
	aCommandName2[ProcessId] = $(ufn["COMMAND"] + i + j)
	next
}
f == 2 { # service
	tokenre0("\"[^\"]*\"|[^\"[:space:]]+")
	ProcessId = $sfn["ProcessId"]
	aDesktopInteract[ProcessId] = $sfn["DesktopInteract"] ~ /Vrai|True/
	if (ProcessId in aServiceName)
		aServiceName[ProcessId] = aServiceName[ProcessId] " " unq($sfn["ServiceName"])
	else
		aServiceName[ProcessId] = unq($sfn["ServiceName"])
	next
}
f == 3 { # process
	#tokenre0("\"([^\"]|\\\")*\"|[[:alnum:]_]+")
	tokenre0("\"[^\"]*\"|[^\"[:space:]]+")
	ProcessId = $pfn["ProcessId"]
	ParentProcessId = $pfn["ParentProcessId"]
	Kernel = $pfn["CreationDate"] == 0
	UserName = ParentProcessId == 0 ? "SYSTEM" : unq($pfn["UserName"])
	if (UserName ~ / /) gsub(" ", "_", UserName)
	Priority = $pfn["Priority"]
	CreationDate = Kernel ? LastBootUpTime : $pfn["CreationDate"]
	SessionId = $(pfn["SessionId"] - Kernel)
	KernelModeTime = $(pfn["KernelModeTime"] - Kernel)
	UserModeTime = $(pfn["UserModeTime"] - Kernel)
	PrivatePageCount = $(pfn["PrivatePageCount"] - Kernel)
	VirtualSize = $(pfn["VirtualSize"] - Kernel)
	WorkingSetSize = $(pfn["WorkingSetSize"] - Kernel)
	ProcessName = unq($(pfn["ProcessName"] - Kernel))
	if (ParentProcessId == 0) {
		CommandName = "[" ProcessName "]"
	} else {
		ExecutablePath = unq($pfn["ExecutablePath"])
		CommandLine = Sep = ""
		for (i = pfn["CommandLine"]; i <= NF; i++) {
			CommandLine = CommandLine Sep $i
			Sep = " "
		}
		CommandName = cmd(ExecutablePath, CommandLine, ProcessName)
	}
	aUserName[ProcessId] = UserName
	aParentProcessId[ProcessId] = ParentProcessId
	aPriority[ProcessId] = Priority
	aStartTime[ProcessId] = stime(CreationDate)
	aSessionId[ProcessId] = SessionId
	aElapsedTime[ProcessId] = etime(KernelModeTime, UserModeTime)
	aPrivatePageCount[ProcessId] = int(PrivatePageCount / 1024)
	aVirtualSize[ProcessId] = int(VirtualSize / 1024)
	aWorkingSetSize[ProcessId] = int(WorkingSetSize / 1024)
	aCommandName[ProcessId] = CommandName
}
function pinan(p, a, n, b,	f, i) {
	if (!n) return 1
	for (i in a) {
		if (p == a[i]) return 1
		if (p in b && b[p] == a[i]) return 1
	}
	return 0
}
function sinan(s, a, n,	f, i) {
	if (!n) return 1
	for (i in a) if (s ~ a[i]) return 1
	return 0
}
function qsort(a, left, right,  i, last) {
	if (left >= right)
		return
	swap(a, left, left + randint(right - left + 1))
	last = left
	for (i = left + 1; i <= right; i++)
		if (comp(a, i, left) < 0)
			swap(a, ++last, i)
	swap(a, left, last)
	qsort(a, left, last - 1)
	qsort(a, last + 1, right)
}
function randint(n) {
	return int(n * rand())
}
function comp(a, i, j,	rc, ic, k, cmp, t1, t2) {
	i = a[i]; j = a[j]
	rc = 0; ic = IGNORECASE
	for (k = 1; k <= ncmps; k++) {
		cmp = acmps[k]
		if (cmp == "m") {
			t2 = aPercentMemory[i]
			t1 = aPercentMemory[j]
		# } else if (cmp == "r") {
			# t2 = aPercentCPU[a[i]]
			# t1 = aPercentCPU[a[j]]
		} else if (cmp == "c") {
			t1 = aCommandName[i] (i in aServiceName ? " [" aServiceName[i] : "")
			t2 = aCommandName[j] (j in aServiceName ? " [" aServiceName[j] : "")
			sub("^\"", "", t1)
			sub("^\"", "", t2)
		} else if (cmp == "u") {
			t1 = aUserName[i]
			t2 = aUserName[j]
		} else if (cmp == "i") {
			IGNORECASE = !IGNORECASE
			continue
		} else { # p
			t1 = i+0
			t2 = j+0
		}
		if (t1 < t2) {
			rc = -1
			break
		}
		if (t1 > t2) {
			rc = 1
			break
		}
	}
	IGNORECASE = ic
	return rc
}
function swap(a, i, j,  t) {
	t = a[i]
	a[i] = a[j]
	a[j] = t
}
END {
	IdelProcessId = 0
	CygwinProcessId = 1
	SystemProcessId = 4
	ExplorerProcessName = "^[^ ]*[Ee]xplorer.[Ee][Xx][Ee]"

	# fake Cygwin Windows Process
	ProcessId = CygwinProcessId
	ParentProcessId = SystemProcessId
	aUserName[ProcessId] = aUserName[ParentProcessId]
	aParentProcessId[ProcessId] = ParentProcessId
	aPriority[ProcessId] = aPriority[ParentProcessId]
	aStartTime[ProcessId] = aStartTime[ParentProcessId]
	aSessionId[ProcessId] = aSessionId[ParentProcessId]
	aElapsedTime[ProcessId] = aElapsedTime[ParentProcessId]
	aPrivatePageCount[ProcessId] = aPrivatePageCount[ParentProcessId]
	aVirtualSize[ProcessId] = aVirtualSize[ParentProcessId]
	aWorkingSetSize[ProcessId] = aWorkingSetSize[ParentProcessId]
	aCommandName[ProcessId] = "[cygwin]"

	# fake Cygwin Cygwin Process
	WindowsProcessId = CygwinProcessId
	aProcessId2[WindowsProcessId] = ProcessId
	aParentProcessId2[ProcessId] = SystemProcessId
	aWindowsProcessId2[ProcessId] = WindowsProcessId
	ProcessId = WindowsProcessId = SystemProcessId

	# fake System Cygwin Process
	WindowsProcessId = SystemProcessId
	aProcessId2[WindowsProcessId] = ProcessId
	aParentProcessId2[ProcessId] = IdelProcessId
	aWindowsProcessId2[ProcessId] = WindowsProcessId

	# fake Idle Cygwin Process
	ProcessId = WindowsProcessId = IdelProcessId
	aProcessId2[WindowsProcessId] = ProcessId
	aParentProcessId2[ProcessId] = IdelProcessId
	aWindowsProcessId2[ProcessId] = WindowsProcessId

	for (ProcessId in aParentProcessId)
		if (ProcessId in aProcessId2)
			if (aParentProcessId2[aProcessId2[ProcessId]] in aWindowsProcessId2 && \
			    !(aParentProcessId[ProcessId] in aParentProcessId))
				aParentProcessId[ProcessId] = aWindowsProcessId2[aParentProcessId2[aProcessId2[ProcessId]]]

	for (ProcessId in aParentProcessId) {
		ParentProcessId = aParentProcessId[ProcessId]
		if (!(ParentProcessId in aParentProcessId)) {
			aUserName[ParentProcessId] = aUserName[ProcessId]
			aParentProcessId[ParentProcessId] = SystemProcessId
			aPriority[ParentProcessId] = aPriority[ProcessId]
			aStartTime[ParentProcessId] = aStartTime[ProcessId]
			aSessionId[ParentProcessId] = aSessionId[ProcessId]
			aElapsedTime[ParentProcessId] = aElapsedTime[ProcessId]
			aPrivatePageCount[ParentProcessId] = aPrivatePageCount[ProcessId]
			aVirtualSize[ParentProcessId] = aVirtualSize[ProcessId]
			aWorkingSetSize[ParentProcessId] = aWorkingSetSize[ProcessId]
			aCommandName[ParentProcessId] = "<defunct>"
		}
	}

	for (ProcessId in aParentProcessId)  {
		if (aCommandName[ProcessId] !~ ExplorerProcessName)
			continue
		ParentProcessId = aParentProcessId[ProcessId]
		while (ParentProcessId != 0 && ParentProcessId != ProcessId)
			ParentProcessId = aParentProcessId[ParentProcessId]
		if (ParentProcessId == ProcessId)
			aParentProcessId[ProcessId] = SystemProcessId
	}

	RC = npids || nusers || nucmds || nsvcs || nwcmds

	if (("%MEM" in afmth) || ("m" in acmps))
		for (ProcessId in aParentProcessId)
			aPercentMemory[ProcessId] = aPrivatePageCount[ProcessId] / TotalVisibleMemorySize * 100

	i = 0
	for (ProcessId in aParentProcessId)
		aIndexes[++i] = ProcessId
	qsort(aIndexes, 1, nprocs = i)

	pfmt(afmth)

	for (i = 1; i < nprocs; i++) {
		ProcessId = aIndexes[i]
		CommandName = aCommandName[ProcessId]

		if (CommandName ~ /\\(sh|cscript|gawk).+wmips/) continue
		if (!pinan(ProcessId, apids, npids, aProcessId2)) continue

		UserName = aUserName[ProcessId]
		if (!sinan(UserName, ausers, nusers)) continue

		if (!sinan(CommandName, awcmds, nwcmds)) continue

		CygwinName = ProcessId in aProcessId2 && aProcessId2[ProcessId] in aCommandName2 ? \
			aCommandName2[aProcessId2[ProcessId]] : ""
		if (!sinan(CygwinName, aucmds, nucmds)) continue

		ServiceName = ProcessId in aServiceName ? aServiceName[ProcessId] : ""
		if (!sinan(ServiceName, asvcs, nsvcs)) continue

		if (CygwinName != "") CygwinName = " (" aProcessId2[ProcessId] " " CygwinName ")"
		if (ServiceName != "") ServiceName = " [" ServiceName "]"

		fields["UID"] = UserName
		fields["PID"] = ProcessId
		fields["PPID"] = aParentProcessId[ProcessId]
		fields["NI"] = aPriority[ProcessId] # PRI
		fields["STIME"] = aStartTime[ProcessId]
		fields["TTY"] = aSessionId[ProcessId] # SID
		fields["TIME"] = aElapsedTime[ProcessId]
		if (("%MEM" in afmth) || ("m" in acmps))
			fields["%MEM"] = aPercentMemory[ProcessId]
		fields["VSZ"] = aPrivatePageCount[ProcessId]
		#fields["VSZ"] = aVirtualSize[ProcessId]
		fields["RSS"] = aWorkingSetSize[ProcessId]
		fields["COMMAND"] = CommandName ServiceName CygwinName

		pfmt(fields)

		RC = 0
	}

	exit RC
}

# eof
