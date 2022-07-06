#!/bin/bash

if [[ $1 == '' ]]; then
    DIR='..'
else
    DIR=$1
fi
source /home/pi/nomad.conf

X="[NOMAD]"

echo -e "$X SCREEN"
cat << END > $DIR/.screenrc 
shell -${SHELL}
caption always "[ %H ] %w"
defscrollback 1024
startup_message off
hardstatus on
hardstatus alwayslastline
screen -t EMACS 0 emacs -nw --visit ~/index.org
screen -t NOMAD 1 ./nomad.sh
screen -t BASH 2 bash
screen -t COMMS 3 ./nomad.sh operator
screen -t BT 8 bluetoothctl
screen -t MON 9 redis-cli monitor
select 3
END

echo -e "$X INDEX"
cat << END > $DIR/index.org
#+TITLE: Nomadic Linux.
#+TODO: TODO(t!/@) ACTION(a!/@) WORKING(w!/@) | ACTIVE(f!/@) DELEGATED(D!/@) DONE(X!/@)
#+OPTIONS: stat:t html-postamble:nil H:1 num:nil toc:t \n:nil ::nil |:t ^:t f:t tex:t

* Welcome!
  Nomadic linux is built to cope with disasters.  It has a simple set of tools designed to get you up and running quickly and consistantly.  Keep a Spare usb stick in your pocket - you never know when it will come in handy.

* Tools
  - git: The version control system of the future.
  - emacs: The gnu text editor.
  - vim: It's always there.
  - ruby: A dynamic, object oriented, interpreted language.
  - python: A compiled high level language.
  - inotify: Kernel file event notification tools.
  - screen: The gnu terminal multiplexer.
  - redis: A next generation NOsql database.
  - tor: The tor network client tools.
  - nmap: A network analysis tool.
  - tshark: A packet analysis tool.
  - wifite: A simple wireless network decrypter.
  - netcat: The linux network swiss army knife.
  - ii: A tiny filesystem based irc client suitable for scripting.

* Leah
  The Leah tool allows single administrator access to common tools used to administer standalone systems (desktops and laptops) and networks.  It can be thought of as a "smart sudo" or an easy way to not grant privledges unnecessarily on a system.
  - lan: scans the local area network, and performs an OS fingerprint on the attached devices.
  - wifi: connects the local wireless card to an ssid and key, or an existing ssid/key pair.
  - svc: adds a port to be hosted as a hidden service.
  - mnt: mounts a local device.

* Org Mode for fun and profit
  Nomadic linux believes in staying organized.  Org mode keeps notes well organized. Nomadic linux also integrates lots of other tools to automate the process of exporting these files.

END

echo -e "$X PROMPT"
cat << 'END' > $DIR/.prompt
#  Customize BASH PS1 prompt to show current GIT repository and branch.
#  by Mike Stewart - http://MediaDoneRight.com
#  SETUP CONSTANTS
#  Bunch-o-predefined colors.  Makes reading code easier than escape sequences.
#  I don't remember where I found this.  o_O
# Reset
Color_Off="\[\033[0m\]"       # Text Reset

# Regular Colors
Black="\[\033[0;30m\]"        # Black
Red="\[\033[0;31m\]"          # Red
Green="\[\033[0;32m\]"        # Green
Yellow="\[\033[0;33m\]"       # Yellow
Blue="\[\033[0;34m\]"         # Blue
Purple="\[\033[0;35m\]"       # Purple
Cyan="\[\033[0;36m\]"         # Cyan
White="\[\033[0;37m\]"        # White

# Bold
BBlack="\[\033[1;30m\]"       # Black
BRed="\[\033[1;31m\]"         # Red
BGreen="\[\033[1;32m\]"       # Green
BYellow="\[\033[1;33m\]"      # Yellow
BBlue="\[\033[1;34m\]"        # Blue
BPurple="\[\033[1;35m\]"      # Purple
BCyan="\[\033[1;36m\]"        # Cyan
BWhite="\[\033[1;37m\]"       # White

