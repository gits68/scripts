#!/usr/bin/sh
#! -*- ksh -*-
#
# Simulate SU command via SSH
#
#ident @(#) $Header: /package/cvs/exploitation/sbin/Attic/su.sh,v 1.1.2.7 2010/04/26 17:17:46 cle Exp $
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

#set -x

if [ -n "${BASH_VERSION}${KSH_VERSION}" ]; then
	set -o posix
fi

#windows_env='ALLUSERSPROFILE COMMONPROGRAMFILES COMPUTERNAME
#COMSPEC HOMEDRIVE HOMEPATH LOGONSERVER NUMBER_OF_PROCESSORS OS
#PATHEXT PROCESSOR_ARCHITECTURE PROCESSOR_IDENTIFIER PROCESSOR_LEVEL
#PROCESSOR_REVISION PROGRAMFILES SYSTEMDRIVE SYSTEMROOT USERDOMAIN
#USERNAME WINDIR'
#unix_env='CYGWIN HOME LOGNAME MAIL OLDPWD PATH PWD SHELL SHLVL TEMP TMP USER'
#ssh_env='SSH_CLIENT SSH_CONNECTION SSH_AUTH_SOCK SSH_TTY'

CYGWIN_SU_PATH=${PATH}
PATH=/bin:/usr/bin:${PATH}
for CYGWIN_SU_CMD in egrep grep id printf sed ssh; do
	CYGWIN_SU_CMD=$(type ${CYGWIN_SU_CMD} 2>&1)
	case ${CYGWIN_SU_CMD} in
	*' is '*/*)
		CYGWIN_SU_CMD=${CYGWIN_SU_CMD##* }
		;;
	*hashed*)
		CYGWIN_SU_CMD=${CYGWIN_SU_CMD##* }
		CYGWIN_SU_CMD=${CYGWIN_SU_CMD#(}
		CYGWIN_SU_CMD=${CYGWIN_SU_CMD%)}
		;;
	*)
		CYGWIN_SU_CMD=${CYGWIN_SU_CMD%% *}
		;;
	esac
	eval CYGWIN_SU_${CYGWIN_SU_CMD##*/}=${CYGWIN_SU_CMD}
done
PATH=${CYGWIN_SU_PATH}
unset CYGWIN_SU_PATH CYGWIN_SU_CMD

if [ -z "${CYGWIN_SU_SCRIPT}" ]; then

export CYGWIN_SU_PWD=${PWD:-$(pwd)}
export CYGWIN_SU_SCRIPT=$0
case ${CYGWIN_SU_SCRIPT} in
*/*)	;;
*)	CYGWIN_SU_SCRIPT=$(type $0) # f*ing bash
	CYGWIN_SU_SCRIPT=${CYGWIN_SU_SCRIPT##* is } ;;
esac
CYGWIN_SU_PATH=${CYGWIN_SU_SCRIPT%/*}
case ${CYGWIN_SU_PATH} in
/*)	;;
*)	CYGWIN_SU_PATH=${CYGWIN_SU_PWD%/}/${CYGWIN_SU_PATH} ;;
esac
CYGWIN_SU_SCRIPT=${CYGWIN_SU_PATH%/}/${CYGWIN_SU_SCRIPT##*/}

usage() {
	cat << EOF >&2
usage: su [-bf] [-i ssh_key] [-s shell] [-d|-m|-l|-p|-] [user] [shell args]
options:
    -b          go to background just before command execution (ssh)
    -f          fast login (csh, tcsh or zsh, else unset ENV)
    -i ssh_key  ssh key to use if any
    -s shell    shell to use instead of the one in /etc/passwd
    -d          same as -l, but does not change the current directory
    -m | -p     preserve the environment
    -l | -      simulate a full login
options -d, -m, -l, -p or - are mutually exclusive.
default user is '${CYGWIN_SU_ROOT_USER}' (\$CYGWIN_ROOT_USER).
EOF
	exit $1
}

# noexport
CYGWIN_SU_SSH_KEY=${CYGWIN_SSH_KEY:-${HOME}/.ssh/id_sudo}
CYGWIN_SU_ROOT_USER=${CYGWIN_ROOT_USER:-root} # was Administrator

