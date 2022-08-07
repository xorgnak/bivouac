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

//EspAsyncWebServer
#include "AsyncTCP.h"
#include "ESPAsyncWebServer.h"
#include "index.h"
AsyncWebServer server(80);
AsyncWebSocket ws("/ws"); // access at ws://[esp ip]/ws
AsyncEventSource events("/events"); // event source (Server-Sent events)



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
String productLogo0 = "=-.-=";
String productLogo1 = "=^.^=";
String productLogo2 = "=*.*=";
String productLogo3 = "=O.O=";
String productLogo4 = "=@.@=";
String productLogo5 = "=~.~=";

String productVersion = "0.1a";
String productYear = "2021";
String productAuthor = "xorgnak@gmail.com";

// network userid.
String addr;
String userid;
String _userid;
String userStatus = "200";
int productLogo = 0;


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

// button
bool button_state = false;
long button_time = 0;
long button_dur = 0;
bool button_input = false;

// internal
long now = 0;
long announced = 0;
char cw[32];
char chan[32];
char host[32];
char hostName[32];
bool state_wifi = false;
bool state_mqtt = false;
bool state_lora = false;
bool state_bt = false;
bool state_usb = false;
bool oled_update = true;
String oled_0;
String oled_1;
String oled_2;
String oled_3;
String oled_4;
String oled_5;
long mqtt_last = 0;
int mqtt_delay = 30000;

WiFiClient espClient;
PubSubClient client(espClient);



void onRequest(AsyncWebServerRequest *request) {
  //Handle Unknown Request
  request->send(404);
}

void onBody(AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
  //Handle body
}

void onUpload(AsyncWebServerRequest *request, String filename, size_t index, uint8_t *data, size_t len, bool final) {
  //Handle upload
}

void onEvent(AsyncWebSocket * server, AsyncWebSocketClient * client, AwsEventType type, void * arg, uint8_t *data, size_t len) {
  if (type == WS_EVT_CONNECT) {
    Serial.printf("ws[%s][%u] connect", hostName, client->id());
    client->printf("+%s:%u\n", hostName, client->id());
    // ws: clients
    client->ping();
  } else if (type == WS_EVT_DISCONNECT) {
    Serial.printf("-%s:%u\n", hostName, client->id());
  } else if (type == WS_EVT_ERROR) {
    Serial.printf("ws[%s][%u] error(%u): %s\n", server->url(), client->id(), *((uint16_t*)arg), (char*)data);
  } else if (type == WS_EVT_PONG) {
    Serial.printf("ws[%s][%u] pong[%u]: %s\n", server->url(), client->id(), len, (len) ? (char*)data : "");
  } else if (type == WS_EVT_DATA) {
    AwsFrameInfo * info = (AwsFrameInfo*)arg;
    String msg = "";
    if (info->final && info->index == 0 && info->len == len) {
      //the whole message is in a single frame and we got all of it's data
      Serial.printf("ws[%s][%u] %s-message[%llu]: ", server->url(), client->id(), (info->opcode == WS_TEXT) ? "text" : "binary", info->len);

      if (info->opcode == WS_TEXT) {
        for (size_t i = 0; i < info->len; i++) {
          msg += (char) data[i];
        }
      } else {
        char buff[3];
        for (size_t i = 0; i < info->len; i++) {
          sprintf(buff, "%02x ", (uint8_t) data[i]);
          msg += buff ;
        }
      }
      Serial.printf("%s\n", msg.c_str());

      if (info->opcode == WS_TEXT) {
        standardInput(String(msg.c_str()));
        ws.printfAll("<p style='color: green'>%s</p>", msg.c_str());
      } else {
        client->binary("I got your binary message");
      }
    } else {
      //message is comprised of multiple frames or the frame is split into multiple packets
      if (info->index == 0) {
        if (info->num == 0)
          Serial.printf("ws[%s][%u] %s-message start\n", server->url(), client->id(), (info->message_opcode == WS_TEXT) ? "text" : "binary");
        Serial.printf("ws[%s][%u] frame[%u] start[%llu]\n", server->url(), client->id(), info->num, info->len);
      }

      Serial.printf("ws[%s][%u] frame[%u] %s[%llu - %llu]: ", server->url(), client->id(), info->num, (info->message_opcode == WS_TEXT) ? "text" : "binary", info->index, info->index + len);

      if (info->opcode == WS_TEXT) {
        for (size_t i = 0; i < len; i++) {
          msg += (char) data[i];
        }
      } else {
        char buff[3];
        for (size_t i = 0; i < len; i++) {
          sprintf(buff, "%02x ", (uint8_t) data[i]);
          msg += buff ;
        }
      }
      Serial.printf("%s\n", msg.c_str());

      if ((info->index + len) == info->len) {
        Serial.printf("ws[%s][%u] frame[%u] end[%llu]\n", server->url(), client->id(), info->num, info->len);
        if (info->final) {
          Serial.printf("ws[%s][%u] %s-message end\n", server->url(), client->id(), (info->message_opcode == WS_TEXT) ? "text" : "binary");
          if (info->message_opcode == WS_TEXT) {
            standardInput(String(msg.c_str()));
            ws.printfAll("<p style='color: green'>%s</p>", msg.c_str());
          } else {
            client->binary("I got your binary message");
          }
        }
      }
    }
  }
}

