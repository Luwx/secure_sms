#include <SoftwareSerial.h>
#include <string.h>
#include <EEPROM.h>

// Adjust TX and RX pins as per your setup
#define SIM800_TX_PIN 10
#define SIM800_RX_PIN 11

#define EEPROM_USER_COUNTERS_ADDRESS 0

#define MAX_USERS 5

struct UserCounter {
  char phoneNumber[5];
  uint16_t lastCounter;
};

UserCounter userCounters[MAX_USERS];

SoftwareSerial sim800l(SIM800_TX_PIN, SIM800_RX_PIN); // RX, TX

// Buffers
char sim800lBuffer[128]; // Buffer for incoming data from SIM800L
int sim800lBufferPos = 0;

void initializeSIM800L() {
  sim800l.begin(9600);
  delay(1000);

  // Setar modo de SMS
  sim800l.println("AT+CMGF=1");
  delay(500);
  flushSIM800L();

  // Flag para que notificacoes SMS sejam enviadas para a porta serial
  sim800l.println(F("AT+CNMI=1,2,0,0,0"));
  delay(500);
  flushSIM800L();

  // carregar usuarios cadastrados
  loadUserCountersFromEEPROM();
}

void sendSMS(char* message, char* address) {
   // Start SMS send command
  sim800l.print(F("AT+CMGS=\""));
  sim800l.print(address);
  sim800l.println("\"\r");
  delay(500);
  sim800l.print(message);
  delay(200);
  sim800l.println((char)26);
}

void checkForSMS() {
  while (sim800l.available()) {
    char c = sim800l.read();

    Serial.print(c);

    // Armazena caracteres ate que uma nova linha seja encontrada
    if (c == '\n' || sim800lBufferPos >= sizeof(sim800lBuffer) - 1) {
      sim800lBuffer[sim800lBufferPos] = '\0'; // Null-terminate the string

      // Check if the line contains "+CMT:"
      if (strncmp(sim800lBuffer, "+CMT:", 5) == 0) {
        Serial.println(F("SMS DETECTED"));
        // We have received an SMS notification
        // The next line should be the SMS content
        char senderNumber[20];
        char dateTime[30];

        // Extrai o numero do remetente e a data/hora
        int numFields = sscanf(sim800lBuffer, "+CMT: \"%19[^\"]\",\"\",\"%29[^\"]\"", senderNumber, dateTime);
        if (numFields >= 1) {
          // Read the SMS content
          if (sim800l.available()) {
            size_t contentLength = sim800l.readBytesUntil('\n', sim800lBuffer, sizeof(sim800lBuffer) - 1);
            sim800lBuffer[contentLength] = '\0'; // Null-terminate the string

            // Remove caracteres de nova linha
            char *p = strchr(sim800lBuffer, '\r');
            if (p) *p = '\0';
            p = strchr(sim800lBuffer, '\n');
            if (p) *p = '\0';

            processReceivedSMS(senderNumber, sim800lBuffer);
          }
        }
      }

      // Reset the buffer position for the next line
      sim800lBufferPos = 0;
    } else {
      if (sim800lBufferPos < sizeof(sim800lBuffer) - 1) {
        sim800lBuffer[sim800lBufferPos++] = c;
      }
    }
  }
}

// Rest of the SMSHandler.cpp code remains the same

