#!/bin/bash

TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

while sleep 5; do

    HTTP_CODE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s -w %{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action)

    if [[ "$HTTP_CODE" -eq 401 ]] ; then
        echo 'Refreshing Authentication Token'
        TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 30"`
    elif [[ "$HTTP_CODE" -eq 200 ]] ; then
	inst_id=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
        inst_type=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-type`
	expcode="M-TRANSFORMER-BERT-FUSE"
	action="start"
        aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --region us-east-1 --payload '{"action":"'$action'","inst_type":"'$inst_type'","expcode":"'$expcode'","inst_id":"'$inst_id'"}' outfile ; cat outfile
    else
        echo 'Not Interrupted'
    fi

done
