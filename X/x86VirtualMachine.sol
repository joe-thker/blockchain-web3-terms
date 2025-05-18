// SPDX-License-Identifier: MIT
// Filename: KeyValueStore.cpp

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <iostream>
#include <qtum/contract.h>  // Qtum x86 syscall interface

#define MAX_KEY_LEN 32
#define MAX_VALUE_LEN 64

// Storage prefix constants
const char PREFIX[] = "kv:";

// Save a key-value pair
extern "C" int put(const char* key, const char* value) {
    if (strlen(key) > MAX_KEY_LEN || strlen(value) > MAX_VALUE_LEN) {
        return -1; // error: input too long
    }

    char storageKey[64];
    snprintf(storageKey, sizeof(storageKey), "%s%s", PREFIX, key);

    return qtum::store(storageKey, value, strlen(value));
}

// Retrieve value by key
extern "C" int get(const char* key, char* out, uint32_t outSize) {
    char storageKey[64];
    snprintf(storageKey, sizeof(storageKey), "%s%s", PREFIX, key);

    uint32_t actualSize;
    int status = qtum::load(storageKey, out, outSize, &actualSize);

    return status; // 0 = success, -1 = not found or error
}

// Initialization (called on deployment)
extern "C" int main(int argc, char* argv[]) {
    const char* initialKey = "creator";
    const char* initialVal = "qtum_admin";

    put(initialKey, initialVal);

    return 0;
}
