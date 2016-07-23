#!/usr/bin/sh
#! -*- ksh -*-
#ident @(#) $Header: /package/cvs/exploitation/sbin/Attic/auth_sudo.sh,v 1.1.2.1 2010/01/25 15:25:48 cle Exp $
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

if [[ -n ${BASH_VERSION} ]]; then
shopt -s expand_aliases extglob xpg_echo
print () {
	if [[ $1 = *2* ]]; then
		shift 2
		\echo "$@" >&2
	else
		shift 2
		\echo "$@"
	fi
}
fi

if [[ -z ${SSH_ORIGINAL_COMMAND} ]]; then
	print -ru2 -- "\${SSH_ORIGINAL_COMMAND}: not set"
	exit 1
fi

# was '[;&|(){}<>`^$?*\]'
if print -r -- "${SSH_ORIGINAL_COMMAND}" | grep -q '[;&|(){}<>`^$]'; then
#meta=$(print -r -- "${SSH_ORIGINAL_COMMAND}" | tr -d -- '\t -/.a-zA-Z_0-9?*\\"'"'")
#if [[ -n ${meta} ]]; then
	print -ru2 -- "${SSH_ORIGINAL_COMMAND}: metacharacters rejected"
	exit 1
fi

path=/bin:/usr/bin
# /path/to/cmd arg... => /path/to/cmd
cmd="${SSH_ORIGINAL_COMMAND%% *}"
# /path/to/cmd => cmd
cmd="${cmd##*/}"
# /path/to/cmd arg... => arg...
args="${SSH_ORIGINAL_COMMAND#* }"
args="${args# }"

case ${cmd} in

'su.sh')
	path=${path}:/root
	pattern='\"-c\" \"*\"'

	subargs="${args#\"-c\" }"
	subargs="${subargs#\"}"
	subargs="${subargs%\"}"
	if [[ ${subargs} = *' '* ]]; then
		subcmd="${subargs%% *}"
		subargs="${subargs#* }"
	else
		subcmd="${subargs}"
		subargs=
	fi
	subcmd="${subcmd#\\\"}"
	subcmd="${subcmd%\\\"}"

	case ${subcmd} in
	*'export'*)
		subcmd_pattern=export
		subargs_pattern=-p
		;;
	*'wmips'*)
		subcmd_pattern='/exploitation/bin/wmips?(.sh)'
		subargs_pattern='?(@(\\"-ef\\"|@(\\"-fp\\"|\\"-fu\\") \\"+([-_a-zA-Z0-9])\\"))'
		;;
	*)
		subcmd_pattern='/exploitation/util/peu/Peu@(ControleEtat|Arret|Dem)Module.sh'
		subargs_pattern='?(\\"-t\\" )\\"-m\\" \\"+([-_a-zA-Z0-9])\\"'
		;;
	*)
		print -ru2 -- "${SSH_ORIGINAL_COMMAND}: command rejected"
		exit 1
		;;
	esac
	;;

*)
	print -ru2 -- "${SSH_ORIGINAL_COMMAND}: command rejected"
	exit 1
	;;

esac

if [[ ( -n ${pattern} && ${args} != ${pattern} ) || \
      ( -z ${pattern} && -n ${args} ) ]]; then
	print -ru2 -- "${SSH_ORIGINAL_COMMAND}: bad argument"
	exit 1
fi

if [[ ( -n ${subcmd_pattern} && ${subcmd} != ${subcmd_pattern} ) || \
      ( -z ${subcmd_pattern} && -n ${subcmd} ) ]]; then
	print -ru2 -- "${SSH_ORIGINAL_COMMAND}: bad argument (subcmd)"
	exit 1
fi

if [[ ( -n ${subargs_pattern} && ${subargs} != ${subargs_pattern} ) || \
      ( -z ${subargs_pattern} && -n ${subargs} ) ]]; then
	print -ru2 -- "${SSH_ORIGINAL_COMMAND}: bad argument (subargs)"
	exit 1
fi

if [[ -n ${path} ]]; then
	export PATH=${path}
fi

if [[ -n ${precmd} ]]; then
	eval ${precmd}
fi

#eval exec ${SSH_ORIGINAL_COMMAND}
unset SSH_ORIGINAL_COMMAND
eval exec ${cmd} ${args}

# eof
