#include <string.h>
#include <SoftwareSerial.h>

const int led3Pin = 8;
const int led2Pin = 3;
const int led1Pin = 2;

const char encryptionKey[] = "SenhaSecreta1234";

struct ScheduledCommand {
  char phoneNumber[16];
  char command[10];
};

ScheduledCommand scheduledCommand;

bool isCommandScheduled = false;

void setup() {
  pinMode(led1Pin, OUTPUT);
  pinMode(led2Pin, OUTPUT);
  pinMode(led3Pin, OUTPUT);

  Serial.begin(9600);
  //sim800l.begin(9600);
  while (!Serial) {
    ; // Espera porta serial ficar pronta
  }

  // Inicializa gerador randomico
  randomSeed(analogRead(0));

  // Inicializa modulo GSM
  initializeSIM800L();

}

void loop() {
  checkForSMS();
  processScheduledCommand();
//  if (sim800l.available()) {
//    Serial.write(sim800l.read());
//  }
//  if (Serial.available()) {
//    sim800l.write(Serial.read());
//  }
}

void processCommand(const char *command, const char *sender) {
  // Remove espaços vazios
  while (*command == ' ' || *command == '\t') command++;

  Serial.print(F("Processing command: "));
  Serial.println(command);

  if (strcmp(command, "allon") == 0) {
    digitalWrite(led1Pin, HIGH);
    digitalWrite(led2Pin, HIGH);
    digitalWrite(led3Pin, HIGH);
    Serial.println(F("All LEDs turned ON"));
  } else if (strcmp(command, "alloff") == 0) {
    digitalWrite(led1Pin, LOW);
    digitalWrite(led2Pin, LOW);
    digitalWrite(led3Pin, LOW);
    Serial.println(F("All LEDs turned OFF"));
  } else if (strcmp(command, "1on") == 0) {
    digitalWrite(led1Pin, HIGH);
    Serial.println(F("LED 1 turned ON"));
  } else if (strcmp(command, "1off") == 0) {
    digitalWrite(led1Pin, LOW);
    Serial.println(F("LED 1 turned OFF"));
  } else if (strcmp(command, "2on") == 0) {
    digitalWrite(led2Pin, HIGH);
    Serial.println(F("LED 2 turned ON"));
  } else if (strcmp(command, "2off") == 0) {
    digitalWrite(led2Pin, LOW);
    Serial.println(F("LED 2 turned OFF"));
  } else if (strcmp(command, "3on") == 0) {
    digitalWrite(led3Pin, HIGH);
    Serial.println(F("LED 3 turned ON"));
  } else if (strcmp(command, "3off") == 0) {
    digitalWrite(led3Pin, LOW);
    Serial.println(F("LED 3 turned OFF"));
  } else if (strcmp(command, "status") == 0) {
    // Schedule the status command
    Serial.println(F("Scheduling status SMS"));

    // Armazena o numero e o comando na variavel global
    strncpy(scheduledCommand.phoneNumber, sender, sizeof(scheduledCommand.phoneNumber) - 1);
    scheduledCommand.phoneNumber[sizeof(scheduledCommand.phoneNumber) - 1] = '\0';

    strncpy(scheduledCommand.command, command, sizeof(scheduledCommand.command) - 1);
    scheduledCommand.command[sizeof(scheduledCommand.command) - 1] = '\0';

    isCommandScheduled = true;
  } else {
    Serial.println(F("Unknown command"));
  }
}

void processScheduledCommand() {
  if (isCommandScheduled) {
    
    if (strcmp(scheduledCommand.command, "status") == 0) {
      int l1 = digitalRead(led1Pin);
      int l2 = digitalRead(led2Pin);
      int l3 = digitalRead(led3Pin);
      Serial.println(F("Processing scheduled status SMS"));

      // Gera mensagem de status
      static char message[32];
      snprintf(message, sizeof(message),
               "LED1: %s\nLED2: %s\nLED3: %s",
               l1 == HIGH ? "ON" : "OFF",
               l2 == HIGH ? "ON" : "OFF",
               l3 == HIGH ? "ON" : "OFF");

      // Criptografa a mensagem
      String encryptedMessage = encryptGCM(encryptionKey, message);
      Serial.print("M: ");
      Serial.println(encryptedMessage);

      // Envia SMS
      sendSMS(encryptedMessage.c_str(), scheduledCommand.phoneNumber);

      isCommandScheduled = false;
    }

  }
}
