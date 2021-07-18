import Foundation
import AsyncOperation

class BLOperation<T: BLRequestProtocol, P: BLParserProtocol>: AsyncOperation {
  private weak var manager: BluetoothWrapper?
  private let device: BluetoothIdentifiable
  private let request: T
  private let queue: DispatchQueue
  
  /// Override to increase or decrease time
  var timeout: DispatchTime {
      .now() + 10
  }
  
  init(manager: BluetoothWrapper?,
       device: BluetoothIdentifiable,
       request: T,
       queue: DispatchQueue
       
  ) {
    self.manager = manager
    self.device = device
    self.request = request
    self.queue = queue
  }
  
  /// Override this function with implementation. Don't forget call super and state = .finished
  open override func main() {
    guard !self.isCancelled else { return }
    
    state = .executing
    
    queue.asyncAfter(deadline: timeout) { [weak self] in
      if let `self` = self, self.state != .finished {
        self.request.readCompletion?(.failure(.timeout))
        self.state = .finished
      }
    }
  }
}