# Underline
UBlack="\[\033[4;30m\]"       # Black
URed="\[\033[4;31m\]"         # Red
UGreen="\[\033[4;32m\]"       # Green
UYellow="\[\033[4;33m\]"      # Yellow
UBlue="\[\033[4;34m\]"        # Blue
UPurple="\[\033[4;35m\]"      # Purple
UCyan="\[\033[4;36m\]"        # Cyan
UWhite="\[\033[4;37m\]"       # White

# Background
On_Black="\[\033[40m\]"       # Black
On_Red="\[\033[41m\]"         # Red
On_Green="\[\033[42m\]"       # Green
On_Yellow="\[\033[43m\]"      # Yellow
On_Blue="\[\033[44m\]"        # Blue
On_Purple="\[\033[45m\]"      # Purple
On_Cyan="\[\033[46m\]"        # Cyan
On_White="\[\033[47m\]"       # White

# High Intensty
IBlack="\[\033[0;90m\]"       # Black
IRed="\[\033[0;91m\]"         # Red
IGreen="\[\033[0;92m\]"       # Green
IYellow="\[\033[0;93m\]"      # Yellow
IBlue="\[\033[0;94m\]"        # Blue
IPurple="\[\033[0;95m\]"      # Purple
ICyan="\[\033[0;96m\]"        # Cyan
IWhite="\[\033[0;97m\]"       # White

# Bold High Intensty
BIBlack="\[\033[1;90m\]"      # Black
BIRed="\[\033[1;91m\]"        # Red
BIGreen="\[\033[1;92m\]"      # Green
BIYellow="\[\033[1;93m\]"     # Yellow
BIBlue="\[\033[1;94m\]"       # Blue
BIPurple="\[\033[1;95m\]"     # Purple
BICyan="\[\033[1;96m\]"       # Cyan
BIWhite="\[\033[1;97m\]"      # White

# High Intensty backgrounds
On_IBlack="\[\033[0;100m\]"   # Black
On_IRed="\[\033[0;101m\]"     # Red
On_IGreen="\[\033[0;102m\]"   # Green
On_IYellow="\[\033[0;103m\]"  # Yellow
On_IBlue="\[\033[0;104m\]"    # Blue
On_IPurple="\[\033[10;95m\]"  # Purple
On_ICyan="\[\033[0;106m\]"    # Cyan
On_IWhite="\[\033[0;107m\]"   # White

# Various variables you might want for your PS1 prompt instead
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"


# This PS1 snippet was adopted from code for MAC/BSD I saw from: http://allancraig.net/index.php?option=com_content&view=article&id=108:ps1-export-command-for-git&catid=45:general&Itemid=96
# I tweaked it to work on UBUNTU 11.04 & 11.10 plus made it mo' better

export PS1=$Green$Time12h$Color_Off'$(git branch &>/dev/null;\
if [ $? -eq 0 ]; then \
  echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
  if [ "$?" -eq "0" ]; then \
    # @4 - Clean repository - nothing to commit
    echo "'$Green'"$(__git_ps1 " (%s)"); \
  else \
    # @5 - Changes to working tree
    echo "'$IRed'"$(__git_ps1 " {%s}"); \
  fi) '$BYellow$PathShort$Color_Off'\$ "; \
else \
  # @2 - Prompt when not in GIT repo
  echo " '$Yellow$PathShort$Color_Off'\$ "; \
fi)'

END



