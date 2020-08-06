/* ############ OPERATIONS AND CONTROL (O&C) - IMPORTANT ############
  
  Operations decisions made further down in the code - beware:
  (*1) Detect launch when relative altitude > *10 meters*
  (*2) *2 minutes* after launch, the radio will transmit GPS signals slowing down the sensor measurement rate drastically (this time should be chosen so that it has definitely landed - or do we want it before landing/ASAP incase everything breaks on impact?)
  (*3) Redundancy for radioStart if altimeter fails; transmit GPS coordinates if time since boot/setup > *60 minutes*. (Battery life = upto 30h).
 */
 
/*  ############################ NTX2B HARDWARE SETUP ###################################
    
   Arduino:    NTX2B:
   5V          VCC pin 5
   5V          EN  pin 4
   GND         GND pin 6
   Pin 9       TXD pin 7         
   
   1/4 whip antenna goes onto NTX2B pin 2         */


/* ############################# NEO-6M GPS HARDWARE SETUP ##############################
   
   Arduino         NEO-6M
   5V              Vcc
   GND             GND
   2  (= ss TX)    RX (labelled TX)  %% originally Arduino 4; changed to make space for microSD
   ~3 (= ss RX)    TX (labelled RX)                 */
 

/* ############################# BMP180 HARDWARE SETUP ##################################

  - (GND) to GND
  + (VDD) to 3.3V

  (WARNING: do not connect + to 5V or the sensor will be damaged!)

  You will also need to connect the I2C pins (SCL and SDA) to your
  Arduino. The pins are different on different Arduinos:

  Any Arduino pins labeled:  SDA  SCL
  Uno, Redboard, Pro:        A4   A5
  Mega2560, Due:             20   21
  Leonardo:                   2    3

  Leave the IO (VDDIO) pin unconnected. This pin is for connecting
  the BMP180 to systems with lower logic levels such as 1.8V */


/* ########################## SD CARD READ/WRITE SETUP ###################################

  This example shows how to read and write data to and from an SD card file
  The circuit:
  ** Vcc - 5V, 
  ** GND - GND
  * SD card attached to SPI bus as follows:
  ** MOSI - pin 11
  ** MISO - pin 12
  ** CLK - pin 13
  ** CS - pin 4 (for MKRZero SD: SDCARD_SS_PIN) */


/* ######################## DS3231 CLOCK SETUP ###########################################

  VCC - 5V
  GND - GND
  SDA - SDA
  SCL - SCL  ! Important: SDA/SCL can be conneted to the corresponding pins on the Arduino AT THE SAME TIME as the BMP180 because everything supports I2C */


#include <SFE_BMP180.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include "Sodaq_DS3231.h"
#include <string.h>
#include <util/crc16.h>
#include <TinyGPS++.h>
#include <SoftwareSerial.h>

// NTX2B
#define RADIOPIN 9 
char GPSDATASTRING[40];

// NEO-6M
static const byte RXPin = 2, TXPin = 3; // %%% RXPin is originally 4; changed to make space for microSD
static const uint32_t GPSBaud = 9600;
TinyGPSPlus gps; // The TinyGPS++ object
SoftwareSerial ss(RXPin, TXPin); // The serial connection to the GPS device

SFE_BMP180 BMP; // BMP180 object
double baseline_P, baseline_T; // Baseline pressure and temperature

// File SD_FILE; // MicroSD file object
String fileName = "COMPR1.txt"; // Filenames are limited to 8 characters

// uint32_t TIMESTAMP; // To store the Unix Epoch
uint32_t TIMEZERO; // To store the Unix Epoch upon startup


