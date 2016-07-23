#!/bin/sh
SSH_ORIGINAL_COMMAND=${SSH_ORIGINAL_COMMAND:-$*}
PATH=/bin:/usr/bin
sudoers=/root/sudoers
debug () {
	set -x
}
error () {
	echo "$@" >&2
	exit 128
}
reset () {
	check=1
	args=${SSH_ORIGINAL_COMMAND}
	path=${PATH} precmd=
	
}
sudoers=/root/sudoers2
check () {
	[ ${check} = 0 ] && return 0

case ${args} in
*\"*) _args=$(echo "_${args}_" | sed -e 's|^_||;s|_$||' \
-e 's|"\\"|--dq--|g' \
-e 's|\\""|--dq--|g' \
-e 's|\\"\([^ ]\{1,\}\)\\"|\1|g' \
-e 's|"||g' \
-e 's|--dq--|"|g' \
) ;;
*) _args=${args} ;;
esac
	echo "_${_args}_" | egrep -q "^_${arg}_$"
	check=$?
	return 1

	echo "_${args}_" | egrep -q "^_${arg}_$"
	check=$?
	[ ${check} = 0 ] && return 1
	case ${arg} in *\"*)
	arg=$(echo "_${arg}_" | sed -e 's|^_||;s|_$||;s|"|\\\\"|g')
	echo "_${args}_" | egrep -q "^_${arg}_$"
	check=$?
	[ ${check} = 0 ] && return 1
	arg=$(echo "_${arg}_" | sed -e 's|^_||;s|_$||;s|\\\\"||g')
	echo "_${args}_" | egrep -q "^_${arg}_$"
	check=$? ;;
	esac
	return 1
}
subst () {
	[ ${check} != 0 ] && return
	check=1
	args=$(echo "_${args}_" | sed -e 's|^_||;s|_$||' -e "${arg}")
}
path () {
	[ ${check} != 0 ] && return
	case $1 in
	=) path=${arg} ;;
	-) path=${arg}:${path} ;;
	+) path=${path}:${arg} ;;
	esac
}
precmd () {
	[ ${check} != 0 ] && return
	precmd=${arg}
}
reset
lineno=0
while read -r cmd arg; do
lineno=$(( ${lineno} + 1 ))
case ${cmd} in
''|\#*) : no-op ;;
debug) debug ;;
reset) reset ;;
check) check && break ;;
subst) subst ;;
path=) path = ;;
path-) path - ;;
path+) path + ;;
precmd) precmd ;;
*) error "${lineno}:${cmd}: action inconnue" ;;
esac
done < "${sudoers}"
[ ${check} != 0 ] && error "${args}: commande non autorisee"
[ "_${path}_" != "_${PATH}_" ] && PATH=${path}
[ "_${precmd}_" != "__" ] && eval "${precmd}"
args=${SSH_ORIGINAL_COMMAND}
unset SSH_ORIGINAL_COMMAND
eval exec ${args}
