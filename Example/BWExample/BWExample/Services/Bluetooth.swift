import Foundation
import Combine
import CoreBluetooth
import BluetoothWrapper

protocol Bluetooth {
  var isAuthorised: Published<Bool>.Publisher { get }
  
  var devices: Published<Set<BluetoothDevice>>.Publisher { get }
  func scan()
  func readData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool)
  func writeData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T,  force: Bool)
  func connect(peripheral: BluetoothIdentifiable) -> AnyPublisher<BluetoothWrapper.CBConnection,
                                                                  BluetoothWrapper.CBError>
  func disconnect(peripheral: BluetoothIdentifiable)
}

extension Bluetooth {
  func readData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool = false) {
    readData(for: peripheral, request: request, force: force)
  }
  
  func writeData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool = false) {
    writeData(for: peripheral, request: request, force: force)
  }
}

class BluetoothImplementation: Bluetooth {
  
  var devices: Published<Set<BluetoothDevice>>.Publisher { $devicesPublisher }
  @Published fileprivate var devicesPublisher: Set<BluetoothDevice> = []
  
  // TODO: Refactore to state property???
  var isAuthorised: Published<Bool>.Publisher { $isAuthorisedPublisher}
  @Published fileprivate var isAuthorisedPublisher: Bool = false
  
  var connectionState: CurrentValueSubject<BluetoothWrapper.CBConnection,
                                           BluetoothWrapper.CBError> = .init(.disconnected)
  
  private var manager: CBCentralManager!
  private var proxyManager: BluetoothWrapper!
  private let queue = DispatchQueue(label: "counter", qos: .background)
  private var disposables = Set<AnyCancellable>()
  
  init() {
    setup()
  }
  
  private func setup() {
    proxyManager = BluetoothWrapper(asyncState: { [weak self, proxyManager] (state) -> BluetoothWrapper.CBAction in
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
    }, strategy: BluetoothStrategy())
  }
  
  func scan() {
    proxyManager.scan()
  }
  
  func readData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool = false) {
    guard connectionState.value == .connected else {
      return
    }

    let request = T.init(operation: .write,
                         type: .read,
                         request: request.request,
                         value: nil,
                         writeCompletion: request.writeCompletion,
                         readCompletion: request.readCompletion)
    proxyManager.do(for: peripheral, request: request, force: force)
  }
  
  func writeData<T: BLRequestProtocol>(for peripheral: BluetoothIdentifiable, request: T, force: Bool = false) {
    guard connectionState.value == .connected else {
      return
    }

    proxyManager.do(for: peripheral, request: request, force: force)
  }
  
  func connect(peripheral: BluetoothIdentifiable) -> AnyPublisher<BluetoothWrapper.CBConnection,
                                                                  BluetoothWrapper.CBError> {
    connectionState = .init(.connecting)
    self.proxyManager.connect(peripheral: peripheral,
                              settings: PeripheralSettings(characteristicUUID: nil,
                                                           serviceUUID: nil)) { [weak self] result in
      switch result {
      case let .success(connection):
        self?.connectionState.send(connection)
      case let .failure(error):
        self?.connectionState.send(completion: .failure(error))
      }
    }
    
    return connectionState.eraseToAnyPublisher()
  }
  
  func disconnect(peripheral: BluetoothIdentifiable) {
    proxyManager.disconnect(peripheral: peripheral)
  }
  
  private func handle(uuid: String, name: String?, data: [String: Any], rssi: Int) -> BluetoothDevice? {
   // Handle somehow device ad
    return BluetoothDevice()
  }
  
}