void setup()
{
  Serial.begin(9600);

  // Initialise the NTX2B transmitter       %%% Print setup success/fail
  pinMode(RADIOPIN,OUTPUT);
  setPwmFrequency(RADIOPIN, 1);
  
  // Initialise the NEO-6M GPS module      %%% Test/print setup success/fail
  ss.begin(GPSBaud);
  
  // Initialise the DS3231 clock: Wire.begin(), rtc.begin()
  Wire.begin();
  rtc.begin();
  DateTime now = rtc.now();
  TIMEZERO = now.getEpoch();
  // Initialise the BMP180 sensor (it is important to get calibration values stored on the device): BMP.begin()
  // Initialise the microSD card reader: SD.begin()
  if (!BMP.begin() || !SD.begin(4) || !rtc.begin()) while (true);
  Serial.println(F("OK"));
  
  // Get the baseline pressure:
  baseline_T = getTemperature();
  baseline_P = getPressure(baseline_T);

  // Create a unique file name. Note that only one file can be open at a time, so you have to close this one before opening another.
  byte fileNumber = 1;
  while (SD.exists(fileName)) {
    fileNumber += 1;
    fileName = "COMPR" + String(fileNumber) + ".txt"; 
  }


}


void loop()
{
  // O&C Variables
  static float OCaltitudes[2];          // Store the 2 newest altitude readings       %%% Could delete (and other O&C variables) after use to free memory
  static int OCcounter = 0;             // Count main loops/altitude readings         %%% Could get rid of to save memory
  static bool OChasLaunched = false;    // Detect launch
  static bool OCpastApogee = false;     // Detect apogee
  static uint32_t OCradioTimer;         // Save epoch at launch
  static bool OCradioStart = false;     //  %%% TRUE FOR TESTING %%% Start transmitting GPS coordinates, based on time since launch or (long, for redundancy:) time since boot/setup
  
  // Get BMP180 measurements
  double a,P,T;
  T = getTemperature();
  P = getPressure(T); // Get a new pressure reading
  a = BMP.altitude(P,baseline_P); // Show the relative altitude difference between the new reading and the baseline reading

  // Get the current date-time
  DateTime now = rtc.now(); 
  uint32_t TIMESTAMP = now.getEpoch();
  double T2; // Get the DS3231 temp. reading
  rtc.convertTemperature(); // Convert current temperature into registers
  T2 = rtc.getTemperature(); // Read registers and display the temperature


  // O&C Logic
  if ((a > 10) && !OChasLaunched) { // (*1) Detect launch when relative altitude > 10 meters
    OCradioTimer = TIMESTAMP;
    OChasLaunched = true;
  }

  OCaltitudes[OCcounter % 2] = a;
  
  if (OChasLaunched && !OCpastApogee) {
    if ((OCaltitudes[OCcounter % 2] - OCaltitudes[(OCcounter+1) % 2]) < 0) {  // If the altitude ever declines after launch
      OCpastApogee = true;
    }
  }

  if (OChasLaunched && !OCradioStart) {
    if ((TIMESTAMP-OCradioTimer) > 120) { // (*2) %%%DECISION%%% I.e. 2 minutes after launch, the radio will transmit GPS signals slowing down the sensor measurement rate drastically (this time should be chosen so that it has definitely landed - or do we want it before landing/ASAP incase everything breaks on impact?)
      OCradioStart = true;
    }
  }

  if (!OCradioStart && ((TIMESTAMP-TIMEZERO) > 3600)) {   // (*3) Redundancy for radioStart if altimeter fails; transmit GPS coordinates if time since boot/setup > 60 minutes. (Battery life = upto 30h). This number needs also be changed in the SD-write logic.
    OCradioStart = true;
  }
  
  OCcounter += 1;


  // NEO-6M:  This sketch displays information every time a new sentence is correctly encoded
  while(ss.available() > 0) {
    gps.encode(ss.read());
    if (gps.time.isUpdated()){

      // %%% Don't forget to save all this on SD instead of Serial.priting
      
      // NTX2B: Transmit Coordinates
      if (OCradioStart || ((TIMESTAMP-TIMEZERO) < 20)) {
        const char *dec_mask = "1< LAT %s LNG %s >0";   // Workaround for printf not having %f on Arduino 
        char charLAT[10];
        char charLNG[10];
        dtostrf(gps.location.lat(),9,6,charLAT);
        dtostrf(gps.location.lng(),9,6,charLNG);
        snprintf(GPSDATASTRING,40,dec_mask,charLAT,charLNG);
      
        unsigned int CHECKSUM = gps_CRC16_checksum(GPSDATASTRING); // Calculates the checksum for this datastring
        char checksum_str[6];
        sprintf(checksum_str, "*%04X\n", CHECKSUM);
        strcat(GPSDATASTRING,checksum_str);
      
        ss.end();     // Necessary end/begin around transmission to avoid overwhelming processor noise
        rtty_txstring (GPSDATASTRING);
        ss.begin(GPSBaud);        
      }
      
    }
  }
  
    
  // If the microSD file opens okay, write to it:
  static bool SDwriteLaunch = false;
  static bool SDwriteApogee = false;
  static bool SDwriteRadioStart = false;
  
  File SD_FILE = SD.open(fileName, FILE_WRITE);
  if (SD_FILE) {
    // Serial.print(F("Writing to file;"));   // %%% Consider keeping a few of these key status updates to check that everything is working on launch day
    if (OChasLaunched && !SDwriteLaunch) {
      SD_FILE.println(F("OPERATION         ### LAUNCH DETECTED ###"));
      SDwriteLaunch = true;
    }
    if (OCpastApogee && !SDwriteApogee) {
      SD_FILE.println(F("OPERATION         ### APOGEE DETECTED ###"));
      SDwriteApogee = true;
    }
    if (OCradioStart && !SDwriteRadioStart) {
      if ((TIMESTAMP-TIMEZERO) < 3600) {
        SD_FILE.println(F("OPERATION         ### GPS COORDINATES TRANSMITTING ###"));
      }
      else {
        SD_FILE.println(F("OPERATION         ### SAFETY START OF GPS COORDINATES TRANSMISSION ###"));
      }
      SDwriteRadioStart = true;
    }
    SD_FILE.print(F("CLOCK DATA        Seconds since Unix Epoch: "));
    SD_FILE.print(TIMESTAMP, DEC);
    SD_FILE.print(F(", Seconds running: "));
    SD_FILE.print(TIMESTAMP - TIMEZERO);
    SD_FILE.print(F(". Temperature(2): "));
    SD_FILE.print(T2,1);
    SD_FILE.println(F(" C"));
    SD_FILE.print(F("ALTIMETER DATA    Absolute pressure: "));
    SD_FILE.print(P,0);
    SD_FILE.print(F(" mb.  Relative altitude: "));
    if (a >= 0.0) SD_FILE.print(F(" ")); // Add a space for positive numbers
    SD_FILE.print(a,2);
    SD_FILE.print(F(" meters, "));
    if (a >= 0.0) SD_FILE.print(F(" ")); // Add a space for positive numbers
    SD_FILE.print(a*3.28084,1);
    SD_FILE.print(F(" feet.  Temperature: "));
    SD_FILE.print(T,1);
    SD_FILE.println(F(" C"));
    SD_FILE.close(); // Close the file
    // Serial.println(F(" Writing complete.\n"));
  } else {
    // Serial.println(F("Error opening the microSD file\n")); // If the file didn't open, print an error
  }

  // Loop delay time
  delay(10);
}


