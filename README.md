# Introduction
This script will listens for changes in the network conditions of your mac and activate the wireless interfaces when it loses connection to a wired interface and viceversa. This way the mac will never be connected to the same network more than once and it will always use the faster connection.

The installer installs a configurable script in "/Library/Scripts/FutureWorkshops" that is activated everytime the network conditions change.

# Configuration
The script looks in two directories for a configuration files in this order:
1. ~/Library/Preferences/com.futureworkshops.airportswitch.plist
2. /Library/Preferences/com.futureworkshops.airportswitch.plist
so that any user can overwrite the default system settings

The file is a standard .plist file in which you can configure the following options:

Option			| Description
------------------------|-----------------------------------------------------------------------------------------------------------
FWEthInterfaceNames 	| an array containing the name of the wired interfaces to monitor for changes 			
FWWifiInterfaceName 	| the name of the wireless interface to activate/deactivated when the ethernet cable is plugged/unplugged
FWOnOffScriptPath 	| path to a script that executes everytime the wireless interface is enabled/disabled 		
FWUseGrowl 		| flag that activate growls notifications everytime the wireless interface is enabled/disabled 
