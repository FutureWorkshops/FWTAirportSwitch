#!/bin/bash
configfile='/Library/Preferences/com.futureworkshops.airportswitch.plist'
user_configfile='~/Library/Preferences/com.futureworkshops.airportswitch.plist'

die () {
    echo >&2 "$@"
    exit 1
}

if [ ! -r ${user_configfile} ]; then
	[ -r ${configfile} ] || die "No conf files found at path: \"${user_configfile}\" or \"${configfile}\""


	echo "User config file not found. Using default at: \"${configfile}\""
	user_configfile=${configfile};
fi

onoff_script=$(/usr/libexec/PlistBuddy -c "Print :FWOnOffScriptPath" "${user_configfile}")
wifi_interface=$(/usr/libexec/PlistBuddy -c "Print :FWWifiInterfaceName" "${user_configfile}") || die "Unable to read the Wi-fi interface name from the conf file"
eth_interfaces_strings=`/usr/libexec/PlistBuddy -c "Print :FWEthInterfaceNames" "${user_configfile}"` || die "Unable to read the eth interface name from the conf file"
eth_interfaces_strings=`echo "${eth_interfaces_strings}" | sed '1d;$d;s/ //g'`

eth_interfaces=()
for line in ${eth_interfaces_strings}
do
    eth_interfaces+=($line)
done

use_growl="NO"
if [ `/usr/libexec/PlistBuddy -c "Print :FWOnOffScriptPath" "${user_configfile}"`="YES" ]; then
    use_growl="YES"
fi

##
# Airport script:
# http://www.georges.nu/blog/2011/06/how-to-automatically-turn-off-airport-when-ethernet-is-plugged-in/

function set_airport {

    new_status=$1

    if [ $new_status = "On" ]; then
    /usr/sbin/networksetup -setairportpower ${wifi_interface} on
    touch /var/tmp/prev_air_on
    else
    /usr/sbin/networksetup -setairportpower ${wifi_interface} off
    if [ -f "/var/tmp/prev_air_on" ]; then
        rm /var/tmp/prev_air_on
    fi
    fi

}

function growl {

    # Checks whether Growl is installed
    if [ -f "/usr/local/bin/growlnotify" ]; then
    /usr/local/bin/growlnotify -m "$1" -a "AirPort Utility.app"
    fi

}

# Set default values
prev_eth_status="Off"
prev_air_status="Off"

eth_status="Off"

# Determine previous ethernet status
# If file prev_eth_on exists, ethernet was active last time we checked
if [ -f "/var/tmp/prev_eth_on" ]; then
    prev_eth_status="On"
fi

# Determine same for AirPort status
# File is prev_air_on
if [ -f "/var/tmp/prev_air_on" ]; then
    prev_air_status="On"
fi

# Check actual current ethernet status
for eth_interface in "${eth_interfaces[@]}"
do
echo "checking ${eth_interface}"
    if [ "`ifconfig ${eth_interface} | grep \"inet\"`" != "" ]; then
        eth_status="On"
    fi
done

# And actual current AirPort status
air_status=`/usr/sbin/networksetup -getairportpower ${wifi_interface} | awk '{ print $4 }'`

# If any change has occured. Run external script (if it exists)
if [ "$prev_air_status" != "$air_status" ] || [ "$prev_eth_status" != "$eth_status" ]; then
    if [ -f "${onoff_script}" ]; then
    "${onoff_script}" "$eth_status" "$air_status" &
    fi
fi

# Determine whether ethernet status changed
if [ "$prev_eth_status" != "$eth_status" ]; then

    if [ "$eth_status" = "On" ]; then
    set_airport "Off"
    [ $use_growl="NO" ] || growl "Wired network detected. Turning AirPort off."
    else
    set_airport "On"
    [ $use_growl="NO" ] || growl "No wired network detected. Turning AirPort on."
    fi

# If ethernet did not change
else

    # Check whether AirPort status changed
    # If so it was done manually by user
    if [ "$prev_air_status" != "$air_status" ]; then
    set_airport $air_status

    if [ "$air_status" = "On" ]; then
        [ $use_growl="NO" ] || growl "AirPort manually turned on."
    else
        [ $use_growl="NO" ] || growl "AirPort manually turned off."
    fi

fi

fi

# Update ethernet status
if [ "$eth_status" == "On" ]; then
    touch /var/tmp/prev_eth_on
else
    if [ -f "/var/tmp/prev_eth_on" ]; then
    rm /var/tmp/prev_eth_on
    fi
fi

exit 0
