#!/usr/bin/awk -f

BEGIN {
	fmt = 1
	maxlen = 40
}

function bar() {
	if (line1 ~ /^(<.>)?-/)
		return
	sep2 = line2 ? " " : ""
	sep3 = line3 ? " " : ""
	$0 = line1 sep2 line2 sep2 line3
	olen = len = length()
	if (! len) {
		line1 = ""
		return
	}
#	if (match($1, "({y:(.)})", a)) {
#		gsub(a[1], "<"a[2]">")
#		gsub("{y}", "</"a[2]">")
#	}
	n = gsub("</.> <.>", " ")
	len -= n * 7
	if (match($1, "(<.>)", a)) {
		sub("^"a[1], "", $1)
		pre = a[1]
		len -= length(a[1])
	}
	if (match($NF, "(</.>)", a)) {
		sub(a[1]"$", "", $NF)
		post = a[1]
		len -= length(a[1])
	}
	if (len <= maxlen) {
		line1 = pre $0 post
		line2 = line3 = ""
		pre = post = ""
		return
	}
	l = int(len / 2)
	n1 = n2 = n3 = slen = 0
	s1 = s2 = s3 = sep = ""
	for (i = 1; i <= NF; i++) {
		ll = length($i) + slen
		if (n1 + ll >= l) {
			if (n1 + ll == l) {
				n1 += ll
				s1 = s1 " " $i
			} else {
				n3 = ll
				s3 = $i
			}
			break
		} else {
			n1 += ll
			s1 = s1 sep $i
			sep = " "
			slen = 1
		}
	}
	sep = ""
	slen = 0
	for (i++; i <= NF; i++) {
		n2 += length($i) + slen
		s2 = s2 sep $i
		sep = " "
		slen = 1
	}
	if (n3) {
		if (n1 <= n2 || match(s3, "[,.;:?!]$"))
			s1 = s1 " " s3
		else
			s2 = s3 " " s2
	}
	if (! fmt)
		pre = post = ""
	line1 = pre s1
	line2 = s2 post
	line3 = pre = post = ""
}

function foo() {
	if (! line1)
		return
	bar()
	if (! line1)
		return
	print ++indice
	print time
	print line1
	if (line2)
		print line2
	if (line3)
		print line3
	print ""
}

! line1 && /^[0-9]+$/ {
	# indice = $0
	next
}
/^[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+/ {
	time = $0
	next
}
/^[ 	]*$/ {
	foo()
	time = line1 = line2 = line3 = ""
	next
}
! line1 { line1 = $0; next }
! line2 { line2 = $0; next }
! line3 { line3 = $0; next }
END { foo() }
