#!/bin/bash

here=`pwd`;
conf=bivouac.conf;


DEBS='git screen ruby-full redis-server redis-tools build-essential nginx ngircd tor emacs-nox mosquitto python3 python3-pip git python3-pil python3-pil.imagetk golang pulseaudio pulseaudio-module-bluetooth alsa-base alsa-tools alsa-utils imagemagick';
DEBS_HAM='soundmodem multimon-ng ax25-apps ax25-tools golang libopus0 libopus-dev libopenal-dev libconfig-dev libprotobuf-c-dev libssl-dev cmake autotools-dev autoconf libtool openssl';
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
    echo "no file: $conf";
    exit 1
fi

source $conf

debug 'init' "0"

if [[ "$1" == "-h" || "$1" == "-u" || "$1" == "--help" || "$1" == "help" ]]; then
    echo "usage: $0 [install|sd|op]"
    echo "install: normalize system, install packages, and install gems."
    echo "\$COMMS, \$IOT, \$MINE \$INIT : install submodule."
    echo "sd: pre-configure raspberry pi os for network."
    echo "op: begin operator mode."
elif [[ "$1" == 'sd' ]]; then
    echo "##### SD INIT #####"
    sudo cp -fvv /etc/wpa_supplicant/wpa_supplicant.conf /media/pi/boot/
    sudo touch /media/pi/boot/ssh
    echo "##### SD DONE #####"
elif [[ "$1" == 'op' || "$1" == "op" ]]; then
    echo "##### OP INIT #####"
    $(go env GOPATH)/bin/barnard -insecure -server $MUMBLE -username $NICK;
    echo "##### OP DONE #####"
elif [[ "$1" == "install" ]]; then
    echo "##### INSTALL INIT #####"
    
    debs="$DEBS $DEBS_HAM $DEBS_FUN ";
    
#    if [[ "$GUI" == "true" ]]; then
#	debs="$debs $DEBS_GUI";
#    fi
    
#    if [[ "$BOX" == 'true' ]]; then
#	debs="$debs $DEBS_SHELL";
#    fi
    if [[ "$BARE" != "true" ]]; then
	echo "##### installing debs..."
	sudo apt update && sudo apt upgrade -y && sudo apt install -y $debs;
	echo "##### installing gems..."
	sudo gem install $GEMS;
    fi
    
    echo "##### install nomad.sh"

    sudo ./exe/nomad.sh $USER;

    echo "##### submodules?"
    
    if [[ "$COMMS" == 'true' ]]; then
	echo "##### installing comms";
	# mumble server
	cd ~
	git clone https://github.com/umurmur/umurmur.git
	cd umurmur
	./autogen.sh
	./configure
	make
	sudo cp -fvv src/umurmurd /usr/bin/umurmurd
	# mumble client
	cd ~
	go get -u layeh.com/barnard
	sudo mkdir -p /usr/share/alsa/
	sudo cp -fvv alsa.conf /usr/share/alsa/alsa.conf
	cat << EOF > /home/$USER/asound.conf
pcm.!default { 
 type hw     
 card 1
}
ctl.!default {
 type hw
 card 1
}
EOF
	sudo cp -fvv /home/$USER/asound.conf /etc/asound.conf
    fi
    
    if [[ "$MINE" == 'true' ]]; then
	cd ~
	git clone https://github.com/revoxhere/duino-coin
	cd duino-coin
	python3 -m pip install -r requirements.txt
	python3 PC_Miner.py
    fi
    
    if [[ "$IOT" == "true" ]]; then
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
	echo "function upload() { source config.sh; echo \"\$FQBN\"; arduino-cli compile --fqbn \$FQBN \`pwd\` && arduino-cli upload --port /dev/ttyUSB0 --fqbn \$FQBN \`pwd\`; }" >> $f;
	echo 'echo "upload -> upload sketch to device"' >> $f;
	echo "alias monitor='cat /dev/ttyUSB0'" >> $f;
	echo 'echo "monitor -> monitor serial traffic from device"' >> $f;
	echo "function arduino() { arduino-cli lib install \"$1\"; }" >> $f;
	echo 'echo "arduino <library> -> install arduino library"' >> $f;
	echo "function sketch() { arduino-cli sketch new \"\$1\" && echo 'export FQBN=\"\"' > \$1/config.sh && editor \$1/config.sh && editor \$1/\$1.ino; }" >> $f;
	echo 'echo "sketch <name> -> create new arduino sketch."' >> $f;
	echo "### NOMAD arduino-cli end ###" >> $f;
    fi
    
    if [[ "$INIT" == 'true' ]]; then
	echo "##### resetting root crontab...";
	(echo "@reboot cd $here && ./start") | sudo crontab -
    fi
    echo "##### resetting file ownership to user...";
    sudo chown $USER:$USER ~/*;
    sudo chown $USER:$USER ~/.*;
    
    echo "##### REBOOT TO RUN #####";
    echo "# v--- add to ~/.bashrc #";
    echo "#    source ~/.nomad    #";
    echo "# to load nomad tools.  #"
    echo "#####     DONE!     #####";
else
    echo "##### NOMADIC #####"
    echo "usage: $0 --help"
    echo "###################"
    exit 0;
fi
