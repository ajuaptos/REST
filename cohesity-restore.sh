#!/bin/bash

PROGNAME=$(basename $0)
PORT=80
API=irisservices/api/v1

usage() {
  echo "Usage: ${PROGNAME} <node-ip-address>"
  exit 1
}

if [ "$#" -ne "1" ]
then
  usage
fi

TARGET=$1

# Get an authentication token first.
token=$(curl -k -H "Accept: application/json" -d '{
    "username":"admin",
    "password":"admin"
}' https://${TARGET}/${API}/public/accessTokens 2> /dev/null | \
  awk -F":" '/:/ {printf $2}' | sed 's/["}]//g' |sed 's/,tokenType//')

echo ${token}

echo "Test 1: Search all objects that can be restored."
curl -w '\n%{http_code}\n%{content_type}' -k  \
  -H "Accept: application/json" \
  -H "authorization: Bearer ${token}" \
  https://${TARGET}/${API}/public/restore/objects

echo "Test 2: Search a particular VM."
curl -w '\n%{http_code}\n%{content_type}' -k \
  -H "Accept: application/json"  \
  -H "authorization: Bearer ${token}" \
  https://${TARGET}/${API}/public/restore/objects?search=TTYLinux_manoj_2

echo "Test 3: Search by job Id."
curl -w '\n%{http_code}\n%{content_type}' -k \
  -H "Accept: application/json"  \
  -H "authorization: Bearer ${token}" \
  https://${TARGET}/${API}/public/restore/objects?jobId=3

echo "Test 4: Create a RecoverVM Restore Task."
curl -w '\n%{http_code}\n%{content_type}' -k \
  -H "Accept: application/json"  \
  -H "authorization: Bearer ${token}" \
  -d '{
  "type": "kRecoverVMs",
  "name": "RecoveringManojVM",
  "objects": [
    {
      "jobUid": {
        "id": 3,
        "clusterId": 3243595861545562,
        "clusterIncarnationId": 1490296324490
      },
      "protectionSourceId": 2208,
      "jobRunId": 37,
      "startedTimeUsecs": 1490305979317683
    }
  ],
  "prefix": "mahesh-1",
  "suffix": "restored"
}' https://${TARGET}/${API}/public/restore/recover
