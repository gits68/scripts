#!/bin/sh
#! -*- ksh -*-
#ident @(#) $Header: /package/cvs/exploitation/sbin/Attic/sudoers.sh,v 1.1.2.7 2010/02/15 17:47:15 cle Exp $
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

# pour test en ligne de commande
# SSH_ORIGINAL_COMMAND=${SSH_ORIGINAL_COMMAND:-$*}

debug () {
	typeset -ft reset reject accept subst path precmd _eval accept_alt
	set -x
}
error () {
	echo "$@" >&2
	exit 128
}
reset () {
	accept=1
	args="${SSH_ORIGINAL_COMMAND}"
	path="${PATH}" precmd=
}
reject () {
	echo "_${args}_" | egrep -q "^_.*${arg}.*_$"
}
accept () {
	[ ${accept} = 0 ] && return 0
	echo "_${args}_" | egrep -q "^_${arg}_$"
	accept=$?
	[ ${accept} = 0 ] && return 1
	case ${arg} in
	*\"*)
		arg=$(echo "_${arg}_" | sed -e 's|^_||;s|_$||;s|"|\\\\"|g')
		echo "_${args}_" | egrep -q "^_${arg}_$"
		accept=$?
		[ ${accept} = 0 ] && return 1
		arg=$(echo "_${arg}_" | sed -e 's|^_||;s|_$||;s|\\\\"||g')
		echo "_${args}_" | egrep -q "^_${arg}_$"
		accept=$?
		;;
	esac
	return 1
}
accept_alt () {
	[ ${accept} = 0 ] && return 0
	case ${args} in
	*\"*)
		_args=$(echo "_${args}_" |
			sed -e 's|^_||;s|_$||' \
			    -e 's|\\"\([^ ]\{1,\}\)\\"|\1|g' \
			    -e 's|"\([^ ]\{1,\}\)"|\1|g' \
			    -e 's|[^\\]""|"|g' \
		)
		;;
	*)
		_args="${args}"
		;;
	esac
	echo "_${_args}_" | egrep -q "^_${arg}_$"
	accept=$?
	return 1
}
subst () {
	[ ${accept} != 0 ] && return
	accept=1
	args=$(echo "_${args}_" | sed -e 's|^_||;s|_$||' -e "${arg}")
}
path () {
	[ ${accept} != 0 ] && return
	if [ "_${1}_" = '__' -o  "_${1}_" = '_=_' ]; then
		path="${arg}"
	else
		case ":${path}:" in
		*:"${arg}":*) return ;;
		esac
		case $1 in
		'^') path="${arg}:${path}" ;;
		'$') path="${path}:${arg}" ;;
		esac
	fi
}
precmd () {
	[ ${accept} != 0 ] && return
	precmd="${arg}"
}
_eval () {
	args=$(eval printf "' %s'" "${args}")
	args="${args# }"
}

[[ -z ${SSH_ORIGINAL_COMMAND} ]] && error "\${SSH_ORIGINAL_COMMAND}: not set"

PATH='/bin:/usr/bin'
sudoers="${HOME}/.ssh/sudoers"
lineno=0

reset
while read -r cmd arg; do
	lineno=$(( ${lineno} + 1 ))
	case ${cmd} in
	''|\#*)
		: no-op
		;;
	debug)
		debug; set -x
		;;
	reset)
		reset
		;;
	eval)
		_eval
		;;
	reject)
		reject && break
		;;
	accept)
		# accept && break
		accept_alt && break
		;;
	subst)
		subst
		;;
	path)
		_arg="${arg%% *}"
		arg="${arg#* }"
		path "${_arg}"
		;;
	precmd)
		precmd
		;;
	*)
		error "${lineno}: action inconnue (${cmd})"
		;;
	esac
done < "${sudoers}"

[ ${accept} != 0 ] && error "${lineno}: commande non autorisee (${args})"
[ "_${path}_" != "_${PATH}_" ] && PATH="${path}"
[ "_${precmd}_" != "__" ] && eval "${precmd}"

args=${SSH_ORIGINAL_COMMAND}
unset SSH_ORIGINAL_COMMAND

eval exec ${args}

# eof
