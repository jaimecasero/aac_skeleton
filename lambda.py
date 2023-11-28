"""
  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  A copy of the License is located at

      http://www.apache.org/licenses/LICENSE-2.0

  or in the "license" file accompanying this file. This file is distributed
  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
  express or implied. See the License for the specific language governing
  permissions and limitations under the License.
"""
import json
import boto3
import os
import ast
import pymongo
import bson
import datetime
## GLOBALS
db_client = None
db_secret_name = os.environ['DB_SECRET_NAME']
pem_locator ='/opt/python/global-bundle.pem'
datetime_str = "%Y-%m-%dT%H:%M:%S"
## HELPERS
def stringify(doc):
    if (type(doc) == str):
        return doc
    if (type(doc) == dict):
        for k, v in doc.items():
            doc[k] = stringify(v)
    if (type(doc) == list):
        for i in range(len(doc)):
            doc[i] = stringify(doc[i])
    if (type(doc) == bson.ObjectId):
        doc = str(doc)
    if (type(doc) == datetime.datetime):
        doc = doc.strftime(datetime_str)
    return doc
## DOCUMENTDB CREDENTIALS
def get_credentials():
    """Retrieve credentials from the Secrets Manager service."""
    boto_session = boto3.session.Session()
    try:
        secrets_client = boto_session.client(service_name='secretsmanager', region_name=boto_session.region_name)
        print("getting secret:" + db_secret_name)
        secret_value = secrets_client.get_secret_value(SecretId=db_secret_name)
        print("secret retrieved")
        secret = secret_value['SecretString']
        secret_json = json.loads(secret)
        username = secret_json['username']
        password = secret_json['password']
        host = secret_json['host']
        port = secret_json['port']
        return (username, password, host, port)
    except Exception as ex:
        raise
## DOCUMENTDB CONNECTION
def get_db_client():
    # Use a global variable so Lambda can reuse the persisted client on future invocations
    global db_client
    if db_client is None:
        try:
            # Retrieve Amazon DocumentDB credentials
            (secret_username, secret_password, docdb_host, docdb_port) = get_credentials()
            print("docdb_host:" + docdb_host )
            db_client = pymongo.MongoClient(
                host=docdb_host,
                port=docdb_port,
                tls=True,
                retryWrites=False,
                tlsCAFile=pem_locator,
                username=secret_username,
                password=secret_password,
                authSource='admin')
            print("connected to db")
        except Exception as e:
            print('Failed to create new DocumentDB client: {}'.format(e))
            raise
    return db_client
## Extract the db.collection from event and return collection
def collection_from_event(event):
    path = event["path"].rstrip("/")
    print("path: " + path)
    splits = path.split("/")
    collection_name = splits[-1]
    db_name = splits[-2]
    get_db_client()
    if "latest" == db_name:
        db_names= db_client.list_database_names()
        db_name = db_names[-1]
    print("db_name: " + db_name + "; collection_name: " + collection_name)
    db = db_client[db_name]
    collection = db[collection_name]
    return collection

## Handle POST
def handle_post(event):
    collection = collection_from_event(event)
    body = json.loads(event["body"])
    print(body)
    collection.insert_one(body)
    print("body inserted")
    return stringify(body)
## Handle GET
def handle_get(event):
    collection = collection_from_event(event)
    input_qs = event["queryStringParameters"]
    filter = None
    projection = None
    sort = None
    limit = 0
    skip = 0
    if None != input_qs:
        if "filter" in input_qs.keys():
            filter = json.loads(input_qs["filter"])
        if "projection" in input_qs.keys():
            projection = json.loads(input_qs["projection"])
        if "sort" in input_qs.keys():
            sort = ast.literal_eval(input_qs["sort"])
        if "limit" in input_qs.keys():
            limit = int(input_qs["limit"])
        if "skip" in input_qs.keys():
            skip = int(input_qs["skip"])

    print(filter)
    res = list(collection.find(filter=filter, projection=projection, sort=sort, limit=limit, skip=skip))
    return stringify(res)

def handle_get_aggregation(event):
    collection = collection_from_event(event)
    input_qs = event["queryStringParameters"]
    filter ={"keywords": {"$all":['MODULE_1CORE']}}
    nfr_filter = {"nfrRelated.keywords": {"$all":['NFR_LEVEL_MANDATORY']}}
    group="nfrs.implementation"
    if None != input_qs:
        if "filter" in input_qs.keys():
            filter = json.loads(input_qs["filter"])
        if "nfr_filter" in input_qs.keys():
            nfr_filter = json.loads(input_qs["nfr_filter"])
        if "group" in input_qs.keys():
            group = input_qs["group"]


    pipeline = [
        {"$match": filter}
        ,{"$unwind": "$nfrs"}
        ,{"$lookup": {"from": "nfrs","foreignField" : "id","localField" : "nfrs.nfr","as": "nfrRelated"}}
        ,{"$unwind": "$nfrRelated" }
        ,{"$match": nfr_filter}
    ]
    if group != "NONE":
        pipeline.append({"$group" : {"_id":"$" + group , "countNfr":{"$sum":1}}})
    else:
        pipeline.append({"$project": {"id": 1, "nfrRelated.id" : 1, "nfrRelated.title" : 1}})

    res = list(collection.aggregate(pipeline))
    return stringify(res)

# Lambda Handler
def lambda_handler(event, context):
    print(event)
    httpMethod = event["httpMethod"]
    retval = "Done"
    if "GET" == httpMethod:
        if event["queryStringParameters"] != None and "aggregate" in event["queryStringParameters"]:
            retval = handle_get_aggregation(event)
        else:
            retval = handle_get(event)
    elif "POST" == httpMethod:
        retval = handle_post(event)

    print(retval)

    return {
        'statusCode': 200,
        'body': json.dumps(retval)
    }