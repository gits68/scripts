#!/usr/bin/awk -f

# function ppcm(a, b) { return b == 0 ? a : ppcm(b, a % b) }
function _pgcd(a, b) {
	while (a != b)
		if (a > b)
			a -= b
		else
			b -= a
	return a
}
function pgcd(a, b,	r) {
	while (b > 0) {
		r = a % b
		a = b
		b = r
	}
	return a
		
}

BEGIN {
	height = ARGV[1]
	width = ARGV[2]
	dar = ARGC < 4 ? 1 : ARGV[3]
	dars["1.1618:1"] = dars["1.1618"] = 1.1618 # golden ration
	dars["6:5"] = dars["6/5"] = 6/5		# fox moviestone
	dars["5:4"] = dars["5/4"] = 5/4		# old tv
	dars["4:3"] = dars["4/3"] = 4/3		# trad tv
	dars["1.37:1"] = dars["1.37"] = 1.37	# 16mm
	dars["11:8"] = dars["11/8"] = 11/8	# academy ratio
	dars["3:2"] = dars["3/2"] = 3/2		# 35mm
	dars["14:9"] = dars["14/9"] = 14/9	# compromise
	dars["16:10"] = dars["16/10"] = 16/10	# monitor
	dars["5:3"] = dars["5/3"] = 5/3		# super 16mm
	dars["128:75"] = dars["128/75"] = 128/75 # 
	dars["16:9"] = dars["16/9"] = 16/9	# hd tv
	dars["256:135"] = dars["256/135"] = 256/135 # Panoramique
	dars["64:27"] = dars["64/27"] = \
	dars["21:19"] = dars["21/19"] = 64/27	# new tv
	dars["8:3"] = dars["8/3"] = 8/3		# super 16mm
	dars["37:20"] = dars["37/20"] = \
	dars["1.85:1"] = dars["1.85"] = 1.85	# Panoramic
	dars["47:20"] = dars["47/20"] = \
	dars["2.35:1"] = dars["2.35"] = 2.35	# old CinemaScope
	dars["2.39:1"] = dars["2.39"] = 2.39	# new CinemaScope
	dars["2.414:1"] = dars["2.414"] = 2.414	# silver ratio
	dars["69:25"] = dars["69/25"] = \
	dars["2.76:1"] = dars["2.76"] = 2.76	# 70mm
	if (ARGC > 4)
		dar /= ARGV[4]
	else if (dar in dars)
		dar = dars[dar]
	else if (dar ~ /\//) {
		split(dar, _, /\//)
		dar = _[1] / _[2]
	}
	h = int(height * dar)
	w = width
	g = pgcd(h, w)
	if (g) {
		h /= g
		w /= g
		while (h > 1000 || w > 1000) {
			h /= 10
			w /= 10
		}
		if (h != int(h) || w != int(w)) {
			h *= 10
			w *= 10
		}
	} else
		h = w = 1
	print h ":" w
	exit
}
