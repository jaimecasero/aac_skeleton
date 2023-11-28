set -e
##########################NFRS
# read each item in the JSON array to an item in the Bash array
mkdir -p "./target"
curl -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/nfrs" > ./target/nfrs.json
readarray -t nfr_array < <(jq --compact-output '.[]' ./target/nfrs.json)
output_file=./architecture/nfrs.adoc
echo -e "\n" >> $output_file
echo ".A Container Tech-Requirements" >> $output_file
echo "|===" >> $output_file
echo "| Req  | Title | Keywords" >> $output_file
# iterate through the Bash array
for item in "${nfr_array[@]}"; do
  nfr_id=$(jq --raw-output '.id' <<< "$item")
  keywords=$(jq --raw-output '.keywords' <<< "$item")
  keywords=$(echo "$keywords" | tr -d '\n')
  echo "|<<./nfrs/$nfr_id.adoc#,$nfr_id>>| $(jq --raw-output '.title' <<< "$item") | $keywords" >> $output_file
done
echo -e "\n" >> $output_file
echo "|===" >> $output_file

