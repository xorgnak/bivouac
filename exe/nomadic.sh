#!/bin/bash

if [[ `which gum` == '' ]]; then
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
fi
FG='#0000ff'
here=`pwd`;
conf=bivouac.conf;
function say() {
    echo "[NOMADIC] $*";
    #gum style --width=20 --foreground "$FG" --border-foreground "$FG" --border rounded --align center --margin "0 0" --padding "0 0" $*;
}

DEBS='git screen ruby-full redis-server redis-tools build-essential nginx ngircd tor emacs-nox mosquitto mosquitto-clients python3 python3-pip python3-pil python3-pil.imagetk golang pulseaudio pulseaudio-module-bluetooth alsa-base alsa-tools alsa-utils imagemagick ruby-eventmachine ruby-image-processing';
DEBS_HAM='soundmodem multimon-ng ax25-apps ax25-tools golang libopus0 libopus-dev libopenal-dev libconfig-dev libprotobuf-c-dev libssl-dev cmake autotools-dev autoconf libtool openssl ruby-espeak';
DEBS_FUN='games-console tintin++ slashem';
DEBS_GUI='xinit xwayland terminator chromium dwm mumble vlc mednafen mednaffe';
DEBS_SSL='python-nginx-certbot certbot';
DEBS_SHELL=''
GEMS='sinatra thin eventmachine slop redis-objects pry rufus-scheduler redcarpet paho-mqtt cerebrum cryptology ruby-mud faker sinatra-websocket browser securerandom sentimental mqtt bundler cinch rqrcode webpush twilio-ruby rmagick binance';

mkdir -p mumble run home public
function debug() {
    echo "[$1] $2";
    redis-cli publish "DEBUG.nomadic.sh.$1" "$2" > /dev/null;
}

if [[ ! -f $conf ]]; then
    say 'Welcome!'
    ADMIN=$(gum input --placeholder='admin phone number')
    DOMAINS=$(gum input --placeholder='domains to host')
    CLUSTER=$(gum input --placeholder='telemetry host')
    TAG=$(gum input --placeholder='network tag')
    cat << EOF > $conf
# network wide configuration.
export MASK='';
export ID='';
export BOX='';

# telemetry server.
export CLUSTER='$CLUSTER';
export TAG='$TAG';

# hosting
export DOMAINS='$DOMAINS';

# admin contact.
export EMAIL='';
export PHONE='';
export ADMIN='$ADMIN';

# twilio api sid and key.
export PHONE_SID='';
export PHONE_KEY='';

# irc services.
export IRC="false";
export DEVS="false";
export IOT="false";
export MINE="false";
export INIT="false";
# end of network configuration.
EOF
    editor $conf
fi

source $conf

debug 'init' "0"

if [[ "$1" == 'clone' ]]; then
    say 'SD INIT'
    sudo cp -fvv /etc/wpa_supplicant/wpa_supplicant.conf /media/pi/boot/
    sudo touch /media/pi/boot/ssh
    say 'SD DONE'
#elif [[ "$1" == 'op' || "$1" == "operator" ]]; then
#    say "OP INIT"
#    MUMBLE=$(gum input --placeholder='host...');
#    NICK=$(gum input --placeholder='nick...');
#    $(go env GOPATH)/bin/barnard -insecure -server $MUMBLE -username $NICK;
#    say "OP DONE"
else
    say 'INSTALL INIT'
    
    debs="$DEBS $DEBS_HAM $DEBS_FUN ";
    
#    if [[ "$GUI" == "true" ]]; then
#	debs="$debs $DEBS_GUI";
#    fi
    
#    if [[ "$BOX" == 'true' ]]; then
#	debs="$debs $DEBS_SHELL";
#    fi
    if [[ "$BARE" != "true" ]]; then
	#gum spin -s minidot --title='debs...' --spinner.foreground="$FG"
	sudo apt update && sudo apt upgrade -y -q && sudo apt install -y -q $debs
	#gum spin -s minidot --title='gems...' --spinner.foreground="$FG"
	sudo gem install $GEMS
    fi
    
    say 'nomad'

    sudo ./exe/nomad.sh $USER;

    say 'submodules?'
    