void processReceivedSMS(const char *fullPhoneNumber, const char *smsContent) {
  Serial.print(F("Received SMS from "));
  Serial.print(fullPhoneNumber);
  Serial.println(":");
  Serial.println(smsContent);

  // Decrypt the SMS content
  String decrypted = decryptGCM(encryptionKey, smsContent);
  Serial.println(F("Decrypted SMS Content:"));
  Serial.println(decrypted);

  // Check if decryption was successful
  if (decrypted == "E") {
    Serial.println(F("Authentication failed. SMS discarded."));
    return;
  }

  // Process the phone number (reduce to last 4 digits)
  char senderNumber[5]; // Last 4 digits + null terminator
  size_t len = strlen(fullPhoneNumber);
  strncpy(senderNumber, &fullPhoneNumber[len - 4], 4);
  senderNumber[4] = '\0'; // Ensure null-termination

  // Parse the counter and command
  char *decryptedStr = strdup(decrypted.c_str());
  char *token = strtok(decryptedStr, "|");
  if (token == NULL) {
    Serial.println(F("Invalid message format."));
    free(decryptedStr);
    return;
  }

  uint32_t receivedCounter32 = atol(token); // Parse as 32-bit integer
  uint16_t receivedCounter = receivedCounter32 % 65536; // Map to uint16_t (0-255)
  char *command = strtok(NULL, "|");
  if (command == NULL) {
    Serial.println(F("Invalid message format."));
    free(decryptedStr);
    return;
  }

  if (strcmp(command, "reset") == 0) {
    resetEEPROM();
    free(decryptedStr);
    return;
  }

  // Find or add the user
  int userIndex = findOrAddUser(senderNumber, receivedCounter == 0);

  if (userIndex == -1) {
    Serial.println(F("User not in the list. Cannot process message."));
    free(decryptedStr);
    return;
  }


  Serial.print("Last Numbers: ");
  Serial.println(userCounters[userIndex].phoneNumber);
  Serial.print("Counter: ");
  Serial.println(userCounters[userIndex].lastCounter);

  // Compute delta between receivedCounter and lastCounter, accounting for wrap-around
  int delta = receivedCounter - userCounters[userIndex].lastCounter;

  if (delta == 0) {
    Serial.println(F("Replay attack detected (same counter). Message discarded."));
  } else if (delta < 0) {
    Serial.println(F("Replay attack detected (counter too old). Message discarded."));
  } else {
    userCounters[userIndex].lastCounter = receivedCounter;
    saveUserCountersToEEPROM();

    // Process the command
    processCommand(command, fullPhoneNumber);
    return;
  }

  free(decryptedStr);
}

void flushSIM800L() {
  while (sim800l.available()) {
    Serial.print(sim800l.read());
  }
}

void loadUserCountersFromEEPROM() {
  Serial.println(F("Loading users"));
  int address = EEPROM_USER_COUNTERS_ADDRESS;
  for (int i = 0; i < MAX_USERS; i++) {
    // Read phoneNumber (5 bytes)
    for (int j = 0; j < sizeof(userCounters[i].phoneNumber); j++) {
      int value = EEPROM.read(address++);
      userCounters[i].phoneNumber[j] = (value == -1 || value == 255) ? '\0' : value;
    }
    // Ensure null-termination
    userCounters[i].phoneNumber[sizeof(userCounters[i].phoneNumber) - 1] = '\0';
    // Read lastCounter (1 byte)
    userCounters[i].lastCounter = EEPROM.read(address++);
  }
}

void saveUserCountersToEEPROM() {
  int address = EEPROM_USER_COUNTERS_ADDRESS;
  for (int i = 0; i < MAX_USERS; i++) {
    // Write phoneNumber (5 bytes)
    for (int j = 0; j < sizeof(userCounters[i].phoneNumber); j++) {
      EEPROM.update(address++, userCounters[i].phoneNumber[j]);
    }
    // Write lastCounter (1 byte)
    EEPROM.update(address++, userCounters[i].lastCounter);
  }
}

void resetEEPROM() {
  Serial.println(F("Reseting EEPROM"));
  for (int i = 0 ; i < EEPROM.length() ; i++) {
    EEPROM.write(i, 0);
  }
  loadUserCountersFromEEPROM();
}

int findOrAddUser(const char *senderNumber, bool shouldAdd) {
  int emptyIndex = -1;
  for (int i = 0; i < MAX_USERS; i++) {
    if (strcmp(userCounters[i].phoneNumber, senderNumber) == 0) {
      // User found
      return i;
    } else if (userCounters[i].phoneNumber[0] == '\0' && emptyIndex == -1) {
      // Record empty slot
      emptyIndex = i;
    }
  }

  if (emptyIndex != -1 && shouldAdd) {
    // Add new user
    strncpy(userCounters[emptyIndex].phoneNumber, senderNumber, sizeof(userCounters[emptyIndex].phoneNumber) - 1);
    userCounters[emptyIndex].phoneNumber[sizeof(userCounters[emptyIndex].phoneNumber) - 1] = '\0';
    userCounters[emptyIndex].lastCounter = 0;

    Serial.println(F("New User!"));
    saveUserCountersToEEPROM();

    return emptyIndex;
  }

  // No space for new users
  // Implement LRU policy or reject new users
  return -1;
}
