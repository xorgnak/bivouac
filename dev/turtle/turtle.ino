/*********
  Rui Santos
  Complete project details at https://RandomNerdTutorials.com/esp32-cam-video-streaming-web-server-camera-home-assistant/
  
  IMPORTANT!!! 
   - Select Board "AI Thinker ESP32-CAM"
   - GPIO 0 must be connected to GND to upload a sketch
   - After connecting GPIO 0 to GND, press the ESP32-CAM on-board RESET button to put your board in flashing mode
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files.

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
*********/
#define DEV "turtle"

#include "esp_camera.h"
#include "WiFi.h"
#include <PubSubClient.h>
#include "esp_timer.h"
#include "img_converters.h"
#include "Arduino.h"
#include "fb_gfx.h"
#include "soc/soc.h" //disable brownout problems
#include "soc/rtc_cntl_reg.h"  //disable brownout problems
#include "esp_http_server.h"
#include "secrets.h"
static volatile bool wifi_connected = false;

String dev;
String devId;
String netId;
String userId;

String userid;
String id;

#define LED_BUILTIN 33

WiFiClient espClient;
PubSubClient client(espClient);




// [BEGIN] DO NO TOUCH

#define PART_BOUNDARY "123456789000000000000987654321"

#define CAMERA_MODEL_AI_THINKER

  #define PWDN_GPIO_NUM     32
  #define RESET_GPIO_NUM    -1
  #define XCLK_GPIO_NUM      0
  #define SIOD_GPIO_NUM     26
  #define SIOC_GPIO_NUM     27
  
  #define Y9_GPIO_NUM       35
  #define Y8_GPIO_NUM       34
  #define Y7_GPIO_NUM       39
  #define Y6_GPIO_NUM       36
  #define Y5_GPIO_NUM       21
  #define Y4_GPIO_NUM       19
  #define Y3_GPIO_NUM       18
  #define Y2_GPIO_NUM        5
  #define VSYNC_GPIO_NUM    25
  #define HREF_GPIO_NUM     23
  #define PCLK_GPIO_NUM     22

// [END] DO NO TOUCH



void mqttCallback(char* topic, byte* message, unsigned int length) {
  String msg;

  for (int i = 0; i < length; i++) {
    //Serial.print((char)message[i]);
    msg += (char)message[i];
  }
  //Serial.printf("msg: %s", msg);
  //Serial.println();
  if(msg[0] == '1') {
    //Serial.print("flash ");
    digitalWrite(4, HIGH);
  } else {
    digitalWrite(4, LOW);
  }
    
  if(msg[1] == '1') {
    //Serial.print("led ");
    digitalWrite(LED_BUILTIN, LOW);
  } else {
    digitalWrite(LED_BUILTIN, HIGH);
  }
  Serial.println();
}


void wifiOnConnect(){
  mqttReconnect();
}

void wifiOnDisconnect(){
  Serial.println("STA Disconnected");
  delay(100);
  WiFi.reconnect();
}

void wifiConnectedLoop(){
  if(wifi_connected){
    if (!client.connected()) {
      mqttReconnect();
    }
    client.loop();
  }
}

void WiFiEvent(WiFiEvent_t event){
  switch(event) {

  case SYSTEM_EVENT_STA_CONNECTED:
    WiFi.enableIpV6();
    break;

  case SYSTEM_EVENT_AP_STA_GOT_IP6:
//    Serial.print("GOT IPv6: ");
//    Serial.println(WiFi.localIPv6());
    delay(2000);
    wifiOnConnect();
    wifi_connected = true;
    break;

  case SYSTEM_EVENT_STA_DISCONNECTED:
    wifi_connected = false;
    wifiOnDisconnect();
    break;
  
  default:
    break;
  }
}


static const char* _STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* _STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* _STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

httpd_handle_t stream_httpd = NULL;

