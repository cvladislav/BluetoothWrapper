import XCTest
@testable import BluetoothWrapper
import AsyncOperation

class BluetoothWrapperTests: XCTestCase {
  
  var bWrapper: BluetoothWrapper!
  
  struct Parser: BLParserProtocol {
    static func parse<T>(from data: Data, request: T.P?) throws -> T where T : BLParsable {
      T.init(data: Data(), request: request)
    }
  }
  
  struct BluetoothStrategy: BLOperationStrategy {
    func match<T>(manager: BluetoothWrapper,
                  peripheral: BluetoothIdentifiable,
                  request: T,
                  queue: DispatchQueue) -> AsyncOperation where T : BLRequestProtocol {
      return BLOperation<T, Parser>(manager: manager, device: peripheral, request: request, queue: queue)
    }
  }
  
  override func setUp() {
    bWrapper = BluetoothWrapper(asyncState: { action in
      return .scan
    }, scanCompletion: { scan in
      return .skip
    }, strategy: BluetoothStrategy())
  }
  
  func testAdd() {

  }
  
}
