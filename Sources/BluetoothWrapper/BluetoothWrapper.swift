import CoreBluetooth
import AsyncOperation

public class BluetoothWrapper: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  public typealias ConnectionCompletion = (Result<CBConnection, CBError>) -> Void
  public typealias ScanCompletion = (PeripheralScanResult) -> CBScan
  public typealias ReadDataCompletion = (Result<Data, CBReadDataError>) -> Void
  public typealias WriteDataCompletion = (Result<Void, CBWriteDataError>) -> Void
  public typealias OperationCompletion = () -> Void
  public typealias Log = (String) -> Void
  
  private let queue = DispatchQueue(label: "\(BluetoothWrapper.self)", qos: .background)
  private let operations: OperationQueue = OperationQueue()
  
  public enum PeripheralScanResult {
    //      case scanStarted
    case scanResult(peripheral: Peripheral, advertisementData: [String: Any], RSSI: Int)
    //      case scanStopped(peripherals: [Peripheral], error: Error?)
  }
  
  public enum CBAction {
    case scan
    case nothing
  }
  
  public enum CBOperation {
    case read
    case write
  }
  
  public enum CBError: Error {
    case connection
    case services(Error?)
    case characteristics(Error?)
  }
  
  public enum CBConnection {
    case connected
    case connecting
    case disconnected
  }
  
  public enum CBScan {
    case add
    case skip
  }
  
  public enum CBReadDataError: Error {
    case read(Error?)
    case timeout
    case parse
    case noData
    case auth
    case cancelled
  }
  
  public enum CBWriteDataError: Error {
    case write(Error?)
    case timeout
    case parse
  }
  
  private var manager: CBCentralManager!
  open var isAuthorised: Bool {
    (CBCentralManager.authorization == .allowedAlways)
  }
  
  private let scanCompletion: ScanCompletion
  let asyncState: (CBManagerState) -> CBAction
  
  internal var readCompletion: ReadDataCompletion?
  internal var writeCompletion: WriteDataCompletion?
  internal var operationCompletion: OperationCompletion?
    
  private var peripherals: Set<Peripheral> = []
  private let strategy: BLOperationStrategy
  private var log: Log?
  private var lastUUIDs: [CBUUID]?

  public init(asyncState: @escaping (CBManagerState) -> CBAction,
       scanCompletion: @escaping ScanCompletion,
       strategy: BLOperationStrategy,
       log: Log? = nil
  ) {
    self.scanCompletion = scanCompletion
    self.asyncState = asyncState
    self.strategy = strategy
    self.log = log
    super.init()
    
    self.setup()
  }
  
  private func setup() {
    manager = CBCentralManager(delegate: self, queue: queue)
    operations.maxConcurrentOperationCount = 1
  }
  
  public func scan(withServices serviceUUIDs: [CBUUID]? = nil,
            options: [String : Any]? = nil,
            force: Bool = true,
            for lastUUIDs: Bool = false) {
    if force {
      manager.stopScan()
    }
    if !lastUUIDs {
      self.lastUUIDs = serviceUUIDs
    }
    manager.scanForPeripherals(withServices: lastUUIDs ? self.lastUUIDs : serviceUUIDs, options: options)
  }
  
  public func connect(peripheral: BluetoothIdentifiable, settings: PeripheralSettings, completion: @escaping ConnectionCompletion) {
    if let peripheral = retrievePeripheral(by: peripheral) {
      peripheral.connect(with: manager, with: settings)
      peripheral.completion = completion
    }
  }
  
  public func disconnect(peripheral: BluetoothIdentifiable) {
    operations.cancelAllOperations()
    
    if let peripheral = retrievePeripheral(by: peripheral) {
      peripheral.disconnect(with: manager)
    }
  }
  
  public func `do`<T: BLRequestProtocol>(for device: BluetoothIdentifiable,
                                  request: T, force: Bool = false) {
    let operation = getOperation(for: device, request)
    if force {
      operation.queuePriority = .veryHigh
    }
    operations.addOperation(operation)
  }
  
  @discardableResult
  private func getOperation<T: BLRequestProtocol>(for device: BluetoothIdentifiable, _ request: T) -> AsyncOperation {
    return strategy.match(manager: self, peripheral: device, request: request, queue: queue)
  }
  
  func readData(by identifiable: BluetoothIdentifiable) {
    if let peripheral = retrievePeripheral(by: identifiable) {
      peripheral.readData()
    }
  }
  
  func writeData(by identifiable: BluetoothIdentifiable, data: Data) {
    if let peripheral = retrievePeripheral(by: identifiable) {
      peripheral.write(data: data)
    }
  }
  
  private func retrievePeripheral(by identifiable: BluetoothIdentifiable) -> Peripheral? {
    return peripherals.filter({ $0.id == identifiable.id }).first
  }
  
  // MARK: - Delegate
  
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch asyncState(central.state) {
    case .scan: scan(force: true)
    case .nothing: break
    }
  }
  
  public func centralManager(_ central: CBCentralManager,
                      didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any],
                      rssi RSSI: NSNumber) {
    peripheral.delegate = self
    let peripheral = Peripheral(peripheral)
    switch scanCompletion(.scanResult(peripheral: peripheral,
                                      advertisementData: advertisementData,
                                      RSSI: RSSI.intValue)) {
    case .add:
      peripherals.insert(peripheral)
    case .skip: break
    }
  }
  
  // MARK: - Connection
  
  public func centralManager(_ central: CBCentralManager,
                      didConnect peripheral: CBPeripheral) {
    if let peripheral = retrievePeripheral(by: Peripheral(peripheral)) {
      peripheral.discoverServices()
    }
  }
  
  public func centralManager(_ central: CBCentralManager,
                      didFailToConnect peripheral: CBPeripheral,
                      error: Error?) {
    if let peripheral = retrievePeripheral(by: Peripheral(peripheral)) {
      peripheral.completion?(.failure(.connection))
    }
  }
  
  public func centralManager(_ central: CBCentralManager,
                      didDisconnectPeripheral peripheral: CBPeripheral,
                      error: Error?) {
    if let peripheral = retrievePeripheral(by: Peripheral(peripheral)) {
      peripheral.completion?(.success(.disconnected))
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let peripheral = retrievePeripheral(by: Peripheral(peripheral))
    
    if error == nil {
      peripheral?.discoverCharacteristic()
    } else {
      peripheral?.completion?(.failure(.services(error)))
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    log?("[ProxyBluetooth] Discover characteristics for \(service) peripheral:\(peripheral)")
    
    let peripheral = retrievePeripheral(by: Peripheral(peripheral))
    peripheral?.update(characteristics: service.characteristics)
    
    if error == nil {
      peripheral?.completion?(.success(.connected))
    }
  }
  
  // MARK: - Communication
  
  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    log?("[ProxyBluetooth] Value write...")
    if let errorMessage = error?.localizedDescription {
      log?("[ProxyBluetooth] Error - \(errorMessage)")
    }

    if let _ = retrievePeripheral(by: Peripheral(peripheral)) {
      if let error = error {
        writeCompletion?(.failure(.write(error)))
      } else {
        writeCompletion?(.success(()))
      }
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    log?("[ProxyBluetooth] Value read - \(String(describing: characteristic.value?.bytes))")
    if let errorMessage = error?.localizedDescription {
      log?("[ProxyBluetooth] Error - \(errorMessage)")
    }
    
    if let _ = retrievePeripheral(by: Peripheral(peripheral)) {
      if let data = characteristic.value {
        readCompletion?(.success(data))
      } else {
        readCompletion?(.failure(.read(error)))
      }
    }
  }
  
}
