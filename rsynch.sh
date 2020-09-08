#!/bin/bash
dir=/mnt/efs
if mountpoint -q -- "$dir"; then
  echo '%s\n' "$dir is a mount point"
else
	echo "It's not mounted."
	mount -a
	if [ $? -eq 0 ] && [ `mountpoint -q -- "$dir"` ]; then
	echo "Mount success!"
#		while true
#		do
 #       		rsync -avz /home/alla.rozovskaya /mnt/efs/backup
#		done
	else
	inst_id=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
	inst_type=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-type`
	msg="EFS is not mounted on instance : $instance_id .Launching new spot and this will be deleted."
	json="{\"text\": \"$msg\"}"
	curl -s -d "payload=$json" "https://hooks.slack.com/services/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"
	echo "Something went wrong with mount sending slack msg"
	expcode="M-TRANSFORMER-BERT-FUSE"
	action="start"
        aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --region us-east-1 --payload '{"action":"'$action'","inst_type":"'$inst_type'","expcode":"'$expcode'","inst_id":"'$inst_id'"}' outfile ; cat outfile
	if [ $? -eq 0 ]; then
		action="stop"
		aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --region us-east-1 --payload '{"action":"'$action'","inst_type":"'$inst_type'","expcode":"'$expcode'","inst_id":"'$inst_id'"}' outfile ; cat outfile
	fi
fi

fi