echo -e "$X NOMAD"
cat << 'END' > $DIR/.nomad
##### NOMADIC begin #####
echo "`cat /etc/logo`"
echo "[`hostname`] `uname -a`"
source ~/.prompt
alias commit="rm -f nomadic/bin/*~ && rm -f *~ && git add . && git commit && git push"
echo "commit -> push changes to the origin repo."
function token() { git remote set-url origin https://$1:$2@github.com/$1/`pwd`.git; }
echo "token <user> <token> -> set push token for repo."
alias op="cd ~/nomad && screen"
echo "op -> enter operator mode."
function leah() { su -c "source /root/leah.sh && \$*"; }
##### NOMADIC end #####
END


echo -e "$X PROFILE"
cat << END >> /home/$USERNAME/.profile
##### NOMADIC begin #####
#nomad `date`
##### NOMADIC end #####
END

echo -e "$X LEAH"
cat << 'END' > /usr/bin/leah
#!/bin/bash
AUTOSTART=~/.autostart.sh
ANON="false"
PS1="#> "
function lan() {
    IP_REGEXP="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    IPs=`sudo arp-scan --localnet | grep -E -o $IP_REGEXP`
    nmap -O -F -v $IPs
}
function wifi() {
    WPA=/etc/wpa_supplicant/$1.conf
    if [[ $ANON == "true" ]]; then
	echo "Randomizing MAC address..."
	macchanger -r wlan0
    fi
    if [[ $1 != ''  ]]; then
	if [[ $2 != '' ]]; then
	    echo "Generating $1 configuration..."
	    if [[ $3 != '' ]]; then
		echo "Generating Network configuration..."
		wpa_passphrase $2 $3 > $WPA
	    else
		echo -e "network={\nssid="$2"\nkey_mgmt=NONE\n}\n" > $WPA
	    fi
	else
	    echo "Using existing configuration for $1:"
	fi
	cat $WPA
	### 3
	echo "Starting Wireless Driver..."
	wpa_supplicant -Dwext -iwlan0 -c$WPA &
	echo "Starting DHCP Client..."
	dhclient -v -4 wlan0
    fi    
}

function kill_wifi() {
    pkill NetworkManager
    pkill wpa_supplicant
    pkill dhclient
    ifconfig
}

function svc() {
  pkill tor
cat <<EXX >> /etc/tor/torrc
HiddenServiceDir /var/lib/tor/$1/
HiddenServicePort $1 127.0.0.1:$1
EXX
  tor &
  cat /var/lib/tor/$1/hostname
}

function mnt() {
    mkdir -p /mnt/sd
    mount /dev/sdb2 /mnt/$1
    echo "DEVICE: /dev/$1 MOUNTED: /mnt/$1"
    ls -lha /mnt/$1
}

echo -e "############################\n# Dont do anything stupid. #\n############################"
END
chmod +x /usr/bin/leah

CAMS="";
SSL="";
for c in `redis-cli hkeys CAMS`
do
    CAMS+="location /$c { proxy_pass http://`redis-cli hget CAMS $c`; }\n"
done
sss="server {
    listen 80 default_server;
    server_name _;
    return 301 https://$uri;
}
server {
  listen 443 ssl;
  listen [::]:443;
  server_name $DOMAINS;
  location / {
    proxy_pass http://localhost:4567;                                                                        
    proxy_set_header Host \$host;
    proxy_redirect http://localhost:4567 https://\$uri;
  }
  ssl_certificate /etc/letsencrypt/live/$DOMAIN_ROOT/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_ROOT/privkey.pem;
  # Use the file generated by certbot command.
  include /etc/letsencrypt/options-ssl-nginx.conf;
  # Define the path of the dhparam.pem file.
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}";
ssn="server {
listen 80;                                                                                                   
listen [::]:80;                                                                                              
listen unix:/var/run/nginx.sock;                                                                             
server_name localhost `hostname`.local `sudo cat /var/lib/tor/nomad/hostname`;

### devices                                                                                                  
`echo -e $CAMS`                                                                                              
###
location / { 
          proxy_pass_header  Set-Cookie;                                                                     
          proxy_set_header   Host               \$host;                                                      
          proxy_set_header   X-Real-IP          \$remote_addr;                                               
          proxy_set_header   X-Forwarded-Proto  \$scheme;                                                    
          proxy_set_header   X-Forwarded-For    \$proxy_add_x_forwarded_for;                                 
          proxy_pass http://127.0.0.1:4567/;
	  proxy_redirect http://localhost:4567 https://\$uri;    
          proxy_buffering off;                                                                               
    }                                                                                                        
} 
";
if [[ "$BOX" == "true" ]]; then
    SSL=$ssn;
else
    SSL=$sss;
fi

cat << END > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
        worker_connections 768;
        multi_accept on;                                                                                    
}

