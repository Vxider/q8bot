#ifndef MACSTORAGE_H
#define MACSTORAGE_H

#include <Arduino.h>
#include <Preferences.h>

class macStorage {
private:
  Preferences _prefs;
  const char* _namespace = "q8bot";
  const char* _macKey = "peerMAC";

public:
  macStorage();
  bool loadPeerMAC(uint8_t* mac);
  void savePeerMAC(const uint8_t* mac);
  void clearPeerMAC();
};

#endif
