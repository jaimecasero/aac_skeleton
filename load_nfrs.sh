set -e
for i in ./target/architecture/nfrs/*.json; do
    echo -e "\nloading $i"
    curl -H "x-api-key: $API_KEY" -d @$i -X POST "$API_URL/$DB_NAME/nfrs"
done