http {
        server_names_hash_bucket_size 128;
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE                                    
        ssl_prefer_server_ciphers on;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
        gzip on;
	client_max_body_size 8M;

$SSL

#
# configure domains with certbot
#

include /etc/nginx/sites-enabled/*;

}
END
rm -f /etc/nginx/sites-enabled/*
service nginx restart

cat << END > /etc/tor/torrc
#nomad
HiddenServiceDir /var/lib/tor/nomad/
HiddenServicePort 80 unix:/var/run/nginx.sock
HiddenServicePort 6667 127.0.0.1:6667
HiddenServicePort 4321 127.0.0.1:4321
HiddenServicePort 64738 127.0.0.1:64738
END
sudo service tor restart

##
# TRAMP STAMP

# configure ap
#cat <<EOF > /etc/hostapd/hostapd.conf
#//driver=nl80211
#//ctrl_interface=/var/run/hostapd
#//ctrl_interface_group=0
#//beacon_int=100
#auth_algs=1
#wpa_key_mgmt=WPA-PSK
#ssid=nomad
#channel=1
#hw_mode=g
#wpa_passphrase=nomadnetwork
#interface=wlan0
#wpa=2
#wpa_pairwise=CCMP
#country_code=
## Rapberry Pi 3 specific to on board WLAN/WiFi
#ieee80211n=1 # 802.11n support (Raspberry Pi 3)
#wmm_enabled=1 # QoS support (Raspberry Pi 3)
#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40] # (Raspberry Pi 3)
## RaspAP wireless client AP mode
#interface=uap0
## RaspAP bridge AP mode (disabled by default)
#bridge=br0
#EOF

# resolve domains across interfaces
#cat <<EOF > /etc/dhcpcd.conf
# RaspAP default configuration
#hostname
#clientid
#persistent
#option rapid_commit
#option domain_name_servers, domain_name, domain_search, host_name
#option classless_static_routes
#option ntp_servers
#require dhcp_server_identifier
#slaac private
#nohook lookup-hostname

# RaspAP wlan0 configuration
#interface wlan0
#static ip_address=10.3.141.1/24
#static routers=10.3.141.1
#static domain_name_server=9.9.9.9 1.1.1.1

#interface uap0
#static ip_address=192.168.50.1/24
#nohook wpa_supplicant
#EOF

# create ap network
#cat <<EOF > /etc/dnsmasq.d/090_ap.conf
# RaspAP wlan0 configuration for wired (ethernet) AP mode
#interface=wlan0
#domain-needed
#dhcp-range=10.3.141.50,10.3.141.255,255.255.255.0,12h

# RaspAP default config
#log-facility=/tmp/dnsmasq.log
#conf-dir=/etc/dnsmasq.d

#interface=lo,uap0
#bind-interfaces
#domain-needed
#bogus-priv
#EOF
# bridge traffic
#echo -e "net.ipv4.ip_forward=1" > /etc/sysctl.d/90_nomad.conf;
#echo -e "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl/90_nomad.conf;

#cat <<EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# bridge wifi and ap
#iw dev wlan0 interface add uap0 type __ap
#ifconfig wlan0 up
#ifconfig uap0 up
#exit 0
#EOF

echo -e "$X LOGO"

cat << END > /etc/icon
######  ####################
#####    ###################
#####    ########  +########
######  #@  ####    ########
#######   ; +###    ########
######+   .  ####  ;@  #####
######     + +####      ####
######        ####      ####
######      #####;    # ;###
####:  +     ####       ####
###   ##     ###  +    #####
##  ####,    #.  ##:   ;####
###; ###    ##  ###+   #####
#### ##;    ### +##    #####
##### #      ### ##    #####
#####    :   ###.;.     ####
######   ##  ####   #   ####
######   ##,  ###: .##  ####
######  ####  ###.  ##, ;###
######   ###, +##   ###  ###
#####: . :###  ##   ###: ###
######  # ###: ## .# ###  ##
END

cat << END > /etc/logo
####### NOMADIC LINUX ######
END

echo -e "$X ISSUE"
cat << END > /etc/issue
`cat /etc/logo`
`uname -a`
This image was born on: `date`
No warranty.  No help. May the force be with you.
END

echo -e "$X MOTD"
cat << END > /etc/motd
`cat /etc/icon`
`cat /etc/logo`
No warranty.  No help. May the force be with you.
END

echo -e "$X READY!"
