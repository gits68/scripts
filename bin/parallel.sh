#!/usr/bin/sh
#
#!ident @(#) parallel.sh 1.4 (Cyrille.Lefevre-lists%nospam@laposte.net.invalid) Tue, Dec 31, 2013  1:01:11 AM
# supprimer "%nospam" et ".invalid" pour me repondre.
# remove "%nospam" and ".invalid" to answer me.
#
# Copyright (c) 2010-2013 Cyrille Lefevre. All rights reserved.
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

# works fine under bash & ksh93
# not ksh88 compatible becoz of ${!tab[@]} syntax, will be fixed later

[[ -n ${BASH_VERSION} ]] && shopt -s extglob

function usage {
	typeset rc=0

	if (( $# )); then
		typeset c=$1

		case ${c} in

		''|'?')
			;;

		*)
			echo "${0##*/}: illegal option -- ${c}" >&2
			rc=1
			;;

		esac
	fi

	cat << EOF
usage: ${0##*/} [-hqv] [-c #cpu] [-g #tmout] [-m #coef] [-n #nice] [-o opt ...]
		[[-s "host ..."] | -s [host | file] ...] [-t #tmout]
		[cmd [arg ...]]
options:
    -c #cpu	number of processors (${_ncpu} found)
    -g #tmout	global timeout
    -m #coef	coefficient to apply to #cpu (none by default)
    -n #nice	alter priority of processes (none by default)
    -o opt ...	ssh options
    -s host ...	uses hosts instead of localhost, may be repeated, may be a file,
		#cpu is overriden by the number of hosts, #coef still apply
    -t tmout	per process timeout
    -q		be quiet
    -v		be verbose (default)
arguments:
    arg may contain {} which will be replaced by the current input line
protocol:
    input is taken from stdin, either from a file, a pipe or a here document
    each line is a command to execute or arguments to pass to the global
    command if any
    empty lines and lines beginning with an hash (#) are ignored
    lines beginning with an exclamation mark (!) are keywords
    the following keywords are understood :
    add host ...	same as -s host ...
    del host ...	the opposite of -s host ...
    ncpu #cpu		same as -c #cpu, 0 reset #cpu
    coef #coef		same as -m #coef, 0 reset #coef
    nice #nice		same as -n #nice
    tmout #tmout	same as -t #tmout
    gtmout #tmout	same as -g #tmout, the previous timer is killed if any
    wait		wait for existing processes
    quiet		same as -q
    verb		same as -v
    quit		eof
examples:
    # using a cpu coeficient
    $ for i in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do echo $(($RANDOM%10)); done |
      ${0##*/} -m 2 sleep
    # per process timeout and global timeout
    $ for i in 1 2 3 4 5; do echo $(( $RANDOM % 10 )); done |
      ${0##*/} -t 3 -g 5 sleep {}
    # using remote hosts
    $ for i in 1 2 3 4 5; do echo $(( $RANDOM % 10 )); done |
      ${0##*/} -s host1 -s 'host2 host3' -s hostfile sleep
    # protocol sample
    $ ${0##*/} -o -ax sleep << EoF
1
! add localhost pcvista
1
2
3
! del pcvista
1
3
4
! wait
! del localhost
! ncpu 1
! tmout 1
! gtmout 3
1
2
3
! quit
EoF
EOF
	exit ${rc}
}

function onexit {
	typeset -i rc=$?

	kill_timer

	(( _time0 -= -${SECONDS} ))
	$_quiet echo elapsed: ${_time0}

	exit ${rc}
}

function onsig {
	typeset -i rc=$?
	typeset -i pid=

	exec 6>&2 2> /dev/null
	kill "${!tmouts[@]}"

	for pid in "${!pids[@]}"; do
		kill "${pid}"
		$_quiet echo "${pid}: killed"
	done

	wait "${!tmouts[@]}" "${!pids[@]}"
	exec 2>&6 6>&-

	exit ${rc}
}

function kill_timer {
	if (( gtmoutpid )); then
		exec 6>&2 2> /dev/null
		kill "${gtmoutpid}"
		wait "${gtmoutpid}"
		exec 2>&6 6>&-

		gtmoutpid=
	fi
}

function seta {
	typeset var=$1
	shift

	if [[ -n ${BASH_VERSION} ]]; then
		eval ${var}=\( \${1+\"\$@\"} \)
	else
		nameref ptr=${var}
		ptr=( ${1+"$@"} )
		# set -A ptr -- ${1+"$@"}
	fi
}

function shquot {
	if [[ -n ${BASH_VERSION} ]] ||
	   [[ -n ${KSH_VERSION} && ${SECONDS} = *[,.]* ]]; then
		echo "'${@//\'/\'}'"
	else
		printf "%s " "$@" | sed -e "s|'|\\\'|g;s|^|'|;s| $|'|"
	fi
}

function set_host {
	for host in "${_hosts[@]}"; do
		case " ${hosts[*]} " in

		*" ${host} "*)
			;;

		*)
			last=${host}
			return
			;;

		esac
	done

	# round robin if #coef
	typeset i=0
	while (( i <= ${#_hosts[@]} )); do
		if [[ ${_hosts[i]} = ${last} ]]; then
			(( i += 1 ))
			break
		fi
		(( i += 1 ))
	done
	(( i >= ${#_hosts[@]} )) && i=0

	host=${_hosts[i]}
	last=${host}
}

function set_ncpu {
	case $(uname) in

	'AIX')
		_ncpu=$(LC_ALL=C lsdev -c processor | grep -c Avail)
		;;

	'Darwin')
		#noht#_ncpu=$(sysctl -n hw.physicalcpu)
		_ncpu=$(sysctl -n hw.availcpu) # was logicalcpu
		;;

	'FreeBSD')
		_ncpu=$(sysctl -n hw.ncpu)
		;;

	'HP-UX')
		_ncpu=$(ioscan -fkC processor | grep -c processor)
		;;


	'CYGWIN'*)
		# _ncpu=${NUMBER_OF_PROCESSORS}
		_ncpu=$(grep -c processor /proc/cpuinfo)
		;;

	'Linux')
		#noht#_ncpu=$(grep 'physical id' /proc/cpuinfo | sort -u | wc -l)
		_ncpu=$(grep -c processor /proc/cpuinfo)
		;;

	'SunOS')
		_ncpu=$(LC_ALL=C psrinfo -v | grep -c on-line)
		;;

	esac
}

function dequeue {
	typeset -i maxpid=$1
	typeset -i pid=0 sleep=0

	while (( ${#pids[*]} >= maxpid )); do
		sleep=1

		for pid in "${!tmouts[@]}"; do
			if kill -0 "${pid}" 2> /dev/null; then
				: # ! cmd is buggy under ksh's hp-ux
			elif kill -0 "${tmouts[pid]}" 2> /dev/null; then
				sleep=0

				exec 6>&2 2> /dev/null
				wait "${pid}"
				kill "${tmouts[pid]}"
				wait "${tmouts[pid]}"
				exec 2>&6 6>&-

				unset pids[tmouts[pid]] hosts[tmouts[pid]]
				unset tmouts[pid]

				$_quiet echo "${pid}: tmout"
			fi
		done

		for pid in "${!pids[@]}"; do
			if kill -0 "${pid}" 2> /dev/null; then
				: # ! cmd is buggy under ksh's hp-ux
			else
				sleep=0

				exec 6>&2 2> /dev/null
				wait "${pid}"
				if [[ -n ${pids[pid]} ]]; then
					kill "${pids[pid]}"
					wait "${pids[pid]}"

					unset tmouts[pids[pid]]
				fi
				exec 2>&6 6>&-

				unset pids[pid] hosts[pid]

				$_quiet echo "${pid}: done"
			fi
		done

		(( sleep )) && sleep 1
	done
}

function enqueue {
	typeset -i nice=$1 tmout=$2
	shift 2

	if (( ${#_hosts[*]} )); then
		set_host

		ssh -n -o BatchMode=yes ${_opts} "${host}" "$@" &
		#eval ssh -n -o BatchMode=yes ${_opts} "${host}" $(shquot "$@") &

		hosts[$!]=${host}
	else
		"$@" &
		(( ${nice} )) && sleep 1 && renice "${nice}" -g $!
	fi
	if (( tmout )); then
		typeset pid=$!

		sleep "${tmout}" &

		tmouts[$!]=${pid}
		pids[pid]=$!
	else
		pids[$!]=
	fi

	$_quiet echo "$!:${host:+${host}:} $REPLY"
}

function parallel {
	typeset -i ncpu=0 coef=0 nice=0 tmout=0 gtmout=0 i=0
	typeset cmd= arg= args=

	while read -r; do
		case ${REPLY} in

		''|'#'*)
			continue
			;;

		'!'*)
			$_quiet echo ${REPLY}

			REPLY=${REPLY#!}
			REPLY=${REPLY# }

			case ${REPLY} in

			*=*)
				cmd=${REPLY%%=*}
				args=${REPLY#*=}
				;;

			*)
				cmd=${REPLY%% *}
				args=${REPLY#* }
				;;

			esac

			case ${cmd} in

			'add')
				set -f
				#seta _hosts ${_hosts[@]} ${args}
				_hosts=( ${_hosts[@]} ${args} )
				set +f

				_ncpu=${#_hosts[@]}
				ncpu=${_ncpu}

				(( coef > 1 )) && (( ncpu *= coef ))
				;;

			'del')
				set -f
				for arg in ${args}; do
					#seta _hosts ${_hosts[@]#${arg}}
					_hosts=( ${_hosts[@]#${arg}} )
				done
				set +f

				i=${#_hosts[@]} host=
				while (( (i-=1) >= 0 )); do
					[[ -z ${#_hosts[i]} ]] &&
					eval unset _hosts[i]
				done

				_ncpu=${#_hosts[@]}
				(( _ncpu == 0 )) && _ncpu=1
				ncpu=${_ncpu}

				(( coef > 1 )) && (( ncpu *= coef ))
				;;

			'ncpu')
				eval "${cmd}='${args}'"

				(( ncpu == 0 )) && ncpu=${_ncpu}
				;;

			'coef')
				eval "${cmd}='${args}'"

				(( coef == 0 )) && coef=${_coef}
				(( coef > 1 )) && (( ncpu *= coef ))
				;;

			'nice')
				eval "${cmd}='${args}'"

				[[ -z ${nice} ]] && nice=0
				;;

			'tmout')
				eval "${cmd}='${args}'"

				[[ -z ${tmout} ]] && tmout=0
				;;

			'gtmout')
				kill_timer

				eval "${cmd}='${args}'"

				[[ -z ${gtmout} ]] && gtmout=0

				if (( gtmout > 0 )); then
					(sleep ${gtmout};
					 kill -0 $$ 2> /dev/null && kill $$) &

					gtmoutpid=$!
				fi
				;;

			'wait')
				dequeue 1
				;;

			'quiet')
				_quiet=:
				;;

			'verb')
				_quiet=
				;;

			'quit')
				break
				;;

			*)
				$_quiet echo ${REPLY}: unknown keyword \
					-- ignored >&2
				;;

			esac

			continue
			;;
		esac

		dequeue "${ncpu}"
		if [[ "$*" = *"{}"* ]]; then
			REPLY=${REPLY//\//\/}
			set -f
			#seta args "$@"
			args=( "$@" )
			set +f
			i=0
			while (( i < ${#args[*]} )); do
				if [[ ${args[i]} = *"{}"* ]]; then
					args[i]=${args[i]//{\}/${REPLY}}
				fi
				(( i += 1 ))
			done
		else
			set -f
			#seta args "$@" ${REPLY}
			args=( "$@" ${REPLY} )
			set +f
		fi
		enqueue "${nice}" "${tmout}" "${args[@]}"
set +x
	done

	dequeue 1
}

# ~/.ssh/config
# Host *
# Protocol=2
# LogLevel=ERROR
# StrictHostKeyChecking=no
# NoHostAuthenticationForLocalhost=yes
# PasswordAuthentication=no
# ForwardAgent=no
# ForwardX11=no
# ForwardX11Trusted=no
# ConnectionAttempts 5
# ConnectTimeout 30
# ServerAliveInterval 30
# TCPKeepAlive yes

_coef=0 _nice=0 _tmout=0 _gtmout=0 _quiet= _ncpu=0
sep1= sep2= host= gtmoutpid=0
unset _hosts _opts pids hosts tmouts

while getopts ':?c:g:hm:n:o:qs:t:v' c; do
case ${c} in

'c')
	_ncpu=${OPTARG}
	;;

'g')
	_gtmout=${OPTARG}
	;;

'h')
	usage
	;;

'm')
	_coef=${OPTARG}
	;;

'n')
	_nice=${OPTARG}
	;;

'o')
	_opts=${_opts}${sep2}${OPTARG}; sep2=' '
	;;

'q')
	_quiet=:
	;;

's')
	[[ -f ${OPTARG} ]] && OPTARG=$(< ${OPTARG})
	_hosts=${_hosts}${sep1}${OPTARG}; sep1=' '
	;;

't')
	_tmout=${OPTARG}
	;;

'v')
	_quiet=
	;;

*)
	usage "${OPTARG}"
	;;
esac
done
shift $((OPTIND-1))

if [[ -n ${_hosts} ]]; then
	set -f
	#seta _hosts ${_hosts}
	_hosts=( ${_hosts} )
	set +f

	_ncpu=${#_hosts[*]}
elif (( _ncpu < 1 )); then
	set_ncpu

	(( _ncpu == 0 )) && _ncpu=1
fi

trap onexit EXIT
trap onsig HUP INT TERM

_time0=${SECONDS}

parallel "$@" << EOF
! ncpu=${_ncpu}
! coef=${_coef}
! nice=${_nice}
! tmout=${_tmout}
! gtmout=${_gtmout}
$(cat)
EOF

#eof
