import CoreBluetooth

protocol BluetoothIdentifiable {
  var id: String { get }
}

extension Peripheral {
  override var hash: Int {
    return id.hash
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    if let obj = object as? Self {
      return obj.id == id
    }
    return false
  }
}

func ==(lhs: Peripheral, rhs: Peripheral) -> Bool {
  return lhs.id == rhs.id
}

protocol PeripheralProtocol: BluetoothIdentifiable, CBPeripheralDelegate {
  init(_ peripheral: CBPeripheral)
  
  var completion: BluetoothWrapper.ConnectionCompletion? { get set }
  
  var name: String? { get }
  var state: CBPeripheralState { get }
  
  func connect(with manager: CBCentralManager, with settings: PeripheralSettings)
  func disconnect(with manager: CBCentralManager)
  func discoverServices()
  func discoverCharacteristic()
  func update(services: [CBService]?)
  func update(characteristics: [CBCharacteristic]?)
  func readData()
  func write(data: Data)
}

struct PeripheralSettings {
  let characteristicUUID: CBUUID?
  let serviceUUID: CBUUID?
}

class Peripheral: NSObject, PeripheralProtocol {
  private let peripheral: CBPeripheral
  private var settings: PeripheralSettings!
  private var characteristic: CBCharacteristic?
  private var service: CBService?
  
  var completion: BluetoothWrapper.ConnectionCompletion?
  
  var id: String {
    peripheral.identifier.uuidString
  }
  
  var name: String? {
    peripheral.name
  }
  
  var state: CBPeripheralState {
    peripheral.state
  }
  
  required init(_ peripheral: CBPeripheral) {
    self.peripheral = peripheral
    
    super.init()
  }
  
  func connect(with manager: CBCentralManager, with settings: PeripheralSettings) {
    self.settings = settings
    manager.connect(peripheral, options: nil)
  }
  
  func disconnect(with manager: CBCentralManager) {
    manager.cancelPeripheralConnection(peripheral)
  }
  
  // MARK: - Connecting
  
  func discoverServices() {
    peripheral.discoverServices(nil)
  }
  
  func discoverCharacteristic() {
    update(services: peripheral.services)
    
    if let service = service {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func update(services: [CBService]?) {
    self.service = services?.filter { $0.uuid == self.settings.serviceUUID }.first
  }
  
  func update(characteristics: [CBCharacteristic]?) {
    self.characteristic = characteristics?.filter { $0.uuid == self.settings.characteristicUUID }.first
    if let characteristic = self.characteristic {
      self.peripheral.setNotifyValue(true, for: characteristic)
    }
  }
  
  // MARK: - Communication
  
  func readData() {
    if let characteristic = characteristic {
      peripheral.readValue(for: characteristic)
    }
  }
  
  func write(data: Data) {
    if let characteristic = characteristic {
      peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
  }
}
