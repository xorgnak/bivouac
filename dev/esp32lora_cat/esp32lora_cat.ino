// Includes

// my
//#include "BluetoothSerial.h"
#include "secrets.h"
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif
//
#include <WiFi.h>
#include <PubSubClient.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <SPI.h>
#include <LoRa.h>

// LoRa Settings
#define BAND 915E6
#define SS 18
#define RST 14
#define DI0 26

// network userid.
String addr;
String userid;
String _userid;
String userStatus = "200";

// buffers for lora/serial/bt io.
String pkt_in = "";
String pkt_out = "";

// lora out packet type
int pkt_type = 0;
int _pkt_type = 0;
int pkt_strength = 0;

// lora rx info
String _platform;
String _type;
String _from;

// dev ids
char cw[32];
char host[32];
char hostName[32];

// packet forwarding
bool pkt_dx = true;
bool pkt_fwd = false;
int pkt_dx_delay = 5000;
long pkt_dx_time = 0;

// transponder
bool beacon = true;
long beacon_last = 0;
int beacon_delay = 30000;
String location = "OK";

// blinking debug
int blinking = 0;

// internal
long now = 0;
long announced = 0;

#include "product.h"
//#include "bt.h"
//#include "btn0.h"
#include "http.h"
//#include "mdns.h"
//#include "mqtt.h"
#include "oled.h"
//#include "wifi.h"

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
  sprintf(hostName, "%s-%s", productName.c_str(), userid.c_str());
  sprintf(host, "%s/", HUB);
}

void setup() {
  setupUserId();
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  Serial.begin(115200);
  while ( !Serial ) { delay(1); }

  WiFi.setHostname(hostName);
  WiFi.begin(ssid, password);
  Serial.printf("wifi started\n");
  //
  // LoRa
  //
  LoRa.setPins(SS, RST, DI0);
  LoRa.begin(BAND);
  Serial.printf("lora started\n");
  delay(50);
  loraPkt(location);
  loraSEND();
  state_lora = true;
  Serial.printf("lora beacon\n");
//  Serial.printf("mdns started\n");
//  Serial.printf("serial bluetotth started\n");
//  Serial.printf("mqtt started\n");
  setup_http();
  Serial.printf("server started\n");
  
  char o[30];
  sprintf(o, "%s@%s/%s", userid, broker, HUB);
  standardOutput(String(s));
  digitalWrite(LED_BUILTIN, LOW);
}

void standardInput(String i) {
  i.trim();
  char x[256];
  sprintf(x, "--> %s", i.c_str());
  if (i == "!") {
    if (i.length() > 1) {
      i.remove(0, 1);
      beacon_delay = i.toInt();
    } else {
      beacon = !beacon;
    }
    sprintf(x, "beacon (%d) -> %d", beacon, beacon_delay);
  } else if (i.startsWith("#")) {
    i.remove(0, 1);
    userStatus = i;
    oled_update = true;
  } else if (i.startsWith("@")) {
    i.remove(0, 1);
    location = i;
    oled_update = true;
  } else if (i.startsWith(":")) {
    i.remove(0, 1);
    pkt_type = i.toInt();
    oled_update = true;
  } else if (i.startsWith("/")) {
    i.remove(0, 1);
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
  } else {
    //send
    userid = _userid;
    pkt_type = _pkt_type;
    loraPkt(i);
    loraSEND();
  }
  standardOutput(String(x));
}

void standardOutput(String s) {
  String _s;
  SerialBT.println(s);
  Serial.println(s);
  char o1[20];
  char o2[20];
  String dir;
  uint8_t inf;
  int typ;
  String frm;
  if (LoRa.packetRssi() < 0) {
    if (pkt_fwd == true) {
      dir = ">>>";
    } else {
      dir = "/|\\";
    }
  } else {
    dir = "<<<";
  }
  
  sprintf(o1, "(%s) %s:%s @%s #%s", productLogo, dir, location, userStatus);
  sprintf(o2, "[%02d:%02X] %s", LoRa.packetRssi(), pkt_type, _from);    
  _s += String(o1);
  _s += String(o2);
  _s += s;
  oledPrint(_s);
  SerialBT.println(s);
  Serial.println(s);
}

void loop() {
//  Serial.println("loop!");
  // create buffer
  char o[127];
  // set clock
  now = millis();
  // Receive a message first...
//  Serial.println("lora?");
  if (LoRa.parsePacket()) {
    Serial.println("lora!");
    if (blinking <= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    Serial.println("read...");
    String s = LoRa.readString();
    String _s = s;
    s.trim();
    Serial.println("read.");
    Serial.print("valid? ");
    Serial.println(s);
    if (s.startsWith("BEGIN ") && s.endsWith(" END")) {
      
      Serial.println("valid. strip markers.");
      s.remove(s.length() - 4);
      s.remove(0, 6);
      
      Serial.println("get platform");
      int ip = s.indexOf(" ");
      _platform = s.substring(0, ip);
      s.remove(0, ip + 1);
      
      Serial.println("get type");
      _type = s.substring(0, 1);
      s.remove(0, 2);
      
      Serial.println("get from");
      int iu = s.indexOf(" ");
      _from = s.substring(0, iu);
      s.remove(0, iu + 1);
      Serial.println("echo?");
      if (_from.startsWith(_userid)) {
        Serial.print("[ME] ");
        Serial.println(s);
      } else {
        Serial.print("[DX] ");
        Serial.println(s)
        pkt_fwd = true;
      }
      Serial.println("dx?");
      if (pkt_dx == true) {
        Serial.println("dx!");
        pkt_dx_time = now;
        Serial.println("set dx tick");
        userid = _from + String(">") + _userid;
        Serial.println("packed from");
        pkt_type = _type.toInt();
        Serial.println("set dx type.");
        loraPkt(s);
        Serial.println("pkt");
        userid = _userid;
        Serial.println("reset from");
        pkt_type = _pkt_type;
        Serial.println("reset type");
      }
    }
  }

  
  //Serial.println("bt?");

  if (Serial.available()) {
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    String i = Serial.readString();
    standardInput(i);
  }
  //Serial.println("fwd?");
  if (pkt_fwd == true && now - pkt_dx_time >= pkt_dx_delay) {
    Serial.println("fwd!");
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    loraSEND();
    pkt_fwd = false;
  }

  //Serial.println("beacon?");
  if (pkt_fwd == false && beacon == true && now - beacon_last >= beacon_delay ) {
    Serial.println("beacon!");
    beacon_last = now;
    sprintf(o, "@%s #%s", location.c_str(), userStatus.c_str());
    loraPkt(String(o));
    loraSEND();
  }
  
  //Serial.println("wifi?");
  if (WiFi.status() == WL_CONNECTED) {
    //Serial.println("mqtt?");
    loop_wifi();
  }
  loop_http();
  digitalWrite(LED_BUILTIN, LOW);
  //Serial.println("loop.");
}