export CYGWIN_SU_CWD=NO CYGWIN_SU_FAST=NO
export CYGWIN_SU_LOGIN=NO CYGWIN_SU_PRESERVE=NO
export CYGWIN_SU_SHELL= CYGWIN_SU_USER=
# noexport
CYGWIN_SU_BACKGROUND=NO

while getopts ':bdfhi:lmps:' c; do
	case ${c} in
	'b')
		CYGWIN_SU_BACKGROUND=YES
		;;
	'd')
		CYGWIN_SU_LOGIN=YES
		CYGWIN_SU_CWD=YES
		CYGWIN_SU_PRESERVE=NO
		;;
	'f')
		# csh -f -- ignored
		;;
	'h')
		usage 0
		;;
	'i')
		CYGWIN_SU_SSH_KEY=${OPTARG}
		;;
	'l')
		CYGWIN_SU_LOGIN=YES
		CYGWIN_SU_CWD=NO
		CYGWIN_SU_PRESERVE=NO
		;;
	[mp])
		CYGWIN_SU_LOGIN=NO
		CYGWIN_SU_CWD=NO
		CYGWIN_SU_PRESERVE=YES
		;;
	's')
		CYGWIN_SU_SHELL=${OPTARG}
		;;
	*)
		(( OPTIND -= 1 ))
		break
		#echo "$0: Unknown option ${c}" 2>&1
		#exit 1
		;;
	esac
done

shift $((${OPTIND} - 1))

if [ "_${1}_" = _-_ ]; then
	CYGWIN_SU_LOGIN=YES
	shift
fi

case $#$1 in
0|*-*)
	CYGWIN_SU_USER=${CYGWIN_SU_ROOT_USER}
	;;
*)
	CYGWIN_SU_USER=$1
	shift
	;;
esac

export CYGWIN_SU_FROM=$($CYGWIN_SU_id -un)
export CYGWIN_SU_HOME=${HOME}
#export CYGWIN_SU_MAIL=${MAIL}
export CYGWIN_SU_COLORTERM=${COLORTERM}
export CYGWIN_SU_TERM=${TERM}
export CYGWIN_SU_UMASK=$(umask)

if [ ${CYGWIN_SU_LOGIN} = NO ]; then
	eval "$(export -p |
		$CYGWIN_SU_egrep -e '^export [_[:alpha:]][_[:alnum:]]+' |
		$CYGWIN_SU_sed -e '/export CYGWIN_SU/d' \
			       -e 's|export |&CYGWIN_ENV_|')"
fi

