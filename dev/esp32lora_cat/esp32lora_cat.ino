// Includes

// my
#include "BluetoothSerial.h"
#include "secrets.h"
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif
//
#include <WiFi.h>
#include <PubSubClient.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <SSD1306.h> // you need to install the ESP8266 oled driver for SSD1306 
// by Daniel Eichorn and Fabrice Weinberg to get this file!
// It's in the arduino library manager :-D

#include <SPI.h>
#include <LoRa.h>    // this is the one by Sandeep Mistry, 
// (also in the Arduino Library manager :D )

// display descriptor
SSD1306 display(0x3c, 4, 15);

// definitions
//SPI defs for screen
#define SS 18
#define RST 14
#define DI0 26

// LoRa Settings
#define BAND 915E6

BluetoothSerial SerialBT;
// insert bt

String productBrand = "NOMAD";
String productName = "CAT";
String productLogo = "=^.^=";
String productVersion = "0.1a";
String productYear = "2021";
String productAuthor = "xorgnak@gmail.com";

// network userid.
String addr;
String userid;
String _userid;
String userStatus;
// buffers for lora/serial/bt io.
String pkt_in = "";
String pkt_out = "";
// lora out packet type
int pkt_type = 0;
int _pkt_type = 0;
int pkt_strength = 0;
// packet forwarding
bool pkt_dx = true;
bool pkt_fwd = false;
int pkt_dx_delay = 5000;
long pkt_dx_time = 0;

// transponder
bool beacon = true;
long beacon_last = 0;
int beacon_delay = 5000;
String location = "ALIVE";

// blinking debug
int blinking = 0;

// button
bool button_state = false;
long button_time = 0;
long button_dur = 0;
bool button_input = false;

// internal
long now = 0;
bool announced = false;
char cw[32];
char chan[32];
char host[32];
char hostName[32];
bool state_wifi = false;
bool state_mqtt = false;
bool state_lora = false;
bool state_bt = false;
bool state_usb = false;
bool oled_update = false;
String oled_0;
String oled_1;
String oled_2;
String oled_3;
long mqtt_last = 0;
int mqtt_delay = 30000;

WiFiClient espClient;
PubSubClient client(espClient);
const char* broker = "vango.me";

void mqttCallback(char* topic, byte* message, unsigned int length) {
  String messageTemp;
  
  for (int i = 0; i < length; i++) {
    Serial.print((char)message[i]);
    messageTemp += (char)message[i];
  }
  Serial.printf("msg: %s", messageTemp);
  Serial.println();
}

void mqttReconnect() {
  String ro = "MQTT: ";
  // Loop until we're reconnected
  while (!client.connected()) {
    if (client.connect("ESP8266Client")) {
      ro += "connected.";
      //Subscribe
      client.subscribe(hostName);
      char o[32];
      addr = WiFi.localIP().toString();
      sprintf(o, "%s %s", userid.c_str(), addr.c_str());
      if (announced == false) {
        client.publish(host, o);
        announced = true;
      }
    } else {
      ro += "failed.";
    }
    oled_3 = ro;
    oled_update = true;
  }
}

void loraPkt(String p) {
  pkt_out = "";
  pkt_out += String("BEGIN ");
  pkt_out += productName;
  pkt_out += String(" ");
  pkt_out += String(pkt_type, HEX);
  pkt_out += String(" ");
  pkt_out += userid;
  pkt_out += String(" ");
  pkt_out += p;
  pkt_out += String(" END");
}

void loraSEND() {
  LoRa.beginPacket();
  LoRa.print(pkt_out);
  LoRa.endPacket();
  pkt_out = "";
}

void setupUserId() {
  uint32_t chipId = 0;
  for (int i = 0; i < 17; i = i + 8) {
    chipId |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
  }
  char a[17];
  sprintf(a , "%06X", chipId);
  userid = String(a);
  _userid = userid;
}

void oledDISPLAY() {
  display.clear();
  display.drawString(0, 0, oled_0.c_str());
  display.drawString(0, 10, oled_1.c_str());
  display.drawString(0, 20, oled_2.c_str());
  display.drawString(0, 30, oled_3.c_str());
  display.display();
}

