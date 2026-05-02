#include <Wire.h>

void setup() {
Wire.begin(0x27);   // Arduino as SLAVE
Wire.onReceive(receiveEvent);
Serial.begin(115200);
Serial.println("I2C Slave Ready");
}

void loop() {}

void receiveEvent(int n) {
Serial.print("Received: ");
while (Wire.available()) {
Serial.print("0x");
Serial.print(Wire.read(), HEX);
Serial.print(" ");
}
Serial.println();
}