CYGWIN_SU_SSH_OPTS='-akx'
if [ $# = 0 ]; then
	CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -t"
fi
if [ ${CYGWIN_SU_BACKGROUND} = YES ]; then
	CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -f"
fi
if [ -n "${CYGWIN_SU_SSH_KEY}" -a -f "${CYGWIN_SU_SSH_KEY}" ]; then
	CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -i ${CYGWIN_SU_SSH_KEY}"
fi
CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o Protocol=2"
CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o LogLevel=ERROR"
CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o NoHostAuthenticationForLocalhost=yes"
#CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o ConnectTimeout=10"
#CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o ServerAliveInterval=300"
CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o SendEnv=LANG -o SendEnv=LC_*"
CYGWIN_SU_SSH_OPTS="${CYGWIN_SU_SSH_OPTS} -o SendEnv=CYGWIN_*"

if [ $# != 0 ]; then
	qargs= sep=
	for arg; do
		qarg=$($CYGWIN_SU_printf "%s\n" "${arg}" |
		       $CYGWIN_SU_sed -e 's|"|\\"|g')
		qargs="${qargs}${sep}\"${qarg}\""
		sep=' '
	done
	set -- "${qargs}"
fi

exec $CYGWIN_SU_ssh ${CYGWIN_SU_SSH_OPTS} ${CYGWIN_SU_USER}@localhost \
     "${CYGWIN_SU_SCRIPT}" ${1+"$@"}

else

unset SSH_CLIENT SSH_CONNECTION SSH_AUTH_SOCK SSH_TTY

[ -n "${SHLVL}" ] && SHLVL=0

if [ ${CYGWIN_SU_LOGIN:-NO} = YES ]; then
	CYGWIN_SU_SHELL_OPTS='-l'
	if [ -n "${CYGWIN_SU_COLORTERM}" ]; then
		export COLORTERM=${CYGWIN_SU_COLORTERM}
	fi
	if [ -n "${CYGWIN_SU_TERM}" ]; then
		export TERM=${CYGWIN_SU_TERM}
	fi
	if [ ${CYGWIN_SU_CWD:-NO} = YES ]; then
		cd "${CYGWIN_SU_PWD}"
	fi
else
	CYGWIN_SU_SHELL_OPTS=
	if [ -f /proc/$$/winpid ]; then
		$CYGWIN_SU_id -Gn |
		$CYGWIN_SU_egrep -qv "${CYGWIN_WHEEL_GROUP:-Administrat(or|eur)}"
		CYGWIN_SU_ROOT=$?
	else
		$CYGWIN_SU_id -un |
		$CYGWIN_SU_grep -qv "root"
		CYGWIN_SU_ROOT=$?
	fi
	if [ ${CYGWIN_SU_PRESERVE:-NO} = NO ]; then
#		#if [ ${CYGWIN_SU_ROOT} = 1 ]; then
#			CYGWIN_SU_FROM=${CYGWIN_SU_USER}
#		#fi
		CYGWIN_SU_HOME=${HOME}
		CYGWIN_SU_MAIL=${MAIL}
		CYGWIN_SU_SH=${SHELL}
	fi
	# SHLIB_PATH (hp-ux) LIBPATH (aix) DYLD_ (darwin)
	eval "$(export -p |
		$CYGWIN_SU_sed -n -e '/export CYGWIN_ENV_LD_/d' \
				   -e 's|^export CYGWIN_ENV_|export |p')"
	if [ ${CYGWIN_SU_PRESERVE:-NO} = NO ]; then
		if [ ${CYGWIN_SU_ROOT} = 1 ]; then
			USER=${CYGWIN_SU_FROM}
			LOGNAME=${CYGWIN_SU_FROM}
		else
			USER=${CYGWIN_SU_USER}
			LOGNAME=${CYGWIN_SU_USER}
		fi
		HOME=${CYGWIN_SU_HOME}
		if [ -n "${CYGWIN_SU_MAIL}" ]; then
			MAIL=${CYGWIN_SU_MAIL}
		fi
		SHELL=${CYGWIN_SU_SH}
	fi
	umask ${CYGWIN_SU_UMASK}
	cd "${CYGWIN_SU_PWD}"
fi

#export SU_FROM=${CYGWIN_SU_FROM}

SHELL=${CYGWIN_SU_SHELL:-${SHELL:-/bin/sh}}

if [ ${CYGWIN_SU_FAST:-NO} = YES ]; then
	case ${SHELL##*/} in
	csh|csh.exe|tcsh|tcsh.exe|zsh|zsh.exe)
		CYGWIN_SU_SHELL_OPTS="${CYGWIN_SU_SHELL_OPTS} -f" ;;
	sh|sh.exe|\
	ash|ash.exe|bash|bash.exe|dash|dash.exe|\
	ksh|ksh.exe|pdksh|pdksh.exe|ksh93|ksh93.exe)
		unset ENV ;;
	esac
fi

eval "$(export -p |
	$CYGWIN_SU_sed -e '/^export CYGWIN_ENV_/!d' \
		       -e 's|^export |unset |;s|=.*||')"
unset CYGWIN_SU_PWD CYGWIN_SU_SCRIPT CYGWIN_SU_CWD
unset CYGWIN_SU_FAST CYGWIN_SU_LOGIN CYGWIN_SU_PRESERVE
unset CYGWIN_SU_COLORTERM CYGWIN_SU_FROM CYGWIN_SU_HOME
unset CYGWIN_SU_MAIL CYGWIN_SU_SH CYGWIN_SU_SHELL
unset CYGWIN_SU_TERM CYGWIN_SU_UMASK CYGWIN_SU_USER

if [ $# = 0 ]; then
	set -- -i
fi

exec ${SHELL} ${CYGWIN_SU_SHELL_OPTS} ${1+"$@"}

fi

# eof