void mqttCallback(char* topic, byte* message, unsigned int length) {
  String messageTemp;

  for (int i = 0; i < length; i++) {
    Serial.print((char)message[i]);
    messageTemp += (char)message[i];
  }
  ws.printfAll("<p style='color: grey'>%s</p>", messageTemp);
  standardOutput("[BROKER] " + messageTemp);
}

void mqttReconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    if (client.connect("ESP8266Client")) {
      productLogo = 1;
      //Subscribe
      client.subscribe(hostName);
      char o[32];
      addr = WiFi.localIP().toString();
      sprintf(o, "%s %s", hostName, addr.c_str());
      client.publish(HUB, o);
    } else {
      productLogo = 0;
    }
    // update info line
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
//  Serial.println("| clear");
  display.clear();
//  Serial.println("| line 1");
  display.drawString(0, 0, oled_0.c_str());
//  Serial.println("| line 2");
  display.drawString(0, 10, oled_1.c_str());
//  Serial.println("| line 3");
  display.drawString(0, 20, oled_2.c_str());
//  Serial.println("| line 4");
  display.drawString(0, 30, oled_3.c_str());
//  Serial.println("| line 5");
  display.drawString(0, 40, oled_4.c_str());
//  Serial.println("| line 6");
  display.drawString(0, 50, oled_5.c_str());
//  Serial.println("| display");
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

void button_ISR() {
  button_state = !button_state;
  if (button_state == true) {
    button_time = now;
    button_dur = 0;
  } else {
    button_dur = now - button_time;
    button_time = 0;
  }
  if (button_dur > 20 && button_dur < 2500) {
//    digitalWrite(LED_BUILTIN, HIGH);
    button_input = true;
  }
  if (button_input == true) {
    digitalWrite(LED_BUILTIN, HIGH);
  }
}

void setup() {
  setupUserId();
  sprintf(hostName, "%s-%s", productName.c_str(), userid.c_str());
  sprintf(host, "%s/", HUB);
  sprintf(cw, "%s/cw", HUB);
  pinMode(0, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(0), button_ISR, CHANGE);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  // pre_init

  Serial.begin(115200);
  while ( !Serial ) {}
  Serial.printf("serial started\n");
  delay(50);
  WiFi.setHostname(hostName);
  WiFi.begin(ssid, password);
  Serial.printf("wifi started\n");
  // setup_init
  delay(50);
  SPI.begin(5, 19, 27, 18);
  oledReset();
  LoRa.setPins(SS, RST, DI0);
  LoRa.begin(BAND);
  Serial.printf("lora started\n");
  delay(50);
  loraPkt(location);
  loraSEND();
  state_lora = true;
  Serial.printf("lora beacon\n");
  // lora: on
  delay(50);
  if (!MDNS.begin(hostName)) {
    Serial.println("MDNS: failed.\n");
  }
  MDNS.addService("http", "tcp", 80);
  Serial.printf("mdns started\n");
  delay(50);
  SerialBT.begin(hostName); //Bluetooth device name
  Serial.printf("serial bluetotth started\n");
  delay(50);
  client.setServer(broker, 1883);
  client.setCallback(mqttCallback);
  Serial.printf("mqtt started\n");

  ws.onEvent(onEvent);
  server.addHandler(&ws);

  server.addHandler(&events);

  server.on("/", HTTP_GET, [](AsyncWebServerRequest * request) {
    request->send(200, "text/html", index_html);
  });

  server.on("/scan", HTTP_GET, [](AsyncWebServerRequest * request) {
    String json = "[";
    int n = WiFi.scanComplete();
    if (n == -2) {
      WiFi.scanNetworks(true);
    } else if (n) {
      for (int i = 0; i < n; ++i) {
        if (i) json += ",";
        json += "{";
        json += "\"rssi\":" + String(WiFi.RSSI(i));
        json += ",\"ssid\":\"" + WiFi.SSID(i) + "\"";
        json += ",\"bssid\":\"" + WiFi.BSSIDstr(i) + "\"";
        json += ",\"channel\":" + String(WiFi.channel(i));
        json += ",\"secure\":" + String(WiFi.encryptionType(i));
        json += "}";
      }
      WiFi.scanDelete();
      if (WiFi.scanComplete() == -2) {
        WiFi.scanNetworks(true);
      }
    }
    json += "]";
    request->send(200, "application/json", json);
    json = String();
  });

  server.begin();
  Serial.printf("server started\n");
  delay(50);
  
  char o[100];
  sprintf(o, "%s@%s/%s", userid, broker, HUB);
  String oo = String(o);
  char o1[20];
  sprintf(o1, "%s %sv%s (c)%s", productLogo0, productName, productVersion, productYear);
  oled_0 = String(o1);  
  oled_1 = oo.substring(0, 20);
  oled_2 = oo.substring(20, 40);
  oledDISPLAY();
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
  productLogo = 6;
  standardOutput(String(x));
}

