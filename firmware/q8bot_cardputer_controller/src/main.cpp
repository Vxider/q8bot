#include <Arduino.h>
#include <M5Cardputer.h>
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <math.h>

#include "macStorage.h"
#include "protocol.h"

static constexpr int kChannel = 1;
static constexpr uint32_t kHeartbeatIntervalMs = 2000;
static constexpr uint32_t kHeartbeatTimeoutMs = 5000;
static constexpr uint32_t kControlPeriodMs = 20;
static constexpr uint32_t kUiPeriodMs = 100;
static constexpr uint32_t kBatteryPeriodMs = 60000;
static constexpr int kMaxTrajectoryLen = 90;
static constexpr uint16_t kBg = 0x0000;
static constexpr uint16_t kPanel = 0x18E3;
static constexpr uint16_t kText = 0xFFFF;
static constexpr uint16_t kMuted = 0x8410;
static constexpr uint16_t kGreen = 0x07E0;
static constexpr uint16_t kYellow = 0xFFE0;
static constexpr uint16_t kRed = 0xF800;
static constexpr uint16_t kBlue = 0x05FF;

struct Telemetry {
  int batteryPct = -1;
  uint16_t jointRaw[16] = {};
  bool hasJointData = false;
  uint32_t lastDataMs = 0;
};

struct GaitDef {
  const char* name;
  float x0;
  float y0;
  float xRange;
  float yRange;
  float yRange2;
  int s1Count;
  int s2Count;
};

enum Direction : uint8_t {
  DIR_NONE,
  DIR_F,
  DIR_B,
  DIR_L,
  DIR_R,
  DIR_FL,
  DIR_FR,
};

enum UiPage : uint8_t {
  PAGE_CONTROL,
  PAGE_TELEMETRY,
};

static const GaitDef kGaits[] = {
  {"TROT", 9.75f, 43.36f, 40.0f, 20.0f, 0.0f, 15, 30},
  {"HIGH", 9.75f, 60.0f, 20.0f, 10.0f, 0.0f, 15, 30},
  {"LOW", 9.75f, 25.0f, 20.0f, 10.0f, 0.0f, 15, 30},
  {"FAST", 9.75f, 43.36f, 50.0f, 20.0f, 0.0f, 12, 24},
};

static const float kCenterDist = 19.5f;
static const float kL1 = 25.0f;
static const float kL2 = 40.0f;
static const float kIdlePos[8] = {30, 150, 30, 150, 30, 150, 30, 150};
static const float kGreet[][8] = {
  {-90, 45, -90, 45, -90, 45, -90, 45},
  {0, 45, 0, 45, 0, 45, 0, 45},
  {-45, 45, -45, 45, 50, 75, 50, 75},
  {45, 90, -45, 45, 50, 75, 50, 75},
  {-45, 45, 45, 90, 50, 75, 50, 75},
  {45, 90, -45, 45, 50, 75, 50, 75},
  {-45, 45, 45, 90, 50, 75, 50, 75},
  {45, 90, -45, 45, 50, 75, 50, 75},
  {-90, 45, -90, 45, -90, 45, -90, 45},
};
static const uint16_t kGreetDur[] = {1000, 1000, 500, 200, 200, 200, 200, 200, 500};
static const float kRange[][8] = {
  {100, 80, 100, 80, 100, 80, 100, 80},
  {0, 45, 0, 45, 0, 45, 0, 45},
  {-90, 45, -90, 45, -90, 45, -90, 45},
  {-20, 200, -20, 200, -20, 200, -20, 200},
  {130, 270, 130, 270, 130, 270, 130, 270},
  {130, 180, 130, 180, 130, 180, 130, 180},
  {100, 80, 100, 80, 100, 80, 100, 80},
  {-20, 200, -20, 200, -20, 200, -20, 200},
  {30, 150, 30, 150, 30, 150, 30, 150},
};

