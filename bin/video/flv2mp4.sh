#!/usr/bin/sh
# Copyright (c) 2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
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

shopt -s extglob

mediainfo='/programs/MediaInfo/MediaInfoCli.exe'
avidemux='/programs/Avidemux 2.6 - 32 bits/avidemux.exe'

(( $# )) || set -- *.flv

for in; do
	[[ $in = *.flv ]] || continue
	out=${in%.flv}.mp4
	[[ -f $out ]] && continue
	mi=$("$mediainfo" -f "$in")
	_delay=0
	delay=$(echo "$mi" |
		awk '/Delay relative to video/{sub(/ms$/,"")
		     print ($NF < 0 ? $NF : $NF);exit}')
	shift=$(echo "$mi" |
		awk '/Duration/&&!/s$/&&!/:.+:/{print $NF*1000;exit}')
	[[ -n $delay ]] && (( delay != 0 )) && _delay=1
	in=${in//\\//}
	pwd=$(cygpath -w "${PWD}")
	pwd=${pwd//\\//}
	[[ $in = /* || $in = *:/* ]] || in=$pwd/$in
	out=${out//\\//}
	[[ $out = /* ]] || out=$pwd/$out
	py=${in%.flv}.py
	py=${py//\\//}
	wtemp=${WTEMP:-D:/Temp}
	wtemp=${wtemp//\\//}
	tmp="$wtemp/${out##*/}"
	cat << EOF > "$py"
adm = Avidemux()
adm.loadVideo("$in")
#adm.clearSegments()
#adm.addSegment(0, 0, $shift)
#adm.markerA = 0
#adm.markerB = $shift
adm.videoCodecSetProfile("x264", "_Q23BDU6")
# adm.videoCodec("x264",
# 	"useAdvancedConfiguration=True",
# 	"general.params=AQ=23",
# 	"general.threads=0",
# 	"general.preset=medium",
# 	"general.tuning=film",
# 	"general.profile=high",
# 	"general.fast_decode=False",
# 	"general.zero_latency=False",
# 	"general.fast_first_pass=True",
# 	"level=41",
# 	"vui.sar_height=1",
# 	"vui.sar_width=1",
# 	"MaxRefFrames=3",
# 	"MinIdr=25",
# 	"MaxIdr=250",
# 	"i_scenecut_threshold=40",
# 	"intra_refresh=False",
# 	"MaxBFrame=6",
# 	"i_bframe_adaptive=2",
# 	"i_bframe_bias=0",
# 	"i_bframe_pyramid=2",
# 	"b_deblocking_filter=True",
# 	"i_deblocking_filter_alphac0=0",
# 	"i_deblocking_filter_beta=0",
# 	"cabac=True",
# 	"interlaced=False",
# 	"constrained_intra=False",
# 	"tff=True",
# 	"fake_interlaced=False",
# 	"analyze.b_8x8=True",
# 	"analyze.b_i4x4=True",
# 	"analyze.b_i8x8=True",
# 	"analyze.b_p8x8=False",
# 	"analyze.b_p16x16=True",
# 	"analyze.b_b16x16=True",
# 	"analyze.weighted_pred=2",
# 	"analyze.weighted_bipred=True",
# 	"analyze.direct_mv_pred=3",
# 	"analyze.chroma_offset=0",
# 	"analyze.me_method=2",
# 	"analyze.me_range=16",
# 	"analyze.mv_range=-1",
# 	"analyze.mv_range_thread=-1",
# 	"analyze.subpel_refine=7",
# 	"analyze.chroma_me=True",
# 	"analyze.mixed_references=True",
# 	"analyze.trellis=1",
# 	"analyze.psy_rd=1.000000",
# 	"analyze.psy_trellis=0.000000",
# 	"analyze.fast_pskip=True",
# 	"analyze.dct_decimate=True",
# 	"analyze.noise_reduction=0",
# 	"analyze.psy=True",
# 	"analyze.intra_luma=11",
# 	"analyze.inter_luma=21",
# 	"ratecontrol.rc_method=0",
# 	"ratecontrol.qp_constant=0",
# 	"ratecontrol.qp_min=0",
# 	"ratecontrol.qp_max=69",
# 	"ratecontrol.qp_step=4",
# 	"ratecontrol.bitrate=0",
# 	"ratecontrol.rate_tolerance=1.000000",
# 	"ratecontrol.vbv_max_bitrate=0",
# 	"ratecontrol.vbv_buffer_size=0",
# 	"ratecontrol.vbv_buffer_init=0",
# 	"ratecontrol.ip_factor=1.400000",
# 	"ratecontrol.pb_factor=1.300000",
# 	"ratecontrol.aq_mode=1",
# 	"ratecontrol.aq_strength=1.000000",
# 	"ratecontrol.mb_tree=True",
# 	"ratecontrol.lookahead=40")
#adm.audioClearTracks()
adm.setSourceTrackLanguage(0,"und")
#adm.audioAddTrack(0)
adm.audioCodec(0, "Faac");
#adm.audioSetDrc(0, 0)
adm.audioSetShift(0, ${_delay}, ${delay:-0})
adm.setContainer("MP4", "muxerType=0", "useAlternateMp3Tag=True")
adm.save("$tmp")
EOF
	echo "$in (${delay:-0})"
	"$avidemux" --nogui --run "$py" --quit &&
	cp --backup=t -- "$tmp" "$out" &&
	rm -- "$tmp" "$py"
done
