#!/bin/bash
shopt -s nocasematch

query="{query}"

HOSTNAME=`hostname -s`

function escape_hostname {
    echo $(echo "$@" | sed 's/[^a-zA-Z0-9 -_]//g;s/[ _]/-/g')
}

function return_item() {
    echo "<item arg=\"$1\" uid=\"$1\" valid=\"yes\"><title>$2</title><subtitle>Connect to $1</subtitle><icon>icon.png</icon></item>"
}

trap '{
    if [ -z "$out" ]; then
        out="<item arg=\"$query\" uid=\"$query\" valid=\"yes\">\
                <title>Connect to...</title>\
                <subtitle>Enter host to connect to</subtitle>\
                <icon>icon.png</icon>\
            </item>"
    fi
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><items>$out</items>"
}' EXIT

out=""; i=0
while read -r line; do
    name="${line:6}"
    domain="${line:6}"
    hostname="${line:6}"

    if [[ -z "$query" || $name =~ "$query" ]]; then
        out+="$(return_item "${hostname}" "${name}")"
    fi

done < <(/usr/bin/python -c 'import Foundation
import getpass
data=Foundation.NSKeyedUnarchiver.unarchiveObjectWithFile_("/Users/{user}/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteServers.sfl2".format(user=getpass.getuser()))
if data is not None:
  data_items = data.get("items", [])
  for item in data_items:
    if item["Name"].startswith("vnc://"):
      print item["Name"]')


while read -r line; do
    i=`expr $i + 1`
    if [ $i -lt 5 ]; then continue; fi # skip the header lines

    name=$(echo "$line" | tr -s ' ' | sed 's/^.*_rfb\._tcp\. //g')
    domain=$(echo $line | tr -s ' ' | cut -d ' ' -f 5)
    domain="${domain%?}"
    hostname="$(escape_hostname $name).$domain"

    if [[ "$name" != "$HOSTNAME" && ( -z "$query" || $name =~ "$query" ) ]]; then
        out+="$(return_item "${hostname}" "${name}")"
    fi

    if (( $(echo $line | cut -d ' ' -f 3) < 2 )); then break; fi # break if no more items will follow

done < <((sleep 1; kill -13 0) & # kill quickly if trapped
            dns-sd -B _rfb._tcp)

# silently kill subprocess
kill -13 0
exit 0