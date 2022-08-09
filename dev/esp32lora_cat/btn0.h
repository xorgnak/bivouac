/*
bool button_state = false;
long button_time = 0;
long button_dur = 0;
bool button_input = false;

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

void setup_btn0 () {
  pinMode(0, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(0), button_ISR, CHANGE);
}

void loop_btn0 () {
    if (button_input == true) {
      Serial.println("cw!");
      sprintf(o, "CW %04dms", button_dur);
      oledPrint(String(o));
      if (MQTT) {
        client.publish(cw, o);
      }
    }
}
*/
