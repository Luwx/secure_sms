#include <Crypto.h>
#include <AES.h>
#include <GCM.h>
#include <string.h>
#include "base64.hpp" // Include your Base64 library

// Define the AES key size (128 bits)
#define AES_KEY_SIZE 128

// Define maximum lengths
#define MAX_KEY_LENGTH (AES_KEY_SIZE / 8)  // 16 bytes for AES-128
#define MAX_PLAINTEXT_LENGTH 32            // Adjust as needed
#define MAX_CIPHERTEXT_LENGTH MAX_PLAINTEXT_LENGTH
#define MAX_BASE64_LENGTH  ((12 + MAX_CIPHERTEXT_LENGTH + 16 + 2) / 3 * 4 + 1) // IV + ciphertext + tag

// Global buffers to reduce stack usage
static uint8_t key[MAX_KEY_LENGTH];
static uint8_t iv[12]; // GCM standard IV size is 12 bytes
static uint8_t plaintext[MAX_PLAINTEXT_LENGTH];
static uint8_t ciphertext[MAX_CIPHERTEXT_LENGTH];
static uint8_t tag[16]; // Standard tag size
static uint8_t output[12 + MAX_CIPHERTEXT_LENGTH + 16]; // IV + ciphertext + tag
static char base64Output[MAX_BASE64_LENGTH];
static uint8_t input[12 + MAX_CIPHERTEXT_LENGTH + 16]; // IV + ciphertext + tag


void printHex(const char* label, const uint8_t* data, size_t length) {
  Serial.print(label);
  for (size_t i = 0; i < length; i++) {
    if (data[i] < 0x10) Serial.print("0");
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }
  Serial.println();
}

//// Funcao para encriptar texto usando AES GCM
char* encryptGCM(const char *keyStr, const char *plaintextStr) {
  // Ensure the key is the correct length
  memset(key, 0, sizeof(key));
  size_t keyLength = strlen(keyStr);
  if (keyLength > sizeof(key)) keyLength = sizeof(key);
  memcpy(key, keyStr, keyLength);

  // Generate a random IV
  for (size_t i = 0; i < sizeof(iv); i++) {
    iv[i] = random(48, 122);
  }

  // Prepare plaintext
  size_t plaintextLength = strlen(plaintextStr);
  if (plaintextLength > MAX_PLAINTEXT_LENGTH)
    plaintextLength = MAX_PLAINTEXT_LENGTH;
  memset(plaintext, 0, sizeof(plaintext));
  memcpy(plaintext, plaintextStr, plaintextLength);

  // Print key, IV, and plaintext in hex
  //  printHex("Key (hex): ", key, sizeof(key));
  //  printHex("IV (hex): ", iv, sizeof(iv));
  //  printHex("Plaintext (hex): ", plaintext, plaintextLength);

  // Initialize AES GCM with the key and IV
  GCM<AES128> gcm;
  gcm.clear();
  if (!gcm.setKey(key, sizeof(key))) {
    return "E";
  }
  if (!gcm.setIV(iv, sizeof(iv))) {
    return "E";
  }

  // Encrypt the plaintext
  if (plaintextLength > 0) {
    gcm.encrypt(ciphertext, plaintext, plaintextLength);
  }

  // Compute the authentication tag
  gcm.computeTag(tag, sizeof(tag));

  // Print ciphertext and tag in hex
  //  printHex("Ciphertext (hex): ", ciphertext, plaintextLength);
  //  printHex("Tag (hex): ", tag, sizeof(tag));

  // Concatenate IV + ciphertext + tag into the output buffer
  size_t totalSize = sizeof(iv) + plaintextLength + sizeof(tag);
  if (totalSize > sizeof(output))
    return "E";

  memcpy(output, iv, sizeof(iv));
  memcpy(output + sizeof(iv), ciphertext, plaintextLength);
  memcpy(output + sizeof(iv) + plaintextLength, tag, sizeof(tag));

  // Encode the output to Base64
  size_t base64OutputSize = encode_base64(output, totalSize, (unsigned char*)base64Output);
  base64Output[base64OutputSize] = '\0'; // Null-terminate the string

  return base64Output;
}

String decryptGCM(const char *keyStr, const char *base64Input) {
  memset(key, 0, sizeof(key));
  size_t keyLength = strlen(keyStr);
  if (keyLength > sizeof(key)) keyLength = sizeof(key);
  memcpy(key, keyStr, keyLength);

  // Decode the Base64 input
  size_t base64InputLength = strlen(base64Input);
  if (base64InputLength > MAX_BASE64_LENGTH)
    return "E";

  unsigned int decodedLength = decode_base64((unsigned char*)base64Input, input);
  if (decodedLength < (sizeof(iv) + sizeof(tag))) {
    return "E";
  }

  // Extrai IV, texto cifrado e a TAG
  memcpy(iv, input, sizeof(iv));

  size_t ciphertextLength = decodedLength - sizeof(iv) - sizeof(tag);
  if (ciphertextLength > MAX_CIPHERTEXT_LENGTH)
    return "E";

  memcpy(ciphertext, input + sizeof(iv), ciphertextLength);
  memcpy(tag, input + sizeof(iv) + ciphertextLength, sizeof(tag));

  // Inicial o AES GCM com a chave e o IV
  GCM<AES128> gcm;
  gcm.clear();
  if (!gcm.setKey(key, sizeof(key))) {
    return "E";
  }
  if (!gcm.setIV(iv, sizeof(iv))) {
    return "E";
  }

  if (ciphertextLength > 0) {
    gcm.decrypt(plaintext, ciphertext, ciphertextLength);
  }

  // Verifica Tag
  if (!gcm.checkTag(tag, sizeof(tag))) {
    return "E";
  }

  // Converte de byte para string
  char plaintextStr[MAX_PLAINTEXT_LENGTH + 1];
  memcpy(plaintextStr, plaintext, ciphertextLength);
  plaintextStr[ciphertextLength] = '\0';

  return String(plaintextStr);
}
