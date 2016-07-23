#!/bin/sh
#
# Copyright (c) 2000-2016 Cyrille Lefevre. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

debug=1
trace=1

if [ "$trace" -eq 1 ]; then
	DIRNAME=`dirname $0`
	BASENAME=`basename $0 .sh`
	NOW=`date +%Y%m%d_%H%M%S`

	LOG_DIR=${TMPDIR:-/var/tmp}
	LOG_FILE=${BASENAME}_${NOW}.log
	LOG_PATH=${LOG_DIR}/${LOG_FILE}

	trap 'cat -s $LOG_PATH >&4' 0
	exec 3>&1 4>&2 > $LOG_PATH 2>&1
fi

# do i have to use awk, nawk or gawk
if [ -x $TO_INSTALL_DIR/bin/gawk ]
then
    awk=$TO_INSTALL_DIR/bin/gawk
elif type nawk > /dev/null 2>&1; then
    awk=nawk
else
    awk=awk
fi

whom=$1
signals="15 1 9"
sleeptime=5

# protect myself from death
trap '' 1 15

# processes status
ps -ef |

# find children
$awk '
# useless header
BEGIN { getline }

# the 2nd parameter is a local variable
function children(pid,	p) {
	if (cmds [pid])
		print ppids [pid], pid

	for (p in ppids)
		# find children but don t recurse on same pid
		if (ppids [p] == pid && p != pid)
			children(p)
}

# record processes
{
	ppids [$2] = $3
	cmds [$2] = $0
}

# find children
END {
	# don t kill whom s father (tsort hack)
	ppids [whom] = whom

	children(whom)
}' whom=$whom |

# topologically sort pids
tsort |

# kill'em all
while read pid; do
	# don't kill myself :-)
	[ $pid -eq $$ ] && continue

	# be verbose
	if [ "$debug" -eq 1 ]; then
		ps -fp $pid
	fi

	# don't be sick :P
	for sig in $signals; do
		# is there anybody?
		if kill -0 $pid 2> /dev/null; then
			# yes, kill it!
			kill -$sig $pid

			# still here?
			if kill -0 $pid 2> /dev/null; then
				# let it die smoothly...
				sleep $sleeptime
			fi
		fi
	done
done

# eof
