#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# display date
date

# Set tempfiles
# All_domains will contain all domains from all lists, but also duplicates and ones which are whitelisted
all_domains=$(mktemp)
# Like above, but no duplicates or whitelisted URLs
all_domains_uniq=$(mktemp)
# We don't write directly to the zonefile. Instead to this temp file and copy it to the right directory afterwards
zonefile=$(mktemp)

# Define local black and white lists
# Uncomment if you have no local files
manuell_blacklist="/root/blacklist"
manuell_whitelist="/root/whitelist"

# StevenBlack GitHub Hosts
# Uncomment ONE line containing the filter you want to apply
# See https://github.com/StevenBlack/hosts for more combinations
wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social/hosts
#wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts

# Filter out localhost and broadcast
grep '^0.0.0.0' StevenBlack-hosts | egrep -v '127.0.0.1|255.255.255.255|::1' | cut -d " " -f 2 >> "$all_domains"

# Add local blacklist
[ -f $manuell_blacklist ] && {
    cat $manuell_blacklist >> $all_domains
}

# Filter out comments and empty lines
egrep -v '^$|#' "$all_domains" | sort | uniq  > "$all_domains_uniq"

# Apply local whitelist
[ -f "$manuell_whitelist" ] && {
    for i in $(cat $manuell_whitelist)
    do
        #echo i $i
        sed --in-place= "/$i/d" "$all_domains_uniq"
    done
}

# Add zone information
sed -r 's/(.*)/zone "\1" {type master; file "\/var\/named\/blocked.zone";};/' "$all_domains_uniq" > "$zonefile"

# Copy temp file to right directory
# This is for Debian 8, might differ on other systems
cp "$zonefile" /etc/named.conf.blocked

# Remove all tempfiles
rm $all_domains $all_domains_uniq $zonefile StevenBlack-hosts

# Restart bind
systemctl restart named

# For logfile
echo -e 'done\n\n'
