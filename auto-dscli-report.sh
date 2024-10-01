#!/bin/bash
#-------------------------------------------------------#
# 	Created by Ismael Thiago Marques		#
# 	MF z/OS Storage Support        			# 
# 	E-mail: ithig@br.ibm.com       			#
# 				   			#
# The purpose of this script is to automate rank report #
#-------------------------------------------------------#
# IP LIST HERE (one per line):
#-------------------------------------------------------#
echo "9.xx.xxx.xxx
9.xx.xxx.xx
9.xx.xxx.xx
" > /tmp/iplist
#-------------------------------------------------------#
# IP address list reminder
#-------------------------------------------------------#
clear
echo -n "Have you added the IP Addresses in this .sh file (y/n)? "
read yn
if [ "$yn" == "n" ]
then
	echo "Please, open this .sh file and add the IPs (one per line)"
	sleep 4
	exit
else
	clear
fi
#-------------------------------------------------------#
# MENU
#-------------------------------------------------------#
echo "-------------------------------------------------------"
echo "	Select an option:"
echo 
echo "	1 - Rank Report"
echo "	2 - List IP Adresses"
echo "	3 - Convert report to XML"
echo "	4 - Test accesses"
echo "	0 - Exit"
echo "-------------------------------------------------------"
echo -n "op: "
read menu
#-------------------------------------------------------#
# VARIABLES
#-------------------------------------------------------#
ts=$(date +"%Y-%m-%d-%H-%M")
logdir=$HOME/Desktop/auto-dscli-log-$ts.log
testlogdir=$HOME/Desktop/accesses-dscli-log-$ts.log
#-------------------------------------------------------#
# FUNCTIONS (called from menus)
#-------------------------------------------------------#
function list_IP {
	echo
        cat /tmp/iplist
}
function convert_XML {
	echo	
	echo -n "Have you ran the option '1' (y/n)? "
	read yn
        if [ "$yn" == "n" ]
		then
	       	echo "Please, run option '1' to create the report."
	       	sleep 3
	else
	       	echo "Converting report .CSV to XML..."

c1=$(tr '[:lower:]' '[:upper:]' <<< $(awk -F ";" 'NR==1 {s1=$1}END{print s1}' /$HOME/Desktop/report-dasdbox-summary-$ts.csv))
c2=$(tr '[:lower:]' '[:upper:]' <<< $(awk -F ";" 'NR==1 {s2=$2}END{print s2}' /$HOME/Desktop/report-dasdbox-summary-$ts.csv))
c3=$(tr '[:lower:]' '[:upper:]' <<< $(awk -F ";" 'NR==1 {s3=$3}END{print s3}' /$HOME/Desktop/report-dasdbox-summary-$ts.csv))
			
awk -F ";" 'NR>=2 { print "<""DASDBOX"">\n" "<""'$c1'"">" $1 "</""'$c1'"">\n" "<""'$c2'"">" $2 "</""'$c2'"">\n" "<""'$c3'"">" $3 "</""'$c3'"">" "\n</""DASDBOX"">"}' /$HOME/Desktop/report-dasdbox-summary.csv > /$HOME/Desktop/report-dasdbox-summary-$ts.xml

		sleep 3
		echo "Done!"
	fi	
}
function test_accesses {
	echo
	echo "Please, informe the user authentication to the Dasd-Box(es)"
	echo "(the login and pw must be the same for all IP provided)"
	echo
	echo -n "login: "
	read user
	echo -n "Password: "
	read -s pass
	echo
	echo -n "Confirm Password: "
	read -s checkpass
	echo

	if [ $pass == $checkpass ]
	then
           echo
           echo "$(date +'%Y-%m-%d-%H-%M') LOG: Testing accesses"
           echo "$(date) LOG: Testing accesses:" >> $testlogdir
           sleep 2
            # Iteration over the IP LIST
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
            for i in $(cat /tmp/iplist)
            do

                echo "$(date +'%Y-%m-%d-%H-%M') LOG: Accessing $i"
                echo "$(date) LOG: Accessing $i" >> $testlogdir

                #Access
                #get dev param
                devparam=$(/opt/ibm/dscli/dscli -hmc1 $i -user $user -passwd $pass lssi -s -fullid -hdr off | grep -v Date)

                if [ -z "$devparam" ]
	            then
	               echo "$(date +'%Y-%m-%d-%H-%M') LOG: Authentication has failed or unable to connect to the management console server"
	               echo "$(date) LOG: Authentication has failed or unable to connect to the management console server" >> $testlogdir
                else
		       echo "$(date +'%Y-%m-%d-%H-%M') LOG: Access working $i"
	               echo "$(date) LOG: Access working" >> $testlogdir
                fi
            done
	else
		  echo "Password doesn't match!"
        fi 
}
function rank_report {
	echo
	echo "Please, informe the user authentication to the Dasd-Box(es)"
	echo "(the login and pw must be the same for all IP provided)"
	echo
	echo -n "login: "
	read user
	echo -n "Password: "
	read -s pass
	echo
	echo -n "Confirm Password: "
	read -s checkpass
	echo

	if [ $pass == $checkpass ]
	then
            echo
            echo "$(date +'%Y-%m-%d-%H-%M') LOG: Working..."
            echo "$(date) LOG: Working..." >> $logdir
            sleep 2
            # Iteration over the IP LIST
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
            for i in $(cat /tmp/iplist)
            do

                echo "$(date +'%Y-%m-%d-%H-%M') LOG: Accessing $i"
                echo "$(date) LOG: Accessing $i" >> $logdir

                #Access
                #get dev param
                devparam=$(/opt/ibm/dscli/dscli -hmc1 $i -user $user -passwd $pass lssi -s -fullid -hdr off | grep -v Date)

                if [ -z "$devparam" ]
	            then
	               echo "$(date +'%Y-%m-%d-%H-%M') LOG: Authentication has failed or unable to connect to the management console server"
	               echo "$(date) LOG: Authentication has failed or unable to connect to the management console server" >> $logdir
                else
	               atleastone=true
	               echo "$(date +'%Y-%m-%d-%H-%M') LOG: Extracting report..." 
	               echo "$(date) LOG: Extracting report..." >> $logdir
	               #run rank command on dscli
	               /opt/ibm/dscli/dscli -hmc1 $i -user $user -passwd $pass lsrank -dev $devparam -l > /tmp/dscli-unit-rank

	               echo "$(date +'%Y-%m-%d-%H-%M') LOG: Processing data..."
	               echo "$(date) LOG: Processing data..." >> $logdir
	               #append summary file to show a summary for the report
	               echo $devparam $(awk 'NR>=4 {t10+=$10;t11+=$11}END{print t10,t11}' /tmp/dscli-unit-rank) >> /tmp/dscli-summary-temp

	               #awk to sum total capacity and used capacity
	               awk 'NR>=4 {s10+=$10;s11+=$11}END{print "- - - - - - - - - " s10,s11 " - -"}' /tmp/dscli-unit-rank >> /tmp/dscli-unit-rank

	               #append to a file containing all reports
	               cat /tmp/dscli-unit-rank >> /tmp/dscli-all-rank
                fi
            done
#-------------------------------------------------------#
# Managing the data extracted
#-------------------------------------------------------#
            #if [ -n "$devparam" ]
            if [ $atleastone ]
	           then
	           echo "$(date +'%Y-%m-%d-%H-%M') LOG: Converting files to .CSV"
	           echo "$(date) LOG: Converting files to .CSV" >> $logdir
	           #awk to convert file to .csv
	           awk '{ print $1 ";" $2 ";" $3 ";" $4 ";" $5 ";" $6 ";" $7 ";" $8 ";" $9 ";" $10 ";" $11 ";" $12 ";" $13 ";"}' /tmp/dscli-all-rank > /$HOME/Desktop/report-dasdbox-rank-$ts.csv

	           #insert header to summary file
	           sed '1i Device totalexts totalused' /tmp/dscli-summary-temp > /tmp/dscli-summary

	           #convert summary file to .cvs
	           awk '{ print $1 ";" $2 ";" $3 ";"}' /tmp/dscli-summary > /$HOME/Desktop/report-dasdbox-summary-$ts.csv

	           #remove tmp files
	           rm /tmp/dscli-all-rank 
	           rm /tmp/dscli-unit-rank 
	           rm /tmp/dscli-summary-temp
	           rm /tmp/dscli-summary
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
            fi

            devparam=0
            echo "$(date +'%Y-%m-%d-%H-%M') LOG: Done!"
            echo "$(date) LOG: Done!" >> $logdir
            echo
        else
		  echo "Password doesn't match!"
        fi 
        # end of pass check
}
#-------------------------------------------------------#
# CORE SCRIPT
#-------------------------------------------------------#
while [ $menu != 0 ]
do
    	if [ $menu == 1 ]
	then
	    rank_report
    	elif [ $menu == 2 ]
        then
            list_IP	
	elif [ $menu == 3 ]
	then
	    convert_XML
	elif [ $menu == 4 ]
        then
            test_accesses	
	else
	    echo "Invalid Option!"
	    echo
	fi # end fisrt IF checking OP selected
		
    echo
	echo "Select an option"
	echo -n "op: "
	read menu
done
echo
echo "Bye!"
rm /tmp/iplist
sleep 2
clear
exit 	
