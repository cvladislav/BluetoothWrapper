import XCTest
@testable import BluetoothWrapper

class BluetoothWrapperTests: XCTestCase {
    
    var bWrapper: BluetoothWrapper!

    override func setUp() {
      bWrapper = BluetoothWrapper()
    }

    func testAdd() {
        XCTAssertEqual(bWrapper.add(a: 1, b: 1), 2)
    }

}