void standardOutput(String s) {
  SerialBT.println(s);
  Serial.println(s);
  char o1[20];
  if (productLogo == 0) {
    sprintf(o1, "%s %sv%s (c)%s", productLogo0, productName, productVersion, productYear);
  } else if (productLogo == 1) {
    sprintf(o1, "%s :%s @%s #%s", productLogo1, String(pkt_type, HEX), location, userStatus);
  } else if (productLogo == 2) {
    sprintf(o1, "%s :%s @%s #%s", productLogo1, String(pkt_type, HEX), location, userStatus);  
  } else if (productLogo == 3) {
    sprintf(o1, "%s :%s @%s #%s", productLogo2, String(pkt_type, HEX), location, userStatus);    
  } else if (productLogo == 4) {
    sprintf(o1, "%s (%d) :%s %s", productLogo3, LoRa.packetRssi(), String(_type.toInt(), HEX), _from.c_str());    
  } else if (productLogo == 5) {
    sprintf(o1, "%s >>>", productLogo4);
  } else if (productLogo == 6) {
    sprintf(o1, "%s <<<", productLogo5);
  }
  Serial.print("P: ");
  Serial.println(o1);
  oled_0 = String(o1);
  while (s.length() < 100) {
    s+=" ";
  }
  oled_1 = s.substring(0, 20);
  oled_2 = s.substring(20, 40);
  oled_3 = s.substring(40, 60);
  oled_4 = s.substring(60, 80);
  oled_5 = s.substring(80, 100);
//  Serial.println("--------");
//  Serial.println(oled_0);
//  Serial.println(oled_1);
//  Serial.println(oled_2);
//  Serial.println(oled_3); 
//  Serial.println(oled_4);
//  Serial.println(oled_5);   
//  Serial.println("--------");
  oled_update = true;
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
        Serial.println("yes.");
        productLogo = 3;     
        standardOutput(s);
      } else {
        Serial.println("no.");
        productLogo = 4;
        standardOutput(s);
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
  if (SerialBT.available()) {
    Serial.println("bt!");
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
  //Serial.println("fwd?");
  if (pkt_fwd == true && now - pkt_dx_time >= pkt_dx_delay) {
    Serial.println("fwd!");
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    productLogo = 5;
    standardOutput(pkt_out);
    loraSEND();
    pkt_fwd = false;
  }
  //Serial.println("cw?");
  if (button_input == true) {
    Serial.println("cw!");
    sprintf(o, "CW %04d", button_dur);
    standardOutput(String(o));
    client.publish(cw, o);
    if (pkt_type > 0) {
      loraPkt(String(o));
      loraSEND();
    }
    button_input = false;
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
    if (!client.connected()) {
      Serial.println("mqtt!");
      mqttReconnect();
    }
    client.loop();
  }
  
  //Serial.println("oled?");
  if (oled_update == true) {
    Serial.println("oled!");
    oledDISPLAY();
    productLogo = 1;
    oled_update = false;
  }
  
  //Serial.println("cleanup...");
  ws.cleanupClients();
  digitalWrite(LED_BUILTIN, LOW);
  //Serial.println("loop.");
}
