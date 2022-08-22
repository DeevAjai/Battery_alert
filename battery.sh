#!/usr/bin/env bash

export_dbus(){
	dbus=`grep -zsh DBUS_SESSION_BUS_ADDRESS= /proc/*/environ | grep -zs guid | sed 's/DBUS_SESSION_BUS_ADDRESS=/\n/g' | tail -1 | tr -d '\0'`
	#echo $dbus
	export DBUS_SESSION_BUS_ADDRESS=$dbus
}

export_dbus

#code
battery_level=`cat /sys/class/power_supply/BAT1/capacity`
status=`cat /sys/class/power_supply/BAT1/status`

login_setup(){
	#Check for current days log file already exists
	last_logfile=$(ls ~/Battery_alert/log/ | tail -1)
	current_logfile="battery_`date '+%Y%m%d'`.log"
	if [ $last_logfile != $current_logfile ]; then
		echo -e "\n<Log Created>" >> ~/Battery_alert/log/$current_logfile
	fi

	#Checks if the symbolic link is mappend to current log file, if not maps current file
	if [ $(md5sum ~/Battery_alert/log/$current_logfile | cut -d ' ' -f 1) != $(md5sum ~/Battery_alert/battery.log | cut -d ' ' -f 1) ];then
		ln -sf ~/Battery_alert/log/$current_logfile ~/Battery_alert/battery.log
	fi
	
	#Appends the login time to the log file
	echo -e "\n<Login> @ `date`" >> ~/Battery_alert/battery.log

}

#This checks the no. of arguments passed to the program
#No. of arguments must be 0 or 1
#0 - the program check the battery percentage and give alert
#1 - the only parameter is login - this check for the log file for current date if present appeds login time to the file, if not present it creates the file and appends login time to the file

if [ $# == 1 ];then
	if [ $1 == "login" ];then
		login_setup
	fi
elif [ $# -gt 1 ];then
	echo "Invalid number of arguments"
fi 

if [ $battery_level -ge 90 ]; then
	if [ "$status" = "Charging" ]; then
		/usr/bin/notify-send "Battery is high! Charging : ${battery_level}%" "Remove your Adapter"
		echo -e "\n<Notify>" >> ~/Battery_alert/battery.log
	fi
elif [ $battery_level -le 70 ]; then
	if [ "$status" = "Discharging" ]; then
		/usr/bin/notify-send "Battery is low! Not Charging : ${battery_level}%" "Please pluggin your Adapter"
	    	echo -e "\n<Notify>" >> ~/Battery_alert/battery.log
	fi
fi

echo -e "\n"`date`"\nBattery-level:"$battery_level"%\nStatus:"$status"\n------------------------------------------" >> ~/Battery_alert/battery.log

if [ $(echo $dbus | wc -l) -lt 1 ];then
	gnome-terminal -- bash -c "tail -5f ~/Battery_alert/battery.log"
fi
