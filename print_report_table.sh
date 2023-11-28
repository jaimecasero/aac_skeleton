echo -e
output_file=$1

echo -e "\n" >> $output_file
readarray -t nfr_array < <(jq --compact-output '.[]' ./target/query.json)
echo ". $2" >> $output_file
echo "|===" >> $output_file
echo "| Group  | Count"  >> $output_file
# iterate through the Bash array
for item in "${nfr_array[@]}"; do
  group=$(jq --raw-output '._id' <<< "$item")
  count=$(jq --raw-output '.countNfr' <<< "$item")
  echo "|$group| $count" >> $output_file
done
echo -e "\n" >> $output_file
echo "|===" >> $output_file