macStorage storage;
Telemetry telemetry;
PairingMessage pairingData;
CharMessage sendMsg;
HeartbeatMessage heartbeatMsg;
uint8_t serverMac[6] = {};
uint8_t clientMac[6] = {};
uint8_t broadcastMac[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
volatile bool paired = false;
volatile bool needsUiRefresh = true;
uint32_t lastHeartbeatSent = 0;
uint32_t lastHeartbeatReceived = 0;
uint32_t lastPairAttempt = 0;
uint32_t lastControlTick = 0;
uint32_t lastUiTick = 0;
uint32_t lastBatteryRequest = 0;
uint32_t actionLockoutUntil = 0;
int gaitIndex = 0;
int phaseIndex = 0;
Direction activeDirection = DIR_NONE;
UiPage uiPage = PAGE_CONTROL;
bool torqueEnabled = true;
bool recordNextMovement = false;
char statusLine[48] = "Booting";
char lastCommand[24] = "idle";

static float baseForward[3][kMaxTrajectoryLen][2];
static float baseBackward[3][kMaxTrajectoryLen][2];
static int trajectoryLen = 0;

bool keyDown(char key) {
  return M5Cardputer.Keyboard.isKeyPressed(key);
}

bool keyDownAlias(char lower, char upper) {
  return keyDown(lower) || keyDown(upper);
}

void setStatus(const char* msg) {
  snprintf(statusLine, sizeof(statusLine), "%s", msg);
  needsUiRefresh = true;
}

void addPeer(const uint8_t* mac) {
  esp_now_peer_info_t peer = {};
  memcpy(peer.peer_addr, mac, 6);
  peer.channel = kChannel;
  peer.encrypt = false;
  if (!esp_now_is_peer_exist(mac)) {
    esp_now_add_peer(&peer);
  }
}

bool sendCommand(const char* cmd) {
  if (!paired) return false;
  snprintf(sendMsg.data, sizeof(sendMsg.data), "%s", cmd);
  sendMsg.msgType = DATA;
  sendMsg.id = 1;
  return esp_now_send(serverMac, reinterpret_cast<uint8_t*>(&sendMsg), sizeof(sendMsg)) == ESP_OK;
}

void formatMoveCommand(const float pos[8], uint16_t dur, uint8_t special, char* out, size_t outLen) {
  snprintf(out, outLen,
           "%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%u,%u,%u;",
           pos[0], pos[1], pos[2], pos[3], pos[4], pos[5], pos[6], pos[7],
           special, dur, torqueEnabled ? 1 : 0);
}

void sendMove(const float pos[8], uint16_t dur = 0, uint8_t special = 0) {
  char cmd[100];
  formatMoveCommand(pos, dur, special, cmd, sizeof(cmd));
  sendCommand(cmd);
}

void requestBattery() {
  if (sendCommand("0,0,0,0,0,0,0,0,1,0,0;")) {
    lastBatteryRequest = millis();
    setStatus("Battery requested");
  }
}

void requestJointTelemetry(bool finish = false) {
  if (sendCommand(finish ? "0,0,0,0,0,0,0,0,3,0,1;" : "0,0,0,0,0,0,0,0,2,0,1;")) {
    setStatus(finish ? "Telemetry pull" : "Telemetry sample");
  }
}

void sendJump() {
  if (sendCommand("0,0,0,0,0,0,0,0,4,0,0;")) {
    snprintf(lastCommand, sizeof(lastCommand), "jump");
    setStatus("Jump");
  }
}

void unpair() {
  if (paired) esp_now_del_peer(serverMac);
  storage.clearPeerMAC();
  memset(serverMac, 0, sizeof(serverMac));
  paired = false;
  lastPairAttempt = 0;
  setStatus("Pairing reset");
}

void ikSolve(float x, float y, float& q1, float& q2) {
  float c1 = sqrtf((x - kCenterDist) * (x - kCenterDist) + y * y);
  float c2 = sqrtf(x * x + y * y);
  float a1 = acosf((c1 * c1 + kCenterDist * kCenterDist - c2 * c2) / (2.0f * c1 * kCenterDist));
  float a2 = acosf((c2 * c2 + kCenterDist * kCenterDist - c1 * c1) / (2.0f * c2 * kCenterDist));
  float b1 = acosf((c1 * c1 + kL1 * kL1 - kL2 * kL2) / (2.0f * c1 * kL1));
  float b2 = acosf((c2 * c2 + kL1 * kL1 - kL2 * kL2) / (2.0f * c2 * kL1));
  q1 = (PI - a1 - b1) * 180.0f / PI;
  q2 = (a2 + b2) * 180.0f / PI;
  q1 = roundf(q1 * 10.0f) / 10.0f;
  q2 = roundf(q2 * 10.0f) / 10.0f;
}

void generateBaseTrajectory(const GaitDef& gait, float scale, float out[kMaxTrajectoryLen][2]) {
  float xStart = gait.x0 - (gait.xRange * scale) / 2.0f;
  float xLiftStep = (gait.xRange * scale) / gait.s1Count;
  float xDownStep = (gait.xRange * scale) / gait.s2Count;
  float x = xStart;
  trajectoryLen = gait.s1Count + gait.s2Count;
  if (trajectoryLen > kMaxTrajectoryLen) trajectoryLen = kMaxTrajectoryLen;

  for (int i = 0; i < trajectoryLen; ++i) {
    float y;
    if (i < gait.s1Count) {
      x += xLiftStep;
      y = gait.y0 - sinf((i + 1) * PI / gait.s1Count) * gait.yRange;
    } else {
      x -= xDownStep;
      y = gait.y0 + sinf((i - gait.s1Count + 1) * PI / gait.s2Count) * gait.yRange2;
    }
    ikSolve(x, y, out[i][0], out[i][1]);
  }
}

void loadGait(int index) {
  const GaitDef& gait = kGaits[index];
  generateBaseTrajectory(gait, 1.0f, baseForward[0]);
  generateBaseTrajectory(gait, 0.75f, baseForward[1]);
  generateBaseTrajectory(gait, 0.5f, baseForward[2]);
  generateBaseTrajectory(gait, -1.0f, baseBackward[0]);
  generateBaseTrajectory(gait, -0.75f, baseBackward[1]);
  generateBaseTrajectory(gait, -0.5f, baseBackward[2]);
  phaseIndex = 0;
  snprintf(statusLine, sizeof(statusLine), "Gait %s", gait.name);
  needsUiRefresh = true;
}

int shiftedIndex(int baseIndex) {
  int shift = trajectoryLen / 2;
  return (baseIndex + shift) % trajectoryLen;
}

void copyLeg(const float leg[2], float* out) {
  out[0] = leg[0];
  out[1] = leg[1];
}

void trajectoryPoint(Direction dir, float out[8]) {
  int i = phaseIndex % trajectoryLen;
  int p = shiftedIndex(i);

  switch (dir) {
    case DIR_F:
      copyLeg(baseForward[0][i], &out[0]);
      copyLeg(baseForward[0][p], &out[2]);
      copyLeg(baseForward[0][p], &out[4]);
      copyLeg(baseForward[0][i], &out[6]);
      break;
    case DIR_B:
      copyLeg(baseBackward[0][i], &out[0]);
      copyLeg(baseBackward[0][p], &out[2]);
      copyLeg(baseBackward[0][p], &out[4]);
      copyLeg(baseBackward[0][i], &out[6]);
      break;
    case DIR_L:
      copyLeg(baseBackward[0][i], &out[0]);
      copyLeg(baseForward[0][p], &out[2]);
      copyLeg(baseBackward[0][p], &out[4]);
      copyLeg(baseForward[0][i], &out[6]);
      break;
    case DIR_R:
      copyLeg(baseForward[0][i], &out[0]);
      copyLeg(baseBackward[0][p], &out[2]);
      copyLeg(baseForward[0][p], &out[4]);
      copyLeg(baseBackward[0][i], &out[6]);
      break;
    case DIR_FL:
      copyLeg(baseForward[1][i], &out[0]);
      copyLeg(baseForward[0][p], &out[2]);
      copyLeg(baseForward[1][p], &out[4]);
      copyLeg(baseForward[0][i], &out[6]);
      break;
    case DIR_FR:
      copyLeg(baseForward[0][i], &out[0]);
      copyLeg(baseForward[1][p], &out[2]);
      copyLeg(baseForward[0][p], &out[4]);
      copyLeg(baseForward[1][i], &out[6]);
      break;
    default:
      memcpy(out, kIdlePos, sizeof(kIdlePos));
      break;
  }
}

Direction readDirection() {
  if (keyDownAlias('w', 'W')) return DIR_F;
  if (keyDownAlias('s', 'S')) return DIR_B;
  if (keyDownAlias('a', 'A')) return DIR_L;
  if (keyDownAlias('d', 'D')) return DIR_R;
  if (keyDownAlias('q', 'Q')) return DIR_FL;
  if (keyDownAlias('e', 'E')) return DIR_FR;
  return DIR_NONE;
}

const char* directionName(Direction dir) {
  switch (dir) {
    case DIR_F: return "forward";
    case DIR_B: return "back";
    case DIR_L: return "left";
    case DIR_R: return "right";
    case DIR_FL: return "f-left";
    case DIR_FR: return "f-right";
    default: return "idle";
  }
}

void drawBattery(int x, int y, int pct) {
  auto& d = M5Cardputer.Display;
  d.drawRect(x, y, 28, 12, kText);
  d.fillRect(x + 28, y + 3, 3, 6, kText);
  int fill = pct < 0 ? 0 : map(constrain(pct, 0, 100), 0, 100, 0, 24);
  uint16_t color = pct < 0 ? kMuted : (pct < 20 ? kRed : (pct < 45 ? kYellow : kGreen));
  d.fillRect(x + 2, y + 2, fill, 8, color);
}

void drawHeader() {
  auto& d = M5Cardputer.Display;
  d.fillRect(0, 0, 240, 20, paired ? 0x0320 : 0x3000);
  d.setTextColor(kText);
  d.setTextSize(1);
  d.setCursor(4, 6);
  d.printf("Q8bot %s", paired ? "LINK" : "PAIR");
  d.setCursor(80, 6);
  d.printf("%s", kGaits[gaitIndex].name);
  d.setCursor(134, 6);
  d.printf("%s", torqueEnabled ? "TQ" : "OFF");
  drawBattery(202, 4, telemetry.batteryPct);
}

void drawDpad(int cx, int cy) {
  auto& d = M5Cardputer.Display;
  uint16_t c = activeDirection == DIR_NONE ? kMuted : kBlue;
  d.drawRoundRect(cx - 13, cy - 37, 26, 26, 4, activeDirection == DIR_F ? kGreen : kPanel);
  d.drawRoundRect(cx - 13, cy + 11, 26, 26, 4, activeDirection == DIR_B ? kGreen : kPanel);
  d.drawRoundRect(cx - 37, cy - 13, 26, 26, 4, activeDirection == DIR_L ? kGreen : kPanel);
  d.drawRoundRect(cx + 11, cy - 13, 26, 26, 4, activeDirection == DIR_R ? kGreen : kPanel);
  d.fillCircle(cx, cy, 10, c);
  d.setTextColor(kText);
  d.setCursor(cx - 3, cy - 29); d.print("W");
  d.setCursor(cx - 3, cy + 20); d.print("S");
  d.setCursor(cx - 29, cy - 4); d.print("A");
  d.setCursor(cx + 20, cy - 4); d.print("D");
  d.setCursor(cx - 44, cy - 37); d.print("Q");
  d.setCursor(cx + 36, cy - 37); d.print("E");
}

void drawActionChip(int x, int y, const char* key, const char* label, uint16_t color) {
  auto& d = M5Cardputer.Display;
  d.drawRoundRect(x, y, 48, 18, 4, color);
  d.fillCircle(x + 9, y + 9, 5, color);
  d.setTextColor(kText);
  d.setCursor(x + 18, y + 5);
  d.print(key);
  d.setTextColor(kMuted);
  d.setCursor(x + 4, y + 22);
  d.print(label);
}

void drawControlPage() {
  auto& d = M5Cardputer.Display;
  d.fillScreen(kBg);
  drawHeader();
  d.setTextColor(kText);
  d.setTextSize(1);
  d.setCursor(6, 28);
  d.printf("Move");
  drawDpad(55, 84);

  drawActionChip(112, 30, "J", "Jump", kRed);
  drawActionChip(170, 30, "G", "Gait", kYellow);
  drawActionChip(112, 78, "H", "Greet", kGreen);
  drawActionChip(170, 78, "B", "Batt", kBlue);

  d.drawFastHLine(0, 124, 240, kPanel);
  d.setTextColor(kText);
  d.setCursor(4, 126);
  d.printf("%s", statusLine);
  d.setTextColor(kMuted);
  d.setCursor(150, 126);
  d.printf("TAB telem");
}

void drawTelemetryPage() {
  auto& d = M5Cardputer.Display;
  d.fillScreen(kBg);
  drawHeader();
  d.setTextColor(kText);
  d.setCursor(6, 28);
  d.printf("Telemetry");
  d.setTextColor(kMuted);
  d.setCursor(6, 46);
  d.printf("Batt: ");
  d.setTextColor(kText);
  if (telemetry.batteryPct >= 0) d.printf("%d%%", telemetry.batteryPct);
  else d.printf("--");

  d.setTextColor(kMuted);
  d.setCursor(6, 62);
  d.printf("Body: roll --  pitch --");
  d.setCursor(6, 78);
  d.printf("IMU not present in robot fw");

  d.setCursor(6, 96);
  d.printf("Joints:");
  d.setTextColor(kText);
  d.setCursor(52, 96);
  if (telemetry.hasJointData) {
    for (int i = 0; i < 4; ++i) {
      d.printf("%u ", telemetry.jointRaw[i * 2 + 1]);
    }
  } else {
    d.printf("press Z");
  }

  d.setTextColor(kMuted);
  d.setCursor(4, 126);
  d.printf("B batt  Z rec  X pull  TAB ctrl");
}

void drawUi() {
  if (uiPage == PAGE_CONTROL) drawControlPage();
  else drawTelemetryPage();
  needsUiRefresh = false;
}

void onRecv(const uint8_t* mac, const uint8_t* data, int len) {
  if (len < 1 || len > 250) return;
  uint8_t type = data[0];
  if (type == PAIRING && len >= static_cast<int>(sizeof(PairingMessage))) {
    memcpy(&pairingData, data, sizeof(PairingMessage));
    memcpy(serverMac, mac, 6);
    addPeer(serverMac);
    paired = true;
    lastHeartbeatReceived = millis();
    storage.savePeerMAC(serverMac);
    setStatus("Paired");
  } else if (type == HEARTBEAT && len >= static_cast<int>(sizeof(HeartbeatMessage))) {
    lastHeartbeatReceived = millis();
    needsUiRefresh = true;
  } else if (type == DATA && len >= static_cast<int>(sizeof(IntMessage))) {
    IntMessage msg;
    memcpy(&msg, data, sizeof(IntMessage));
    telemetry.lastDataMs = millis();
    if (msg.data[0] <= 100 && msg.data[1] == 0 && msg.data[2] == 0) {
      telemetry.batteryPct = msg.data[0];
      setStatus("Battery updated");
    } else {
      memcpy(telemetry.jointRaw, msg.data, sizeof(telemetry.jointRaw));
      telemetry.hasJointData = true;
      setStatus("Telemetry updated");
    }
    needsUiRefresh = true;
  }
}

void onDataSent(const uint8_t*, esp_now_send_status_t) {}

void sendPairBroadcast() {
  PairingMessage msg;
  msg.msgType = PAIRING;
  msg.id = 1;
  memcpy(msg.macAddr, clientMac, 6);
  msg.channel = kChannel;
  esp_now_send(broadcastMac, reinterpret_cast<uint8_t*>(&msg), sizeof(msg));
}

void updatePairing() {
  uint32_t now = millis();
  if (!paired && now - lastPairAttempt > 2000) {
    lastPairAttempt = now;
    sendPairBroadcast();
    setStatus("Pairing broadcast");
  }
}

void updateHeartbeat() {
  uint32_t now = millis();
  if (!paired) return;
  if (now - lastHeartbeatSent > kHeartbeatIntervalMs) {
    heartbeatMsg.msgType = HEARTBEAT;
    heartbeatMsg.id = 1;
    heartbeatMsg.timestamp = now;
    lastHeartbeatSent = now;
    esp_now_send(serverMac, reinterpret_cast<uint8_t*>(&heartbeatMsg), sizeof(heartbeatMsg));
  }
#ifndef PERMANENT_PAIRING_MODE
  if (now - lastHeartbeatReceived > kHeartbeatTimeoutMs) {
    paired = false;
    setStatus("Heartbeat timeout");
  }
#endif
}

void runScriptedMotion(const float (*steps)[8], const uint16_t* durations, int count) {
  for (int i = 0; i < count; ++i) {
    sendMove(steps[i], durations[i], 0);
    drawUi();
    delay(durations[i] + 120);
  }
}

void handleActions() {
  uint32_t now = millis();
  if (now < actionLockoutUntil) return;

  if (keyDown(0x09)) {
    uiPage = uiPage == PAGE_CONTROL ? PAGE_TELEMETRY : PAGE_CONTROL;
    needsUiRefresh = true;
    actionLockoutUntil = now + 250;
  } else if (keyDownAlias('p', 'P')) {
    unpair();
    actionLockoutUntil = now + 500;
  } else if (keyDownAlias('b', 'B')) {
    requestBattery();
    actionLockoutUntil = now + 500;
  } else if (keyDownAlias('j', 'J')) {
    sendJump();
    actionLockoutUntil = now + 1200;
  } else if (keyDownAlias('g', 'G')) {
    gaitIndex = (gaitIndex + 1) % (sizeof(kGaits) / sizeof(kGaits[0]));
    loadGait(gaitIndex);
    sendMove(kIdlePos, 500, 0);
    actionLockoutUntil = now + 500;
  } else if (keyDownAlias('r', 'R')) {
    phaseIndex = 0;
    activeDirection = DIR_NONE;
    sendMove(kIdlePos, 500, 0);
    setStatus("Gait reset");
    actionLockoutUntil = now + 500;
  } else if (keyDownAlias('h', 'H')) {
    setStatus("Greet");
    runScriptedMotion(kGreet, kGreetDur, sizeof(kGreet) / sizeof(kGreet[0]));
    actionLockoutUntil = millis() + 500;
  } else if (keyDownAlias('c', 'C')) {
    setStatus("Range demo");
    uint16_t durations[sizeof(kRange) / sizeof(kRange[0])];
    for (size_t i = 0; i < sizeof(durations) / sizeof(durations[0]); ++i) durations[i] = 1000;
    runScriptedMotion(kRange, durations, sizeof(kRange) / sizeof(kRange[0]));
    actionLockoutUntil = millis() + 500;
  } else if (keyDownAlias('z', 'Z')) {
    recordNextMovement = !recordNextMovement;
    requestJointTelemetry(false);
    snprintf(statusLine, sizeof(statusLine), recordNextMovement ? "Record on" : "Record off");
    actionLockoutUntil = now + 500;
  } else if (keyDownAlias('x', 'X')) {
    requestJointTelemetry(true);
    actionLockoutUntil = now + 500;
  } else if (keyDownAlias('t', 'T')) {
    torqueEnabled = !torqueEnabled;
    sendMove(kIdlePos, 0, 0);
    setStatus(torqueEnabled ? "Torque on" : "Torque off");
    actionLockoutUntil = now + 500;
  }
}

void updateControl() {
  uint32_t now = millis();
  if (!paired || now - lastControlTick < kControlPeriodMs) return;
  lastControlTick = now;

  Direction dir = readDirection();
  if (dir != activeDirection) {
    activeDirection = dir;
    snprintf(lastCommand, sizeof(lastCommand), "%s", directionName(dir));
    setStatus(lastCommand);
    if (dir == DIR_NONE) {
      sendMove(kIdlePos, 0, recordNextMovement ? 3 : 0);
      recordNextMovement = false;
    }
  }

  if (dir != DIR_NONE) {
    float pos[8];
    trajectoryPoint(dir, pos);
    sendMove(pos, 0, recordNextMovement ? 2 : 0);
    phaseIndex = (phaseIndex + 1) % trajectoryLen;
  }
}

void setupEspNow() {
  WiFi.mode(WIFI_STA);
  WiFi.macAddress(clientMac);
  esp_wifi_start();
  esp_wifi_set_promiscuous(true);
  esp_wifi_set_channel(kChannel, WIFI_SECOND_CHAN_NONE);
  esp_wifi_set_promiscuous(false);

  if (esp_now_init() != ESP_OK) {
    setStatus("ESP-NOW init failed");
    return;
  }
  esp_now_register_recv_cb(onRecv);
  esp_now_register_send_cb(onDataSent);
  addPeer(broadcastMac);

  if (storage.loadPeerMAC(serverMac)) {
    addPeer(serverMac);
    paired = true;
    lastHeartbeatReceived = millis();
    setStatus("Saved robot MAC");
  } else {
    setStatus("Ready to pair");
  }
}

void setup() {
  auto cfg = M5.config();
  M5Cardputer.begin(cfg, true);
  Serial.begin(115200);
  M5Cardputer.Display.setRotation(1);
  M5Cardputer.Display.setTextFont(1);
  M5Cardputer.Display.fillScreen(kBg);
  M5Cardputer.Display.setTextColor(kText);
  M5Cardputer.Display.setCursor(8, 8);
  M5Cardputer.Display.print("Q8bot Cardputer");

  loadGait(gaitIndex);
  setupEspNow();
  sendMove(kIdlePos, 1000, 0);
  requestBattery();
  drawUi();
}

void loop() {
  M5Cardputer.update();
  handleActions();
  updatePairing();
  updateHeartbeat();
  updateControl();

  uint32_t now = millis();
  if (paired && now - lastBatteryRequest > kBatteryPeriodMs) {
    requestBattery();
  }

  if (needsUiRefresh || now - lastUiTick > kUiPeriodMs) {
    lastUiTick = now;
    drawUi();
  }

  delay(2);
}
