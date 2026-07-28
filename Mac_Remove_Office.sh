#! /bin/bash
chmod u+x Mac_Remove_Office.sh
office_apps=("Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Outlook" "Microsoft OneNote" "Microsoft Teams")

for app in "${office_apps[@]}"
do
  echo "Uninstalling $app..."
  sudo /usr/sbin/installer -pkg "/Library/Application Support/Microsoft/MAU2.0/$app.pkg" -target /
  echo "Uninstalled $app."
done

rm -fr ~/Libary/Containers/com.microsoft.*/