double getTemperature()
{
  char status;
  double T;

  // Start a temperature measurement:
  // If request is successful, the number of ms to wait is returned.
  // If request is unsuccessful, 0 is returned.

  status = BMP.startTemperature();
  if (status != 0)
  {
    // Wait for the measurement to complete:

    delay(status);

    // Retrieve the completed temperature measurement:
    // Note that the measurement is stored in the variable T.
    // Use '&T' to provide the address of T to the function.
    // Function returns 1 if successful, 0 if failure.

    status = BMP.getTemperature(T);
   
     if (status != 0){
      return T;
     }
  }
      
}


double getPressure(double T)
{
  char status;
  double P;

  // You must first get a temperature measurement to perform a pressure reading. 
  // Start a pressure measurement:
  // The parameter is the oversampling setting, from 0 to 3 (highest res, longest wait).
  // If request is successful, the number of ms to wait is returned.
  // If request is unsuccessful, 0 is returned.

  status = BMP.startPressure(3);
  if (status != 0)
  {
    // Wait for the measurement to complete:
    delay(status);

    // Retrieve the completed pressure measurement:
    // Note that the measurement is stored in the variable P.
    // Use '&P' to provide the address of P.
    // Note also that the function requires the previous temperature measurement (T).
    // (If temperature is stable, you can do one temperature measurement for a number of pressure measurements.)
    // Function returns 1 if successful, 0 if failure.

    status = BMP.getPressure(P,T);
    if (status != 0)
    {
      return(P);
    }
  }

}


