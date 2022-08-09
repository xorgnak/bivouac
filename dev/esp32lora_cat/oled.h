#include <SSD1306.h>
SSD1306 display(0x3c, 4, 15);

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

void oledPrint(String s) {
  
//  Serial.println("| clear");
  while (s.length() < 120) { s+="_"; }
  display.clear();
//  Serial.println("| line 1");
  display.drawString(0,  0, s.substring( 0, 20));
//  Serial.println("| line 2");
  display.drawString(0, 10, s.substring(20, 40));
//  Serial.println("| line 3");
  display.drawString(0, 20, s.substring(40, 60));
//  Serial.println("| line 4");
  display.drawString(0, 30, s.substring(60, 80));
//  Serial.println("| line 5");
  display.drawString(0, 40, s.substring(80, 100));
//  Serial.println("| line 6");
  display.drawString(0, 50, s.substring(100, 120));
//  Serial.println("| display");
  display.display();
}

void setup_oled() {
  SPI.begin(5, 19, 27, 18);
  oledReset();
}
