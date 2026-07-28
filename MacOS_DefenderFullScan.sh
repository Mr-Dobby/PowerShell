#!/bin/bash
#set -x

###############################################################################################################
##
## Script to install LaunchDaemon to schedule a Defender for Endpoint (MDE) Antivirus FULL SCAN job
##
## Note1: Edit StartCalendarInterval key to change time/date 
## Note2: RunAtLoad and KeepAlive keys are not configured to avoid additional Full scans running at device reboot
##
## P.S This is a modified version of the example QuickScan job script shared by the Neil Johnson on GitHub:
## https://github.com/microsoft/shell-intune-samples/blob/master/macOS/Config/MDATP/installMDATPQuickScanJob.sh
##
###############################################################################################################

# Define variables
log="/var/log/schedfullscan.log"
plistname="com.microsoft.wdav.schedfullscan"
plistfile="/Library/LaunchDaemons/com.microsoft.wdav.schedfullscan.plist"
exec 1>> $log 2>&1

if test -f "$plistfile"; then
    echo "$(date) - Found existing $plistfile"
    echo "$(date) - Unloading $plistname"
    launchctl unload $plistfile
    echo "$(date) - Removing $plistfile"
    rm -rf $plistfile
fi

echo "$(date) - Installing new $plistfile"
cat > $plistfile <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.microsoft.wdav.schedfullscan</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>-c</string>
        <string>/usr/local/bin/mdatp scan full</string>
    </array>
    <key>RootDirectory</key>
    <string>/usr/local/bin</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>5</integer>
        <key>Hour</key>
        <integer>11</integer>
        <key>Minute</key>
        <integer>30</integer>
    </dict>
    <key>WorkingDirectory</key>
    <string>/usr/local/bin</string>
</dict>
</plist>
EOF

echo "$(date) - Loading $plistfile"
launchctl load $plistfile

echo "$(date) - Starting $plistname"
launchctl start $plistname

exit 0