static esp_err_t stream_handler(httpd_req_t *req){
  camera_fb_t * fb = NULL;
  esp_err_t res = ESP_OK;
  size_t _jpg_buf_len = 0;
  uint8_t * _jpg_buf = NULL;
  char * part_buf[64];

  res = httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
  if(res != ESP_OK){
    return res;
  }

  while(true){
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      res = ESP_FAIL;
    } else {
      if(fb->width > 400){
        if(fb->format != PIXFORMAT_JPEG){
          bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
          esp_camera_fb_return(fb);
          fb = NULL;
          if(!jpeg_converted){
            Serial.println("JPEG compression failed");
            res = ESP_FAIL;
          }
        } else {
          _jpg_buf_len = fb->len;
          _jpg_buf = fb->buf;
        }
      }
    }
    if(res == ESP_OK){
      size_t hlen = snprintf((char *)part_buf, 64, _STREAM_PART, _jpg_buf_len);
      res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
    }
    if(res == ESP_OK){
      res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
    }
    if(res == ESP_OK){
      res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
    }
    if(fb){
      esp_camera_fb_return(fb);
      fb = NULL;
      _jpg_buf = NULL;
    } else if(_jpg_buf){
      free(_jpg_buf);
      _jpg_buf = NULL;
    }
    if(res != ESP_OK){
      break;
    }
    //Serial.printf("MJPG: %uB\n",(uint32_t)(_jpg_buf_len));
  }
  return res;
}

void startCameraServer(){
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 80;

  httpd_uri_t index_uri = {
    .uri       = "/",
    .method    = HTTP_GET,
    .handler   = stream_handler,
    .user_ctx  = NULL
  };
  
  //Serial.printf("Starting web server on port: '%d'\n", config.server_port);
  if (httpd_start(&stream_httpd, &config) == ESP_OK) {
    httpd_register_uri_handler(stream_httpd, &index_uri);
  }
}

void mqttReconnect() {
  while (!client.connected()) {
    if (client.connect("ESP8266Client")) {
      Serial.println("### mqtt connected.");
      client.subscribe(netId.c_str());
      char o[32];
      String addr = WiFi.localIP().toString();
      sprintf(o, "%s %s", devId.c_str(), addr.c_str());
      client.publish(HUB, o);
      Serial.print("DEV: ");
      Serial.println(o);
    }
  }
}

void setupUserId() {
  uint32_t chipId = 0;
  for (int i = 0; i < 17; i = i + 8) {
    chipId |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
  }
  char x[17];
  sprintf(x, "%06X", chipId);
  dev = String(x);
  // build device id
  char a[20];
  sprintf(a, "%s_%s", DEV, dev.c_str());
  devId = String(a);
  // build broker id
  char aa[32];
  sprintf(aa, "%s/%s", HUB, devId.c_str());
  netId = String(aa);
  // build user channel
  char aaa[50];
  sprintf(aaa, "%s/%s", HUB, BOX);
  userId = String(aaa);
}

void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); //disable brownout detector
  Serial.begin(115200);

  setupUserId();

  pinMode(4, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);

  Serial.println("\n\n\n\n\n\n\n\n\n\n\nINIT!");
  Serial.setDebugOutput(false);

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG; 
  config.frame_size = FRAMESIZE_UXGA;
  config.jpeg_quality = 40;
  config.fb_count = 16;
  
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }


  Serial.println("wifi...");
  // Wi-Fi connection
  WiFi.disconnect(true);
  WiFi.setHostname(id.c_str());
  WiFi.onEvent(WiFiEvent);
  WiFi.mode(WIFI_MODE_STA);
  WiFi.begin(WIFI, PASS);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(50);
    Serial.print(".");
  }
  
  Serial.println("mqtt...");
  client.setServer(BROKER, 1883);
  client.setCallback(mqttCallback);
  
  startCameraServer();
}

void loop() {
  wifiConnectedLoop();
  //delay(1);
}
