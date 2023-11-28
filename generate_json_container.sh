for i in architecture/**/*.adoc; do

  ID=`echo "$i" | cut -d'.' -f1 | cut -d'/' -f3`
  KEYWORDS=`cat $i | grep ":keywords:" |  cut -f2- -d' ' | sed 's/, /\",\"/g'`
  if [[ "$KEYWORDS" == *"CONTAINER_RECORD"* ]]; then
    ##calculate output filename and create dir
    NAME=`echo "target/$i" | cut -d'.' -f1`.json
    mkdir -p "${NAME%/*}"
    echo "Writing $NAME"

    ##print basic field

    echo "{" > $NAME
    echo "\"id\":\"$ID\"," >> $NAME
    echo "\"keywords\":[\"$KEYWORDS\"]," >> $NAME

    ##add nfr array from asciidoc table
    echo "\"nfrs\" : [" >> $NAME
    total=$(cat $i | grep "nfrs/NFR" | wc -l)
    echo "totalNFR:$total"
    nfrcounter=0
    cat $i | grep "nfrs/NFR" | while read line
    do
       nfrcounter=$((nfrcounter+1))
       NFR=`echo $line | cut -d'|' -f2 | cut -d',' -f2| cut -d ' ' -f1`
       APPLICABILITY=`echo $line | cut -d'|' -f4 | tr -d '[:blank:]'`
       IMPLEMENTATION=`echo $line | cut -d'|' -f5 | tr -d '[:blank:]'`
       echo "{" >> $NAME
       echo "\"nfr\":\"$NFR\"," >> $NAME
       echo "\"applicability\":\"$APPLICABILITY\"," >> $NAME
       echo "\"implementation\":\"$IMPLEMENTATION\"" >> $NAME
       if [[ $nfrcounter != $total ]]; then
        echo "}," >> $NAME
       else
         echo "}" >> $NAME
       fi
    done
    echo "]" >> $NAME

    echo "}" >> $NAME
  fi
done