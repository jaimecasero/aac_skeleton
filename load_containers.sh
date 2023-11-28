set -e

for i in  $(find ./target/architecture/ -name '*.json'); do
  if [[ "$i" != *"nfrs"* ]]; then
    echo "loading $i"
    curl -H "x-api-key: $API_KEY" -d @$i -X POST "$API_URL/$DB_NAME/containers"
  fi
done