/*
BluetoothSerial SerialBT;

void setup_bt() {
  SerialBT.begin(hostName);
}

void loop_bt() {
    if (SerialBT.available()) {
    Serial.println("bt!");
    if (blinking >= 0) {
      digitalWrite(LED_BUILTIN, HIGH);
    }
    String i = SerialBT.readString();
    standardInput(i);
  }
}
*/
