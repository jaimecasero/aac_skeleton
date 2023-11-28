for i in architecture/nfrs/NFR*.adoc; do # Whitespace-safe but not recursive.
  ID=`head -n1 $i | cut -d' ' -f2`
  TITLE=`head -n1 $i | cut -d' ' -f3-`
  KEYWORDS=`cat $i | grep ":keywords:" |  cut -f2- -d' ' | sed 's/, /\",\"/g'`
  NAME=`echo "target/$i" | cut -d'.' -f1`.json
  mkdir -p "${NAME%/*}"
  echo "Writing $NAME"
  echo "{" > $NAME
  echo "\"id\":\"$ID\"," >> $NAME
  echo "\"title\":\"$TITLE\"," >> $NAME
  echo "\"keywords\":[\"$KEYWORDS\"]" >> $NAME
  echo "}" >> $NAME
done