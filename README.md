# block-ads-via-dns
Block ads and malware via local DNS server

Debian
- Install DNS Server: `sudo apt install bind9`
- Add this to /etc/bind/named.conf: `include "/etc/bind/named.conf.blocked";`
- Create db.blocked and add this:
````
$TTL    86400   ; one day
@       IN      SOA      (
        2017021701       ; serial number YYMMDDNN
        28800   ; refresh  8 hours
        7200    ; retry    2 hours
        864000  ; expire  10 days
        86400 ) ; min ttl  1 day
* IN      A       0.0.0.0
````

- Download generate-zonefile.sh
- Adjust blacklist and whitelist path
- Uncomment one URL to StevenBlack GitHub Hosts
- Make it executable `chmod +x generate-zonefile.sh`
- Run generate-zonefile.sh `./generate-zonefile.sh`
