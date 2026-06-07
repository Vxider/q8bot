#ifndef Q8BOT_PROTOCOL_H
#define Q8BOT_PROTOCOL_H

#include <Arduino.h>

enum MsgType : uint8_t {
  PAIRING,
  DATA,
  HEARTBEAT,
};

struct PairingMessage {
  uint8_t msgType = PAIRING;
  uint8_t id;
  uint8_t macAddr[6];
  uint8_t channel;
};

struct CharMessage {
  uint8_t msgType = DATA;
  uint8_t id;
  char data[100];
};

struct IntMessage {
  uint8_t msgType = DATA;
  uint8_t id;
  uint16_t data[100];
};

struct HeartbeatMessage {
  uint8_t msgType = HEARTBEAT;
  uint8_t id;
  uint32_t timestamp;
};

#endif
