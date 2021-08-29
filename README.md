# BluetoothWrapper
Easily communicate between iOS devices using BLE.

[![Build Status](https://travis-ci.org/cvladislav/BluetoothWrapper.svg?branch=main)](https://travis-ci.org/cvladislav/BluetoothWrapper)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/BluetoothWrapper.svg)](https://img.shields.io/cocoapods/v/BluetoothWrapper.svg)

## Background
Apple mostly did a great job with the CoreBluetooth API, but because it encapsulated the entire Bluetooth LE specification, it can be a lot of work to achieve simple tasks like sending data back and forth between iOS devices, without having to worry about the specification and the inner workings of the CoreBluetooth stack.

BluetoothWrapper tries to address the challenges this may cause by providing a much simpler, modern, closure-based API all implemented in Swift.

## Features

#### Common
- More concise Bluetooth LE availability definition with enums.
- Bluetooth LE availability observation allowing multiple observers at once.

#### Central
- Scan for remote peripherals for a given time interval.
- Continuously scan for remote peripherals for a give time interval, with an in-between delay until interrupted.
- Connect to remote peripherals with a given time interval as time out.
- Operations make communication simply
- Using Result with concrete errors from enums
- Overrading basic classes may easily implement any communication protocol even UDS

#### Peripheral
- Start broadcasting with only a single function call.

## Requirements
- iOS 14.0+
- Xcode 14.0+

## Installation

#### CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.38.2 is required to build BluetoothWrapper. It adds support for Xcode 14, Swift 4.0 and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate BluetoothWrapper into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '14.1'
use_frameworks!

pod 'BluetoothWrapper', '~> 0.1.0'
```

Then, run the following command:

```bash
$ pod install
```

#### Manual
Add the BluetoothWrapper project to your existing project and add BluetoothWrapper as an embedded binary of your target(s).

#### Common
Make sure to import the BluetoothKit framework in files that use it.
```swift
import BluetoothWrapper
```

#### Peripheral

Prepare and start a BluetoothIdentifiable object. You can use it for connect to existing bluetooth device id == UUID device.
```swift
func connect(peripheral: BluetoothIdentifiable) -> AnyPublisher<ProxyCentralManager.CBConnection,
                                                              ProxyCentralManager.CBError> {
connectionState = .init(.connecting)

self.proxyManager.connect(peripheral: peripheral) { [weak self] result in
  switch result {
  case let .success(connection):
    self?.connectionState.send(connection)
    
    Log.log("Connection - \(connection)")
  case let .failure(error):
    self?.connectionState.send(completion: .failure(error))
    
    Log.log("Connection error - \(error)")
  }
}

return connectionState.eraseToAnyPublisher()
}
```

Send or read data can be dne with generic functions. Use force to set priority for request. Also you can simply modify your request if needed
```swift
func readData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool = false) {
let request = T.init(operation: .write,
                     type: .read,
                     request: request.request,
                     value: nil,
                     writeCompletion: request.writeCompletion,
                     readCompletion: request.readCompletion)
proxyManager.do(for: peripheral, request: request, force: force)
}

func writeData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool = false) {
proxyManager.do(for: peripheral, request: request, force: force)
}
```

#### Central
Prepare and start a ProxyCentralManager. There is you can setup actions on any events.
```swift
proxyManager = ProxyCentralManager(asyncState: { [weak self, proxyManager] (state) -> ProxyCentralManager.CBAction in
  if let isAuthorized = proxyManager?.isAuthorised {
    self?.isAuthorisedPublisher = isAuthorized
  }
  
  switch state {
  case .poweredOn:
    return .scan
  case .unauthorized:
    return .nothing
  default:
    return .nothing
  }
}, scanCompletion: { [weak self] (result) in
  switch result {
  case .scanResult(let peripheral, let data, let rsii):
    if let _ = self?.handle(uuid: peripheral.id,
                            name: peripheral.name,
                            data: data,
                            rssi: rsii) {
      return .add
    }
    return .skip
  }
})
```

Scan for peripherals continuously.
```swift
proxyManager.scan()
```

Disconnect.
```swift
proxyManager.disconnect(peripheral: peripheral)
```

## License
BluetoothWrapper is released under the MIT License.
