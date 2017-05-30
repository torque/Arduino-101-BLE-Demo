#include <CurieBLE.h>
#include <CurieIMU.h>

const int ledPin = LED_BUILTIN;

BLEService customService( "BEEF0000-0000-0000-0000-00000000ACCE" );

// BLEBoolCharacteristic throws a linker error because someone forgot to
// implement the constructor. Also, the typed characteristics aren't really very
// useful for the callback-based update approach because the callback signature
// only accepts the base BLECharacteristic type, so the value has to be manually
// cast to the expected type anyway.
BLETypedCharacteristic<bool> ledChar( "BEEF0001-0000-0000-0000-0000000001ED", BLERead | BLEWrite );
BLECharacteristic accelChar( "BEEF0001-0000-0000-0000-00000000ACCE", BLERead | BLENotify, "0,0,0" );

void setup( ) {
  Serial.begin( 115200 );
  Serial.println( "Starting up..." );
  pinMode( ledPin, OUTPUT );

  CurieIMU.begin( );
  CurieIMU.setAccelerometerRange( 2 );
  Serial.println( "IMU started." );

  BLE.begin( );

  BLE.setLocalName( "BTDemo" );
  BLE.setAdvertisedService(customService);

  customService.addCharacteristic(accelChar);
  customService.addCharacteristic(ledChar);

  // Add our service.
  BLE.addService(customService);
  // These do nothing other than provide some debug logging.
  BLE.setEventHandler(BLEConnected, logCentralConnect);
  BLE.setEventHandler(BLEDisconnected, logCentralDisconnect);

  ledChar.setEventHandler(BLEWritten, ledCharChanged);
  ledChar.setValue(false);

  // Advertise.
  BLE.advertise( );

  Serial.println( "BLE waiting for central connection." );
}

void loop( ) {
  static unsigned long lastWrite = 0;
  while ( BLE.central( ) ) {
    unsigned long now = millis( );
    BLE.poll( );
    if ( now - lastWrite > 100 ) {
      lastWrite = now;
      float x, y, z;
      CurieIMU.readAccelerometerScaled(x, y, z);
      String packedData = String(x, 3) + "," + String(y, 3) + "," + String(z, 3);
      accelChar.setValue( packedData.c_str( ) );
    }
  }
}

void logCentralConnect(BLEDevice central) {
  Serial.println( "Central connected: " + central.address( ) );
}

void logCentralDisconnect(BLEDevice central) {
  Serial.print( "Central disconnected: " + central.address( ) );
}

void ledCharChanged(BLEDevice central, BLECharacteristic characteristic) {
  bool value = static_cast<bool>(*characteristic.value( ));
  Serial.println( "Led value updated to: " + String(value) );
  digitalWrite( ledPin, value );
}
