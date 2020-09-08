#!/bin/bash
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
			if [ ! -z $2  ] && [ ! -z $3 ]
			then
				echo "Extra variable is present "
				expcode="M-TRANSFORMER-BERT-FUSE"
				inst_type=$3
				inst_id=$2
				echo $inst_type
				echo $inst_id
				aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --region us-east-1 --payload '{"action":"'$action'","inst_type":"'$inst_type'","expcode":"'$expcode'","inst_id":"'$inst_id'"}' outfile ; cat outfile
			else
				read -p 'Enter valid experiment no. : ' experimentno
				if [ ! -z experimentno ]
				then
					if [ `grep -c "ExpNo=\"$experimentno\"" /mnt/efs/training-records.txt` -gt 1 ]
					then
						echo "Hey! Please check the file \"/mnt/efs/training-records.txt\" as there are multiple entries with same experiment number $experimentno "
					else
						pattern=`sed -n "/$experimentno/p" /mnt/efs/training-records.txt`
						echo $pattern
						inst_type=`echo $pattern|grep -Po 'Instance-Type="\K[^"]*'`
						if [ $? -ne 0 ]; then
							echo "found Not match"
							echo "using default instance type"
                                                	inst_type="p2.xlarge"
						fi
						expcode=`echo $pattern|grep -Po 'ExpCode="\K[^"]*'`
						if [ $? -ne 0 ]; then
							echo "not matched"
							expcode="M-TRANSFORMER-BERT-FUSE"
						fi
						expno=`echo $pattern|grep -Po 'ExpNo="\K[^"]*'`
						if [ $? -ne 0 ]; then
							echo "Experiment no. does not match from file"
							exit 1
						fi
						echo $expno
						echo $expcode
						echo $inst_type
						aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --region us-east-1 --payload '{"action":"'$action'","inst_type":"'$inst_type'","expcode":"'$expcode'","expno":"'$expno'"}' outfile ; cat outfile
					fi
				else
					echo "Please verify your experiment no. you entered as it does not match from file."
				fi
			fi
		else 
			echo "Listing the experiments"
			aws lambda invoke --function-name "nv-manage-spot-edit-score-dev" --region us-east-1 --payload '{"action":"'$action'"}' listfile 
			a=`sed -n "/Training/p" listfile`
			echo $a | cut -d "[" -f2 | cut -d "]" -f1 > listfile2
		#	echo `pwd`
			if [ -s listfile2 ]
			then
			echo "empty file no response"
			touch stopped-exp
			while read r; do echo $r|grep -Po 'ExpNo="\K[^"]*'>> stopped-exp; done < /mnt/efs/training-records.txt
                        sed -i 's/^/"/;s/$/"/' stopped-exp
                        sed -e 's/$/            "Stopped"/' -i stopped-exp
                        #cat stopped-exp 
                        echo "EXPERMENT no.     Status" > outfile
                        cat stopped-exp >> outfile
			rm -rf sample sample2 stopped-exp 
                        cat outfile

			else 
			tr -s ', ' '\n' < listfile2 > running-exp
			while read r; do grep $r /mnt/efs/training-records.txt; done < running-exp > sample
			awk 'NR==FNR{a[$0]=1;next}!a[$0]' sample /mnt/efs/training-records.txt > sample2
			while read r; do echo $r|grep -Po 'ExpNo="\K[^"]*'>> stopped-exp; done < sample2
			sed -i 's/^/"/;s/$/"/' stopped-exp
			sed -e 's/$/            "Stopped"/' -i stopped-exp
			sed -e 's/$/            "Running"/' -i running-exp
			cat stopped-exp >> running-exp
			echo "EXPERMENT no.     Status" > outfile
			cat running-exp >> outfile
			rm -rf sample sample2 stopped-exp listfile
			cat outfile
			fi
		fi
	else
		echo "Your operation is invalid ..It should be either start , stop or list"
	fi
fi
