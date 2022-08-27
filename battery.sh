#!/usr/bin/env bash

cd ~

export_dbus(){
	dbus=`grep -zsh DBUS_SESSION_BUS_ADDRESS= /proc/*/environ | grep -zs guid | sed 's/DBUS_SESSION_BUS_ADDRESS=/\n/g' | tail -1 | tr -d '\0'`
	#echo $dbus
	export DBUS_SESSION_BUS_ADDRESS=$dbus
}

export_dbus

check_dir(){
	path=$1
	echo "Checking for $path";
	if [ ! -d $path ];then
		echo "$path not found";
		echo "Creating $path";
		mkdir -p $path
	else
		echo "$path found";
	fi
}

write_config(){
	dmin=25;dmax=95;dprog_path="Battery_alert/";dlog_path="${dprog_path}log/";dlog_file="${dlog_path}battery.log";
	if [ $# = 1 -a $1 = "default" ];then
		check_dir $dprog_path
		echo -e "MIN_LEVEL=$dmin\nMAX_LEVEL=$dmax\nLOG_FILE=$dlog_file\nLOG_PATH=$dlog_path\nPROG_PATH=$dprog_path" > $config_file
	else
		echo "Type min/max battery level to set notifier"
		echo -n "MIN_LEVEL(minimum battery level to notify):"
		read min_level
		if [ -Z $min_level ];then
			min_level=$dmin
		fi
		echo -n "MAX_LEVEL(maxmum battery level to notify):"
		read max_level
		if [ -Z $max_level ];then
			max_level=$dmax
		fi
		echo -n "PROG_PATH(specify the full path which you want to use as base path for this program , specify slash / at the end):"
		read prog_path
		if [ -Z $dprog_path ];then
			prog_path=$dprog_path
		fi
		log_path="${prog_path}log/"
		log_file="${log_path}battery.log"
		check_dir $prog_path
		echo -e "MIN_LEVEL=$min_level\nMAX_LEVEL=$max_level\nLOG_FILE=$log_file\nLOG_PATH=$log_path\nPROG_PATH=$prog_path" > $config_file
	fi
}

read_configs(){
	config_file="Battery_alert/bconfig.conf"
	if [ ! -f $config_file ];then
		write_config "default"
	fi
	min_level=`grep MIN_LEVEL= $config_file | cut -d = -f 2`
	max_level=`grep MAX_LEVEL= $config_file | cut -d = -f 2`
	log_file=`grep LOG_FILE= $config_file | cut -d = -f 2`
	log_path=`grep LOG_PATH= $config_file | cut -d = -f 2`
	prog_path=`grep PROG_PATH= $config_file | cut -d = -f 2`
	
	battery_level=`cat /sys/class/power_supply/BAT1/capacity`
	status=`cat /sys/class/power_supply/BAT1/status`
}

log_setup(){
	
	#Check for current days log file already exists
	last_logfile=$(ls $log_path | tail -1)
	current_logfile="battery_`date '+%Y%m%d'`.log"
	if [ $last_logfile != $current_logfile ]; then
		echo -e "\n<Log Created>" >> $log_path$current_logfile
	fi

	if [ ! -h $log_file ];then
		echo "Creating soft link for logfile"
		ln -sf $current_logfile $log_file
	fi

	#Checks if the symbolic link is mappend to current log file, if not maps current file
	if [ $(md5sum $log_path$current_logfile | cut -d ' ' -f 1) != $(md5sum $log_file | cut -d ' ' -f 1) ];then
		ln -sf $current_logfile $log_file
	fi

}

login_setup(){
	
	#calling log_setup to check for log validity
	log_setup

	#Appends the login time to the log file
	echo -e "\n<Login> @ `date`" >> $log_file

}

check_battery(){
	#checks battery leve and provides custom notification accordingly
	if [ $battery_level -ge $max_level ]; then
		if [ "$status" = "Charging" ]; then
			/usr/bin/notify-send "Battery is high! Charging : ${battery_level}%" "Remove your Adapter"
			echo -e "\n<Notify>\nMessage :- \nBattery is high! Charging : ${battery_level}%\nRemove your Adapter\n</Notify>" >> $log_file
		fi
	elif [ $battery_level -le $min_level ]; then
		if [ "$status" = "Discharging" ]; then
			/usr/bin/notify-send "Battery is low! Not Charging : ${battery_level}%" "Please pluggin your Adapter"
				echo -e "\n<Notify>\nMessage :- \nBattery is low! Not Charging : ${battery_level}%\nPlease pluggin your Adapter\n</Notify>" >> $log_file
		fi
	fi
	echo -e "\n"`date`"\nBattery-level:"$battery_level"%\nStatus:"$status"\n------------------------------------------" >> $log_file
}

#This checks the no. of arguments passed to the program
#No. of arguments must be 0 or 1
#0 - the program check the battery percentage and give alert
#1 - the only parameter is login - this check for the log file for current date if present appeds login time to the file, if not present it creates the file and appends login time to the file

read_configs
log_setup

if [ $# = 1 ];then
	if [ $1 == "login" ];then
		login_setup
		check_battery
	fi
elif [ $# -gt 1 ];then
	echo "Invalid number of arguments"
elif [ $# = 0 ];then
	check_battery
fi

#addition terminal pops up when the guid is not present

if [ $(echo $dbus | wc -l) -lt 1 ];then
	gnome-terminal -- bash -c "tail -f $log_file"
fi