void oledReset() {
  pinMode(16, OUTPUT);
  digitalWrite(16, LOW); // set GPIO16 low to reset OLED
  delay(50);
  digitalWrite(16, HIGH);
  display.init();
  //  display.flipScreenVertically();
  display.setFont(ArialMT_Plain_10);
  display.setTextAlignment(TEXT_ALIGN_LEFT);
}

void stateOLED() {
  char l0[20];
  sprintf(l0, "%s %s %s v%s", productBrand.c_str(), productName.c_str(), productLogo.c_str(), productVersion.c_str() );
  oled_0 = String(l0);
  char l1[20];
  sprintf(l1, "%s %s", hostName, WiFi.localIP());
  oled_1 = String(l1);
  char l2[20];
  sprintf(l2, "[%d%d%d%d%d]", state_wifi, state_mqtt, state_lora, state_bt, state_usb);
  oled_2 = String(l2);
  char l3[20];
  sprintf(l3, "(c) %s %s", productYear.c_str(), productAuthor.c_str());
  oled_3 = String(l3);
  oledDISPLAY();
}


void button_ISR() {
  button_state = !button_state;
  if (button_state == true) {
    button_time = now;
    button_dur = 0;
  } else {
    button_dur = now - button_time;
    button_time = 0;
  }
  if (button_dur > 10 && button_dur < 2000) {
    digitalWrite(LED_BUILTIN, HIGH);
    button_input = true;
  }
  if (button_input == true) {
    digitalWrite(LED_BUILTIN, HIGH);
  }
}


void setup() {
  setupUserId();
  sprintf(hostName, "%s-%s", productName.c_str(), userid.c_str());
  sprintf(host, "%s", HUB);
  sprintf(chan, "/%s/%s-%s", HUB, productName.c_str(), userid.c_str());
  sprintf(cw, "%s/%s/cw", HUB, userid.c_str()); 
  pinMode(0, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(0), button_ISR, CHANGE);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  // pre_init

  oledReset();
  //  stateOLED();
  char o1[20];
  sprintf(o1, "%s %s v%s", productBrand.c_str(), productName.c_str(), productVersion.c_str());
  oled_0 = String(o1);
  char o2[20];
  sprintf(o2, "HOST: %s", hostName);
  oled_1 = String(o2);
  char o3[20];
  sprintf(o3, "HUB: %s", HUB);
  oled_2 = String(o3);
  oled_3 = "initializing...";
  oledDISPLAY();
  Serial.begin(115200);
  while ( !Serial ) {}

  attachInterrupt(0, button_ISR, CHANGE);
  
  WiFi.setHostname(hostName);
  WiFi.begin(ssid, password);
  // setup_init
  SPI.begin(5, 19, 27, 18);
  LoRa.setPins(SS, RST, DI0);
  if (!LoRa.begin(BAND)) {
    delay(1);
  }
  loraPkt(location);
  loraSEND();
  state_lora = true;

  if (!MDNS.begin(hostName)) {
    standardOutput("MDNS: failed.");
  }
  MDNS.addService("http", "tcp", 80);
  //standardOutput("MDNS: running.");
  // insert
  SerialBT.begin(hostName); //Bluetooth device name
  // insert
  client.setServer(broker, 1883);
  client.setCallback(mqttCallback);
  
  digitalWrite(LED_BUILTIN, LOW);
}

