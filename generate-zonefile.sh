#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# display date
date

blocked_file=/etc/named.conf.blocked
zone_file=/var/named/blocked.zone

# Set tempfiles
# All_domains will contain all domains from all lists, but also duplicates and ones which are whitelisted
all_domains=$(mktemp)

# Like above, but no duplicates or whitelisted URLs
all_domains_uniq=$(mktemp)

# Define local black and white lists
blacklist="/root/blacklist"
whitelist="/root/whitelist"

# StevenBlack GitHub Hosts
# See https://github.com/StevenBlack/hosts for more combinations
wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

# Filter out comments, localhost and broadcast
sed "s/#.*//" StevenBlack-hosts | grep -vE "127.0.0.1 |255.255.255.255|::" | cut -d" " -f2 >> "$all_domains"

# Add local blacklist
[ -f "$blacklist" ] && {
  sed "s/#.*//" $blacklist >> $all_domains
}

# Filter empty lines
grep -vxE "[[:space:]]*|^$" "$all_domains" |sort|uniq > "$all_domains_uniq"

# Apply local whitelist
[ -f "$whitelist" ] && {
  for i in $(<$whitelist)
  do 
    sed --in-place= "/$i/d" "$all_domains_uniq"
  done
}

# Add zone information
# Works on arch
sed "s|.*|zone \"&\" {type master; file \"$zone_file\";};|" "$all_domains_uniq" > "$blocked_file"

# Remove all tempfiles
rm $all_domains $all_domains_uniq StevenBlack-hosts

# Restart bind
systemctl restart named

# For logfile
echo -e 'done\n\n'

