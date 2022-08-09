/*
long mqtt_last = 0;
int mqtt_delay = 30000;

WiFiClient espClient;
PubSubClient client(espClient);

void mqttReconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    if (client.connect("ESP8266Client")) {
      //Subscribe
      client.subscribe(hostName);
      char o[32];
      addr = WiFi.localIP().toString();
      sprintf(o, "%s %s", hostName, addr.c_str());
      client.publish(HUB, o);
    }
    // update info line
    oled_update = true;
  }
}

void mqttCallback(char* topic, byte* message, unsigned int length) {
  String messageTemp;

  for (int i = 0; i < length; i++) {
    Serial.print((char)message[i]);
    messageTemp += (char)message[i];
  }
  if (WEBSOCKET) {
    ws.printfAll("<p style='color: grey'>%s</p>", messageTemp);
  }
  standardOutput("[BROKER] " + messageTemp);
}

void setup_mqtt() {
  client.setServer(broker, 1883);
  client.setCallback(mqttCallback);
}

void loop_mqtt() {
      if (!client.connected()) {
      Serial.println("mqtt!");
      mqttReconnect();
    }
    client.loop();
}
*/
