set -e
mkdir -p "./target"
declare -A components
components[smsc]=SMSC
components[pgw]=PGW
components[sdm]=SDM
components[traffic_controller]=TC
for component_key in "${!components[@]}"
do
echo $component_key
output_file=./architecture/$component_key.adoc
component_filter=`echo 'filter={"keywords": {"$all":["COMPONENT_'${components[$component_key]}'"]}}'`
echo $component_filter
curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={}' --data-urlencode 'group=nfrs.applicability' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_report_table.sh $output_file "NFR group by Applicability"
./print_report_chart.sh $output_file "NFR group by Applicability" "${component_key}_app.png"

curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={"nfrs.applicability" : "APPLICABLE"}' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_report_table.sh $output_file "Applicable NFR group by Implementation"
./print_report_chart.sh $output_file "Applicable NFR group by Implementation" "${component_key}_app_impl.png"

curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={"$and" : [{"nfrRelated.keywords": {"$all":["NFR_LEVEL_MANDATORY"]}}, {"nfrs.applicability" : "APPLICABLE"}]}' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_report_table.sh $output_file "Applicable and Mandatory NFR group by implementation"
./print_report_chart.sh $output_file "Applicable and Mandatory NFR group by implementation" "${component_key}_app_man.png"

curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={"$and" : [{"nfrRelated.keywords": {"$all":["NFR_LEVEL_MANDATORY", "MILESTONE_FUT"]}}, {"nfrs.applicability" : "APPLICABLE"}]}' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_report_table.sh $output_file "Applicable and Mandatory and FUT NFR group by implementation"
./print_report_chart.sh $output_file "Applicable and Mandatory and FUT NFR group by implementation" "${component_key}_app_man_fut.png"
curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={"$and" : [{"nfrRelated.keywords": {"$all":["NFR_LEVEL_MANDATORY", "MILESTONE_FUT"]}}, {"nfrs.implementation" : {"$ne" : "IMPLEMENTED"}}, {"nfrs.applicability" : "APPLICABLE"}]}' -d 'group=NONE' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_nfr_table.sh $output_file "App Mandatory FUT Not Implemented List"


curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={"$and" : [{"nfrRelated.keywords": {"$all":["NFR_LEVEL_MANDATORY", "MILESTONE_MARKET_LAUNCH"]}}, {"nfrs.applicability" : "APPLICABLE"}]}' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_report_table.sh $output_file "Applicable and Mandatory and WML NFR group by implementation"
./print_report_chart.sh $output_file "Applicable and Mandatory and FUT NFR group by implementation" "${component_key}_app_man_wml.png"
curl -G -d "aggregate=true" --data-urlencode "$component_filter" --data-urlencode 'nfr_filter={"$and" : [{"nfrRelated.keywords": {"$all":["NFR_LEVEL_MANDATORY", "MILESTONE_MARKET_LAUNCH"]}}, {"nfrs.applicability" : "APPLICABLE"}, {"nfrs.implementation" : {"$ne" : "IMPLEMENTED"}}]}' -d 'group=NONE' -H "x-api-key: $API_KEY"  -X GET "$API_URL/$DB_NAME/containers" > ./target/query.json
./print_nfr_table.sh $output_file "App Mandatory WML Not Implemented List"


done

