#!/bin/bash

HOME_DIR=/home/prod
ALERT_MAIL=$HOME_DIR/karank/alert_mail.txt
MAIL_RECEPIENTS='karank@glam.com,tanvira@glam.com,sanjayd@glam.com,anwars@glam.com,aswinikumarc@glam.com,bryanb@mode.com'
TMP=$HOME_DIR/karank/job_details.list
FROM_ADDRESS=karank@glam.com
JOB_TRACKER_HOST=cshdpm3.glam.colo
JOB_TRACKER_PORT=50030

#Command to list jobs running in Hadoop
hadoop job -list |tail -n+3 | cut -f 1,3,4 > $TMP 

#Threshold minutes for checking a job
threshold_mins=120
threshold_secs=$(( $threshold_mins * 60 ))

#This while loop compares the start time of the job with the current time
while read job_id  startTime job_user ; do
startTime=$(echo $startTime | cut -c 1-10 )
time_now=$(date '+%s')
timediff=$(( $time_now - $startTime ))
timediff_minutes=$(( $timediff / 60 ))

#JOB URL
job_url=http://$JOB_TRACKER_HOST:$JOB_TRACKER_PORT/jobdetails.jsp?jobid=$job_id

#Get job name from job web page
job_name=$(curl $job_url -s  | w3m -dump -T text/html | grep 'Job Name' | sed  's/&apos;/'\''/g')
	if [ $timediff -gt  $threshold_secs ] 
	then
        printf " \n $job_name \n " >> $ALERT_MAIL
        printf " $job_id (user = $job_user) is running for $timediff_minutes minutes \n " >> $ALERT_MAIL
	fi
 	
done < $TMP

if [ -f $HOME_DIR/karank/alert_mail.txt ]
then
mail -s "COLO-Hadoop JOB status" -r $FROM_ADDRESS $MAIL_RECEPIENTS  < $ALERT_MAIL
fi

rm -f $ALERT_MAIL
