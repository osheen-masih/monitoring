#!/bin/bash
action=$1
if [ -z $1 ]
then
	echo "you have not entered any argument to perform action"
	exit 1
else
	action=$1
	echo $action
	if [ $action == "list" ] || [ $action == "start" ] || [ $action == "stop" ]
	then
		echo "valid action"
		if [ $action != "list" ]
		then
			if [ -z $2 ] && [ -z $3 ] 
			then
				read -p 'EXPCode: ' expcode ; read -p 'Instance_Type: ' inst_type 
				if [[ -z  $expcode  ]]
				then
					expcode="M-TRANSFORMER-BERT-FUSE"
					if [[ -z $inst_type ]]
					then
						inst_type="p2.xlarge"
					fi
				fi
			else 
				echo "There are expcode and instance type as parameter so not reading from user"
				expcode=$2
				inst_type=$3		
			fi
		fi
	else
		echo "Invalid action"
		exit 1

	fi
fi
#aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --payload '{"action":"$action","inst_type":"$inst_type","expcode":"$expcode"}' outfile ; cat outfile

