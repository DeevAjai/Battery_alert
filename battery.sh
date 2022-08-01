#!/usr/bin/env bash

#echo `pwd`
username=$(/usr/bin/whoami)

#echo $username
pid=$(pgrep -u $username nautilus)

if [ $pid ];then
	#echo $pid
	dbus=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$pid/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//')
	#echo $dbus
	export DBUS_SESSION_BUS_ADDRESS=$dbus
fi

#code
battery_level=`cat /sys/class/power_supply/BAT1/capacity`
status=`cat /sys/class/power_supply/BAT1/status`

if [ $# == 1 ];then
	if [ $1 == "login" ];then
		if [ "$(ls ~/Software/Battery_alert/log/ | tail -1)" != "battery_`date '+%Y%m%d'`.log" ]; then
			ln -sf ~/Battery_alert/log/battery_`date '+%Y%m%d'`.log ~/Battery_alert/battery.log
			echo -e "\n<Log Created>" >> ~/Battery_alert/battery.log
		fi
		echo -e "\n<Login> @ `date`" >> ~/Battery_alert/battery.log
	fi
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

if [ ! $pid ];then
	gnome-terminal -- bash -c "tail -5f ~/Software/Battery_alert/battery.log"
fi
