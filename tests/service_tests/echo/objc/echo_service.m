// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// Generated file. Do not edit.

#include "echo_service.h"
#include "include/service_api.h"

static ServiceId _service_id;

@implementation EchoService

+ (void)Setup {
  _service_id = kNoServiceId;
  _service_id = ServiceApiLookup("EchoService");
}

+ (void)TearDown {
  ServiceApiTerminate(_service_id);
  _service_id = kNoServiceId;
}

static const MethodId kEchoId_ = (MethodId)1;

+ (int32_t)echo:(int32_t)n {
  static const int kSize = 40;
  char _bits[kSize];
  char* _buffer = _bits;
  *(int32_t*)(_buffer + 32) = n;
  ServiceApiInvoke(service_id_, kEchoId_, _buffer, kSize);
  return *(int*)(_buffer + 32);
}

static void Unwrap_int32_8(void* raw) {
  typedef void (*cbt)(int);
  char* buffer = (char*)(raw);
  int result = *(int*)(buffer + 32);
  cbt callback = *(cbt*)(buffer + 40);
  free(buffer);
  callback(result);
}

+ (void)echoAsync:(int32_t)n withCallback:(void (*)(int))callback {
  static const int kSize = 40 + 1 * sizeof(void*);
  char* _buffer = (char*)(malloc(kSize));
  *(int32_t*)(_buffer + 32) = n;
  *(void**)(_buffer + 40) = (void*)(callback);
  ServiceApiInvokeAsync(service_id_, kEchoId_, Unwrap_int32_8, _buffer, kSize);
}

static void Unwrap_int32_8_Block(void* raw) {
  typedef void (^cbt)(int);
  char* buffer = (char*)(raw);
  int result = *(int*)(buffer + 32);
  cbt callback = *(cbt*)(buffer + 40);
  free(buffer);
  callback(result);
}

+ (void)echoAsync:(int32_t)n withBlock:(void (^)(int))callback {
  static const int kSize = 40 + 1 * sizeof(void*);
  char* _buffer = (char*)(malloc(kSize));
  *(int32_t*)(_buffer + 32) = n;
  *(void**)(_buffer + 40) = (void*)(callback);
  ServiceApiInvokeAsync(service_id_, kEchoId_, Unwrap_int32_8_Block, _buffer, kSize);
}

static const MethodId kSumId_ = (MethodId)2;

+ (int32_t)sum:(int16_t)x with:(int32_t)y {
  static const int kSize = 40;
  char _bits[kSize];
  char* _buffer = _bits;
  *(int16_t*)(_buffer + 32) = x;
  *(int32_t*)(_buffer + 36) = y;
  ServiceApiInvoke(service_id_, kSumId_, _buffer, kSize);
  return *(int*)(_buffer + 32);
}

+ (void)sumAsync:(int16_t)x with:(int32_t)y withCallback:(void (*)(int))callback {
  static const int kSize = 40 + 1 * sizeof(void*);
  char* _buffer = (char*)(malloc(kSize));
  *(int16_t*)(_buffer + 32) = x;
  *(int32_t*)(_buffer + 36) = y;
  *(void**)(_buffer + 40) = (void*)(callback);
  ServiceApiInvokeAsync(service_id_, kSumId_, Unwrap_int32_8, _buffer, kSize);
}

+ (void)sumAsync:(int16_t)x with:(int32_t)y withBlock:(void (^)(int))callback {
  static const int kSize = 40 + 1 * sizeof(void*);
  char* _buffer = (char*)(malloc(kSize));
  *(int16_t*)(_buffer + 32) = x;
  *(int32_t*)(_buffer + 36) = y;
  *(void**)(_buffer + 40) = (void*)(callback);
  ServiceApiInvokeAsync(service_id_, kSumId_, Unwrap_int32_8_Block, _buffer, kSize);
}

@end