void standardInput(String i) {
  i.trim();
  char x[256];
  if (i == "!") {
    if (i.length() > 1) {
      i.remove(0, 1);
      beacon_delay = i.toInt();
    } else {
      beacon = !beacon;
    }

    sprintf(x, "beacon[%d]: %d", beacon, beacon_delay);

  } else if (i.startsWith("#")) {
    i.remove(0, 1);
    userStatus = i;
    sprintf(x, "status[#]: %s", userStatus.c_str());
  } else if (i.startsWith("@")) {
    i.remove(0, 1);
    location = i;
    sprintf(x, "location[@]: %s", location.c_str());
  } else if (i.startsWith(":")) {
    i.remove(0, 1);
    pkt_type = i.toInt();
    sprintf(x, "type[:]: %d", pkt_type);
  } else if (i.startsWith("/")) {    
  i.remove(0,1);
  String ixd;
  String idp;
  int ixm = i.indexOf(": ");
    if (ixm < i.length()) {
      ixd = i.substring(0, ixm);
      idp = i.substring(ixm + 2);
    } else {
      ixd = host;
      idp = i;
    }
    client.publish(ixd.c_str(), idp.c_str());
    sprintf(x, "[%s] %s", ixd.c_str(), idp.c_str());
  } else {
    //send
    userid = _userid;
    pkt_type = _pkt_type;
    loraPkt(i);
    sprintf(x, "[TX][%d] %s", pkt_type, pkt_out.c_str());
    loraSEND();
  }
  standardOutput(String(x));
}

void standardOutput(String s) {
  if (SerialBT) {
    SerialBT.println(s);
  }
  if (Serial) {
    Serial.println(s);
  }
  oled_0 = s.substring(0, 20);
  oled_1 = s.substring(20, 40);
  oled_2 = s.substring(40, 60);
  oled_3 = s.substring(60, 80);
  oled_update = true;
}

void loop() {
  char o[256];
  now = millis();
  // Receive a message first...
  if (LoRa.parsePacket()) {
    if (blinking <= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    String s = LoRa.readString();
    String _s = s;
    s.trim();
    if (s.startsWith("BEGIN ") && s.endsWith(" END")) {
      s.remove(s.length() - 4);
      s.remove(0, 6);

      int ip = s.indexOf(" ");
      String _platform = s.substring(0, ip);
      s.remove(0, ip + 1);

      String _type = s.substring(0, 1);
      s.remove(0, 2);

      int iu = s.indexOf(" ");
      String _from = s.substring(0, iu);
      s.remove(0, iu + 1);

      if (_from.startsWith(_userid)) {
        sprintf(o, "[ME][%d][%d]%s: %s", LoRa.packetRssi(), _type.toInt(), _from.c_str(), s.c_str());
        standardOutput(String(o));
      } else {
        sprintf(o, "[RX][%d][%d]%s: %s", LoRa.packetRssi(), _type.toInt(), _from.c_str(), s.c_str());
        standardOutput(String(o));
        pkt_fwd = true;
      }

      if (pkt_dx == true) {
        pkt_dx_time = now;
        userid = _from + String(">") + _userid;
        pkt_type = _type.toInt();
        loraPkt(s);
        userid = _userid;
        pkt_type = _pkt_type;
      }
    }
  }

  if (SerialBT.available()) {
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    String i = SerialBT.readString();
    standardInput(i);
  }
  if (Serial.available()) {
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    String i = Serial.readString();
    standardInput(i);
  }

  if (pkt_fwd == true && now - pkt_dx_time >= pkt_dx_delay) {
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    char o[256];
    sprintf(o, "[DX] %s", pkt_out.c_str());
    standardOutput(String(o));
    loraSEND();
    pkt_fwd = false;
  }

  if (button_input == true) {
    sprintf(o, "%03d", button_dur);
    standardOutput(String(o));
    if (pkt_type > 0) {
      loraPkt(String(o));
      loraSEND();
    }
    client.publish(cw,o);
    button_input = false;
  }

  if (pkt_fwd == false && beacon == true && now - beacon_last >= beacon_delay ) {
    beacon_last = now;
    sprintf(o, "@%s #%s", location.c_str(), userStatus.c_str());
    loraPkt(String(o));
    loraSEND();
  }
  if (WiFi.status() == WL_CONNECTED) {
    if (!client.connected()) {
      mqttReconnect();
    }
    client.loop();
  }

  if (oled_update == true) {
    oledDISPLAY();
    oled_update = false;
  }
  digitalWrite(LED_BUILTIN, LOW);
}