#    if [[ "$COMMS" == 'true' ]]; then
#	say "comms init..."
#	cd ~
#	git clone https://github.com/umurmur/umurmur.git || echo "umurmur already cloned..."
#	cd umurmur
#	./autogen.sh
#	./configure
#	make
#	sudo cp -fvv src/umurmurd /usr/bin/umurmurd
#	# mumble client
#	cd ~
#	go get -u layeh.com/barnard
#	sudo mkdir -p /usr/share/alsa/
#	sudo cp -fvv alsa.conf /usr/share/alsa/alsa.conf
#	cat << EOF > /home/$USER/asound.conf
#pcm.!default { 
# type hw     
# card 1
#}
#ctl.!default {
# type hw
# card 1
#}
#EOF
#	sudo cp -fvv /home/$USER/asound.conf /etc/asound.conf
#	say "comms done!"
#    fi
    
    if [[ "$MINE" == 'true' ]]; then
	say 'mine init...'
	cd ~
	git clone https://github.com/revoxhere/duino-coin || echo "duino-coin already cloned..."
	cd duino-coin
	python3 -m pip install -r requirements.txt
	python3 PC_Miner.py
	say 'mine done!'
    fi
    
    if [[ "$IOT" == "true" ]]; then
	say 'iot init...'
	cd ~
	curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
	sudo cp -fvv bin/arduino-cli /usr/local/bin/arduino-cli
	rm -fR bin
	/usr/local/bin/arduino-cli config init
	cat <<EOF > ~/.arduino15/arduino-cli.yaml
board_manager:
  additional_urls: ["https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json", "https://github.com/Heltec-Aaron-Lee/WiFi_Kit_series/releases/download/0.0.5/package_heltec_esp32_index.json", "https://arduino.esp8266.com/stable/package_esp8266com_index.json"]
daemon:
  port: "50051"
directories:
  data: /home/pi/.arduino15
  downloads: /home/pi/.arduino15/staging
  user: /home/pi/Arduino
library:
  enable_unsafe_install: true
logging:
  file: ""
  format: text
  level: info
metrics:
  addr: :9090
  enabled: true
output:
  no_color: false
sketch:
  always_export_binaries: false
updater:
  enable_notification: true
EOF
	arduino-cli core update-index
	arduino-cli core install esp32:esp32
	arduino-cli core install esp8266:esp8266
	f=/home/$USER/.nomad
	echo "### NOMAD arduino-cli begin ###" >> $f;
	echo "function upload() { source config.sh; arduino-cli compile --fqbn \$FQBN \`pwd\` && arduino-cli upload --port /dev/ttyUSB0 --fqbn \$FQBN \`pwd\`; }" >> $f;
	echo 'echo "upload -> upload sketch to device"' >> $f;
	echo "alias monitor='cat /dev/ttyUSB0'" >> $f;
	echo 'echo "monitor -> monitor serial traffic from device"' >> $f;
	echo "function arduino() { arduino-cli lib install \"$1\"; }" >> $f;
	echo 'echo "arduino <library> -> install arduino library"' >> $f;
	echo "function sketch() { arduino-cli sketch new \"\$1\" && echo 'export FQBN=\"\"' > \$1/config.sh && editor \$1/config.sh && editor \$1/\$1.ino; }" >> $f;
	echo 'echo "sketch <name> -> create new arduino sketch."' >> $f;
	echo "### NOMAD arduino-cli end ###" >> $f;
	say 'iot done!'
    fi
    
    if [[ "$INIT" == 'true' ]]; then
	say 'init init...'
	    (echo "@reboot cd $here && ./start") | sudo crontab -
	say 'init done!'
    fi
    sudo chown $USER:$USER /home/$USER/*
    sudo chown $USER:$USER /home/$USER/.*
    say 'DONE'
fi
