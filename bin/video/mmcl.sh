#!/bin/sh
#
# Copyright (c) 2006-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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

# echo=echo
PATH=$PATH:/opt/wbin
(( $# == 0 )) &&  set Movies Manga Series Reportages Music Games Progs Docs ''
for dir; do
if [[ ${dir} = *.[Aa][Vv][Ii] ]]; then
	files=${dir#./}
	src=$PWD  tgt=_
	IFS=:
else
	files='*.[Aa][Vv][Ii]'
	src='D:/P2P/eIncoming/'$dir
	tgt='D:/eMule/'$dir
fi
cd "${src}" || continue
for file in *.mp4 *.mkv *.ogm; do
	[[ ${file} = "*.mp4" || ${file} = "*.mkv" || ${file} = "*.ogm" ]] && continue
	mv -v -- "${file}" "${tgt}/"
done
for file in ${files}; do
	if [[ ${file} = */* ]]; then
		idir=${file%/*}/
		odir=/${idir}
		bfile=${file##*/}
	else
		idir= odir=/
		bfile=${file}
	fi
	[[ ${bfile} = "*.[Aa][Vv][Ii]" || ${bfile} = _*.[Aa][Vv][Ii] ]] && continue
	bfile=${bfile%.[Aa][Vv][Ii]}.avi
	tfile=${bfile}
	if [[ ${IFS} = : ]]; then
		cd "${idir%/}" && echo "${idir%/}" || continue
		idir= odir=/ file=${bfile}
		tfile=$(mktemp -u XXXXXXXXXX.avi)
		if ! $echo mv -v -- "${file}" "${tfile}"; then
			cd - > /dev/null
			continue
		fi
		file=${tfile}; tfile=${bfile}; bfile=${file}
	else
		echo "${file}"
	fi
	[[ -d "${tgt}${odir}" ]] || mkdir -p "${tgt}${odir}"
	$echo mmcl --unpack "${file}" "${tgt}${odir}${bfile}"
	rc=$?
	if (( rc == 0 )) && [[ -f "${tgt}${odir}${bfile}" ]]; then
		s1=$(stat -c %s "${file}")
		s2=$(stat -c %s "${tgt}${odir}${bfile}")
		[[ ${IFS} = : ]] &&
		$echo mv -v -- "${tgt}${odir}${bfile}" "${tgt}${odir}${tfile}"
		if (( s2 >= (s1-(s1/1000)) )); then
			$echo rm -f -- "${file}"
		else
			bfile=${tfile}
			$echo mv -v -- "${file}" "${idir}_${bfile}"
		fi
	elif (( rc == 2 )) || file "${file}" | grep -q "DivX 3"; then
		bfile=${tfile}
		$echo mv -v -- "${file}" "${tgt}${odir}${bfile}"
	else
		bfile=${tfile}
		$echo mv -v -- "${file}" "${tgt}${odir}_${bfile}"
	fi
	if [[ ${IFS} = : ]]; then
		cd - > /dev/null
	fi
done
done
