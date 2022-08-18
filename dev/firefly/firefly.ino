#include "secrets.h"
#include <FastLED.h>

FASTLED_USING_NAMESPACE

#define LED_TYPE    WS2811
#define COLOR_ORDER GRB

uint8_t gCurrentPatternNumber = 0; // Index number of which pattern is current
uint8_t gHue = 0; // rotating "base color" used by many of the patterns

CRGB leds[LEDS_NUM];


// SETUP
void setup() {
  FastLED.addLeds<LED_TYPE,LEDS_PIN,COLOR_ORDER>(leds, LEDS_NUM).setCorrection(TypicalLEDStrip);
  FastLED.setBrightness(LEDS_BRIGHTNESS);
}
 
// PATTERNS

void rainbow() { fill_rainbow( leds, LEDS_NUM, gHue, 7); }

void rainbowWithGlitter() { rainbow(); addGlitter(80); }

void addGlitter( fract8 chanceOfGlitter) { 
  if( random8() < chanceOfGlitter) {
    leds[ random16(LEDS_NUM) ] += CRGB::White;
  }
}

void confetti() 
{
  fadeToBlackBy( leds, LEDS_NUM, 10);
  int pos = random16(LEDS_NUM);
  leds[pos] += CHSV( gHue + random8(64), 200, 255);
}

void sinelon()
{
  fadeToBlackBy( leds, LEDS_NUM, 20);
  int pos = beatsin16( 13, 0, LEDS_NUM-1 );
  leds[pos] += CHSV( gHue, 255, 192);
}

void bpm()
{
  uint8_t BeatsPerMinute = 62;
  CRGBPalette16 palette = PartyColors_p;
  uint8_t beat = beatsin8( BeatsPerMinute, 64, 255);
  for( int i = 0; i < LEDS_NUM; i++) { //9948
    leds[i] = ColorFromPalette(palette, gHue+(i*2), beat-gHue+(i*10));
  }
}

void juggle() {
  fadeToBlackBy( leds, LEDS_NUM, 20);
  uint8_t dothue = 0;
  for( int i = 0; i < 8; i++) {
    leds[beatsin16( i+7, 0, LEDS_NUM-1 )] |= CHSV(dothue, 200, 255);
    dothue += 32;
  }
}

// PATTERN SWITCHING

// List of patterns to cycle through.  Each is defined as a separate function below.
typedef void (*SimplePatternList[])();
SimplePatternList gPatterns = { rainbow, rainbowWithGlitter, confetti, sinelon, juggle, bpm };
#define ARRAY_SIZE(A) (sizeof(A) / sizeof((A)[0]))
void nextPattern() { gCurrentPatternNumber = (gCurrentPatternNumber + 1) % ARRAY_SIZE( gPatterns); }


// LOOP
void loop()
{
  gPatterns[gCurrentPatternNumber]();
  FastLED.show();  
  //FastLED.delay(1000/LEDS_FPS); 

  EVERY_N_MILLISECONDS( 20 ) { gHue++; } // slowly cycle the "base color" through the rainbow
  EVERY_N_SECONDS( 10 ) { nextPattern(); } // change patterns periodically
}
