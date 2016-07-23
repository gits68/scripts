for i; do
	awk -F'[<>:]' '
/ChapterTimeStart/{t=$3*3600+$4*60+$5;next}
/ChapterString/{printf "AddChapterBySecond(%d,%s)\n",t,$3}
' "$i" > "${i%.xml}.txt"
done
