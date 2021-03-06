// Copyright (c) 2016, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

#ifndef SRC_FREERTOS_DEVICE_MANAGER_H_
#define SRC_FREERTOS_DEVICE_MANAGER_H_

#include "src/shared/platform.h"
#include "src/vm/port.h"
#include "src/vm/event_handler.h"

#include "src/freertos/device_manager_api.h"

namespace dartino {

// Event generated by the device manager when a device has flags changed.
class Event {
 public:
  uint32_t device;
  uint32_t flags;
  EventListener* event_listener;
};

// An instance of a open device that can be listened to.
class Device {
 public:
  enum Type {
    UART_DEVICE = 0,
    BUTTON_DEVICE = 1,
    I2C_DEVICE = 2,
    // TODO(karlklose): IO endpoints are not really devices.
    SOCKET_DEVICE = 3,
  };

  Device(const char* name, Type type) :
      name_(name),
      type_(type),
      event_listener_(NULL),
      flags_(0),
      wait_mask_(0),
      initialized_(false) {}

  // Sets the [flag] in [flags]. Returns true if anything changed.
  // Sends a message if there is a matching listener.
  bool SetFlags(uint32_t flag);

  // Clears the [flag] in [flags]. Returns true if anything changed.
  bool ClearFlags(uint32_t flag);

  // Clears the flags in wait_mask. Returns true if anything changed.
  bool ClearWaitFlags();

  uint32_t GetFlags();

  // Set up listening for the given wait_mask.
  //
  // This method transfers ownership of [event_listener] to this Device.
  void SetEventListener(EventListener *event_listener, uint32_t wait_mask);

  int device_id() const { return device_id_; }
  void set_device_id(int device_id) { device_id_ = device_id; }

  const char* name() const { return name_; }
  Type type() const { return type_; }

 private:
  friend class DeviceManager;

  // Send a message if there is an installed event_listener and
  // (flags_ & wait_mask_) != 0.
  //
  // This should only be called with mutex_ taken.
  void SendIfReady();

  // This should only be called with mutex_ taken.
  bool HasEventListener() {
    return event_listener_ != NULL;
  }

  bool IsReady();

  const char* name_;
  Type type_;

  int device_id_;

  // Whom to notify when messages arrive on this device.
  EventListener* event_listener_;

  // The current flags for this device.
  uint32_t flags_;

  // The mask for messages on this device.
  uint32_t wait_mask_;

  bool initialized_;
};


class UartDevice: public Device {
 public:
  UartDevice(const char* name, UartDriver* driver)
      : Device(name, UART_DEVICE), driver_(driver) {}

  void Initialize() {
    driver_->Initialize(driver_);
  }

  // Read up to `count` bytes from the UART into `buffer` starting at
  // buffer. Return the number of bytes read.
  //
  // This is non-blocking, and will return 0 if no data is available.
  size_t Read(uint8_t* buffer, size_t count) {
    return driver_->Read(driver_, buffer, count);
  }

  // Write up to `count` bytes from the UART into `buffer` starting at
  // `offset`. Return the number of bytes written.
  //
  // This is non-blocking, and will return 0 if no data could be written.
  size_t Write(const uint8_t* buffer, size_t offset, size_t count) {
    return driver_->Write(driver_, buffer, offset, count);
  }

  uint32_t GetError() {
    return driver_->GetError(driver_);
  }

  static UartDevice* cast(Device* device) {
    ASSERT(device->type() == UART_DEVICE);
    return reinterpret_cast<UartDevice*>(device);
  }

 private:
  UartDriver* driver_;
};


class ButtonDevice: public Device {
 public:
  ButtonDevice(const char* name, ButtonDriver* driver)
      : Device(name, BUTTON_DEVICE), driver_(driver) {}

  void Initialize() {
    driver_->Initialize(driver_);
  }

  // Indicate that the button press has been recognized.
  void NotifyRead() {
    driver_->NotifyRead(driver_);
  }

  static ButtonDevice* cast(Device* device) {
    ASSERT(device->type() == BUTTON_DEVICE);
    return reinterpret_cast<ButtonDevice*>(device);
  }

 private:
  ButtonDriver* driver_;
};

class I2CDevice: public Device {
 public:
  I2CDevice(const char* name, I2CDriver* driver)
      : Device(name, I2C_DEVICE), driver_(driver) {}

  void Initialize() {
    driver_->Initialize(driver_);
  }

  int RequestReadRegisters(uint16_t address, uint16_t reg,
                           uint8_t* buffer, size_t count) {
    return driver_->RequestReadRegisters(driver_, address, reg, buffer, count);
  }

  int RequestWriteRegisters(uint16_t address, uint16_t reg,
                            uint8_t* buffer, size_t count) {
    return driver_->RequestWriteRegisters(driver_, address, reg, buffer, count);
  }

  int AcknowledgeResult() {
    return driver_->AcknowledgeResult(driver_);
  }

  static I2CDevice* cast(Device* device) {
    ASSERT(device->type() == I2C_DEVICE);
    return reinterpret_cast<I2CDevice*>(device);
  }

 private:
  I2CDriver* driver_;
};

class DeviceManager {
 public:
  static DeviceManager *GetDeviceManager();

  void DeviceSetFlags(uintptr_t device_id, uint32_t flags);
  void DeviceClearFlags(uintptr_t device_id, uint32_t flags);

  uintptr_t RegisterDevice(Device* device);

  // Register a UART driver with the given device name.
  void RegisterUartDevice(const char* name, UartDriver* driver);

  // Register a button driver with the given device name.
  void RegisterButtonDevice(const char* name, ButtonDriver* driver);

  // Register a I2C driver with the given device name.
  void RegisterI2CDevice(const char* name, I2CDriver* driver);

  int OpenUart(const char* name);
  int OpenButton(const char* name);
  int OpenI2C(const char* name);

  int CreateSocket();
  void RemoveSocket(int handle);

  bool SetEventListener(
      int handle, uint32_t flags, EventListener* event_listener);

  void RemoveDevice(Device* device);
  UartDevice* GetUart(int handle);
  ButtonDevice* GetButton(int handle);
  I2CDevice* GetI2C(int handle);

  osMessageQId GetMailQueue() {
    return mail_queue_;
  }

  int SendMessage(int handle);

 private:
  DeviceManager();

  Device* LookupDevice(const char* name, Device::Type type);

  uintptr_t FindFreeDeviceSlot();

  void RegisterFreeDeviceSlot(int handle);

  Vector<Device*> devices_ = Vector<Device*>();

  osMessageQId mail_queue_;

  static DeviceManager *instance_;

  Mutex* mutex_;

  // The smallest index of a free ("NULL") slot in devices_ or kIllegalDeviceId
  // if there is no such slot.
  uintptr_t next_free_slot_;
};

}  // namespace dartino

#endif  // SRC_FREERTOS_DEVICE_MANAGER_H_