// NTX2B: RTTY functions (BEGIN)
void rtty_txstring (char * string) {
// Simple function to sent a char at a time to rtty_txbyte function. NB Each char is one byte (8 Bits)
char c;
c = *string++;
while ( c != '\0') {
 rtty_txbyte (c);
 c = *string++;
 }
}

void rtty_txbyte (char c) {
// Simple function to sent each bit of a char to rtty_txbit function. NB The bits are sent Least Significant Bit first. All chars should be preceded with a 0 and proceded with a 1. 0 = Start bit; 1 = Stop bit 
int i;
rtty_txbit (0); // Start bit

// Send bits for for char LSB first
for (i=0;i<7;i++) { // Change this here 7 or 8 for ASCII-7 / ASCII-8
 if (c & 1) rtty_txbit(1);
else rtty_txbit(0);
c = c >> 1;
}
 
rtty_txbit (1); // Stop bit
 rtty_txbit (1); // Stop bit
}
 
void rtty_txbit (int bit) {
 if (bit) {
 // high
 analogWrite(RADIOPIN,110);
 }
 else {
 // low
 analogWrite(RADIOPIN,100);
}
 
// delayMicroseconds(3370); // 300 baud
 delayMicroseconds(10000); // For 50 Baud uncomment this and the line below.
 delayMicroseconds(10150); // You can't do 20150 it just doesn't work as the
 // largest value that will produce an accurate delay is 16383
 // See : http://arduino.cc/en/Reference/DelayMicroseconds
 
}
 
uint16_t gps_CRC16_checksum (char *string) {
 size_t i;
 uint16_t crc;
 uint8_t c;
 
crc = 0xFFFF;
 
// Calculate checksum ignoring the first two $s
 for (i = 2; i < strlen(string); i++) {
 c = string[i];
 crc = _crc_xmodem_update (crc, c);
 }
 
return crc;
}
 
void setPwmFrequency(int pin, int divisor) {
 byte mode;
 if(pin == 5 || pin == 6 || pin == 9 || pin == 10) {
 switch(divisor) {
 case 1:
 mode = 0x01;
 break;
 case 8:
 mode = 0x02;
 break;
 case 64:
 mode = 0x03;
 break;
 case 256:
 mode = 0x04;
 break;
 case 1024:
 mode = 0x05;
 break;
 default:
 return;
 }
 if(pin == 5 || pin == 6) {
 TCCR0B = TCCR0B & 0b11111000 | mode;
 }
 else {
 TCCR1B = TCCR1B & 0b11111000 | mode;
 }
 }
 else if(pin == 3 || pin == 11) {
 switch(divisor) {
 case 1:
 mode = 0x01;
 break;
 case 8:
 mode = 0x02;
 break;
 case 32:
 mode = 0x03;
 break;
 case 64:
 mode = 0x04;
 break;
 case 128:
 mode = 0x05;
 break;
 case 256:
 mode = 0x06;
 break;
 case 1024:
 mode = 0x7;
 break;
 default:
 return;
 }
 TCCR2B = TCCR2B & 0b11111000 | mode;
 }
}
// NTX2B: RTTY functions (END)
