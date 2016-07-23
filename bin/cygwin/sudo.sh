#!/usr/bin/sh
#! -*- ksh -*-
#
# Simulate SUDO command via SU (well, via SSH)
#
#ident @(#) $Header: /package/cvs/exploitation/sbin/Attic/sudo.sh,v 1.1.2.3 2010/04/26 17:15:20 cle Exp $
# Copyright (c) 2010-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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

if [ -n "${BASH_VERSION}${KSH_VERSION}" ]; then
	set -o posix
fi

usage() {
	cat << EOF >&2
usage: sudo [-b] [-u user] [-I ssh_key] [-ins] [command]
option -i is implied if a command is given.
option -b may be given only if a command is given.
options -i, -n and -s are mutually exclusive and one
of them should be given if no command is given.
in short, sudo -i, -n and -s options are respectively
-l, <none> and -m or -p su options.
options -K, -L, -V, -k, -l, -v, -H, -P, -S, -p and -e
aren't supported in this minimal version of 'sudo'.
default user is '${CYGWIN_SUDO_ROOT_USER}' (\$CYGWIN_ROOT_USER).
default ssh_key is '${CYGWIN_SUDO_SSH_KEY}' (\$CYGWIN_SSH_KEY).
EOF
	exit $1
}
unsupp () {
	echo "option '$1' isn't supported in this minimal version of 'sudo'" >&2
	usage 1
}
unimpl () {
	echo "option '$1' isn't implemented yet in this minimal version of 'sudo'" >&2
	usage 1
}

CYGWIN_SUDO_SCRIPT=$0
case ${CYGWIN_SUDO_SCRIPT} in
*/*)	;;
*)	CYGWIN_SUDO_SCRIPT=$(type $0) # f*ing bash
	CYGWIN_SUDO_SCRIPT=${CYGWIN_SUDO_SCRIPT##* is } ;;
esac
CYGWIN_SUDO_PATH=${CYGWIN_SUDO_SCRIPT%/*}
case ${CYGWIN_SUDO_PATH} in
/*)	;;
*)	CYGWIN_SUDO_PWD=${PWD:-$(pwd)}
	CYGWIN_SUDO_PATH=${CYGWIN_SUDO_PWD%/}/${CYGWIN_SUDO_PATH} ;;
esac

CYGWIN_SUDO_SSH_KEY=${CYGWIN_SSH_KEY:-${HOME}/.ssh/id_sudo}
CYGWIN_SUDO_ROOT_USER=${CYGWIN_ROOT_USER:-root} # was Administrator

CYGWIN_SUDO_BACKGROUND=NO
CYGWIN_SUDO_NOLOGIN=NO
CYGWIN_SUDO_LOGIN=NO
CYGWIN_SUDO_PRESERVE=NO
CYGWIN_SUDO_USER=${CYGWIN_SUDO_ROOT_USER}

while getopts 'bhI:insu:KLVklvHPSp:e:' c; do
	case ${c} in
	[KLVklvHPSpe])
		unsupp "${c}"
		;;
	'b')
		# unimpl "${c}"
		CYGWIN_SUDO_BACKGROUND=YES
		;;
	'h')
		usage 0
		;;
	'I')
		CYGWIN_SUDO_SSH_KEY=${OPTARG}
		;;
	'i')
		CYGWIN_SUDO_NOLOGIN=NO
		CYGWIN_SUDO_LOGIN=YES
		CYGWIN_SUDO_PRESERVE=NO
		;;
	'n')
		CYGWIN_SUDO_NOLOGIN=YES
		CYGWIN_SUDO_LOGIN=NO
		CYGWIN_SUDO_PRESERVE=NO
		;;
	's')
		CYGWIN_SUDO_NOLOGIN=NO
		CYGWIN_SUDO_LOGIN=NO
		CYGWIN_SUDO_PRESERVE=YES
		;;
	'u')
		CYGWIN_SUDO_USER=${OPTARG}
		;;
	*)
		usage 1
		;;
	esac
done
shift $(( ${OPTIND} - 1 ))

CYGWIN_SUDO_SH_OPTS= CYGWIN_SUDO_SU_OPTS=

CYGWIN_SUDO_OPTS=${CYGWIN_SUDO_NOLOGIN}${CYGWIN_SUDO_LOGIN}${CYGWIN_SUDO_PRESERVE}

if [ ${CYGWIN_SUDO_LOGIN} = YES ]; then
	CYGWIN_SUDO_SU_OPTS=-l
elif [ ${CYGWIN_SUDO_PRESERVE} = YES ]; then
	CYGWIN_SUDO_SU_OPTS=-m
fi

if [ $# != 0 ]; then
	if [ ${CYGWIN_SUDO_OPTS} = NONONO ]; then
		CYGWIN_SUDO_SU_OPTS=-l
	fi
	if [ ${CYGWIN_SUDO_BACKGROUND} = YES ]; then
		CYGWIN_SUDO_SU_OPTS="${CYGWIN_SUDO_SU_OPTS} -b"
	fi
	CYGWIN_SUDO_SH_OPTS=-c
	qargs= sep=
	for arg; do
		qarg=$(printf "%s\n" "${arg}" | sed -e 's|"|\\"|g')
		qargs="${qargs}${sep}\"${qarg}\""
		sep=' '
	done
	set -- "${qargs}"
elif [ ${CYGWIN_SUDO_BACKGROUND} = YES ] || \
     [ ${CYGWIN_SUDO_OPTS} = NONONO ]; then
	usage 1
fi

if [ -n "${CYGWIN_SUDO_SSH_KEY}" ]; then
	CYGWIN_SUDO_SU_OPTS="${CYGWIN_SUDO_SU_OPTS} -i ${CYGWIN_SUDO_SSH_KEY}"
fi

exec ${CYGWIN_SUDO_PATH%/}/su.sh ${CYGWIN_SUDO_SU_OPTS} ${CYGWIN_SUDO_USER} \
		   ${CYGWIN_SUDO_SH_OPTS} ${1+"$@"}
