import Combine

class ContentViewModel {
  @Published var devices: [String] = []
  
  private var bluetooth: Bluetooth = BluetoothImplementation()
  private var bag: Set<AnyCancellable> = []
  
  init() {
    bluetooth.scan()
    bluetooth
      .devices
      .map {
        $0.map {
          $0.id
        }
      }
      .sink { [weak self] devices in
        self?.devices = devices
      }
      .store(in: &bag)
  }
}
