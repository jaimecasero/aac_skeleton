echo -e
output_file=$1

echo -e "\n" >> $output_file
readarray -t nfr_array < <(jq --compact-output '.[]' ./target/query.json)
data=""
labels=""
# iterate through the Bash array
for item in "${nfr_array[@]}"; do
  group=$(jq --raw-output '._id' <<< "$item")
  count=$(jq --raw-output '.countNfr' <<< "$item")
  if [[ "$data" == "" ]]; then
    data=$count
    labels=`echo "$group $count"`
  else
    data=`echo $data,$count`
    labels=`echo "$labels|$group $count"`
  fi
done

targetImage=./architecture/img/$3
mkdir -p "${targetImage%/*}"
curl -d "cht=p" -d "chs=640x400" -d "chd=t:$data" -d "chl=$labels" -X POST "https://chart.googleapis.com/chart" > $targetImage

echo "image::img/$3[$2]" >> $output_file