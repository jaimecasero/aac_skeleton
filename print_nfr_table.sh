echo -e
output_file=$1

readarray -t nfr_array < <(jq --compact-output '.[]' ./target/query.json)
echo -e "\n" >> $output_file
echo ". $2" >> $output_file
echo "|===" >> $output_file
echo "| Container  | NFR ID | NFR Title | Implementation"  >> $output_file
# iterate through the Bash array
for item in "${nfr_array[@]}"; do
  container=$(jq --raw-output '.id' <<< "$item")
  nfrId=$(jq --raw-output '.nfrRelated.id' <<< "$item")
  title=$(jq --raw-output '.nfrRelated.title' <<< "$item")
  impl=$(jq --raw-output '.nfrs.implementation' <<< "$item")
  echo "|$container| $nfrId | $title | $impl" >> $output_file
done
echo -e "\n" >> $output_file
echo "|===" >> $output_file