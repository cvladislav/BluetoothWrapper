import Foundation

public protocol DataConvertible {
  var data: Data { get }
}

public protocol ToRequest: EnumConvertible {
  var toRequestBytes: String { get }
}

public protocol ToRequestShifted: ToRequest {
  associatedtype T: (RawRepresentable & CaseIterable) where T.RawValue: UnsignedInteger
  
  var request: T { get }
  var shift: T.RawValue { get }
  var number: T.RawValue { get }
  
  init(request: T, number: T.RawValue)
}

extension ToRequestShifted {
  var hexString: String {
    String(format:"%0\(MemoryLayout<T.RawValue>.size * 2)X", (request.rawValue + number * shift) as! CVarArg)
  }
  
  static var Case: (T.RawValue) -> [Self] {
    {
      (UInt16(T.RawValue(0))...UInt16($0)).compactMap {
        guard let `case` = T.allCases.first else {
          return nil
        }
        return Self.init(request: `case`, number: T.RawValue($0))
      }
    }
  }
  
  static var Cases: (T.RawValue) -> [[Self]] {
    {
      (UInt16(T.RawValue(0))...UInt16($0)).compactMap {
        var requests: [Self] = []
        for `case` in T.allCases {
          requests.append( Self.init(request: `case`, number: T.RawValue($0)) )
        }
        return requests
      }
    }
  }
}

extension ToRequest {
  public var toRequestBytes: String { hexString }
  
  ///
  /// There is you can describe any request by variable
  /// For example:
  ///
  /// var someRequest: String { Base.request + Another.param + ... + hexString
  ///
  ///
}
  
public protocol EnumConvertible {
  var hexString: String { get }
}

extension EnumConvertible where Self: RawRepresentable {
  static func +(lhs: Self, rhs: ToRequest) -> String {
    lhs.hexString + rhs.hexString
  }
  
  static func +(lhs: String, rhs: Self) -> String {
    lhs + rhs.hexString
  }
  
  public var hexString: String {
    String(format:"%0\(MemoryLayout<Self.RawValue>.size * 2)X", self.rawValue as! CVarArg)
  }
}

public protocol BLRequestProtocol: DataConvertible {
  associatedtype P: BLParsable
  
  var operation: BluetoothWrapper.CBOperation { get }
  var type: BluetoothWrapper.CBOperation { get }
  
  var writeCompletion: WriteCompletion? { get }
  var readCompletion: ReadCompletion? { get }
  
  var request: ToRequest { get }
  
  init(operation: BluetoothWrapper.CBOperation,
       type: BluetoothWrapper.CBOperation?,
       request: ToRequest,
       value: ToRequest?,
       writeCompletion: WriteCompletion?,
       readCompletion: ReadCompletion?)
}

extension BLRequestProtocol {
  public typealias WriteCompletion = (Result<Void, BluetoothWrapper.CBWriteDataError>) -> Void
  public typealias ReadCompletion = (Result<P, BluetoothWrapper.CBReadDataError>) -> Void
}

public class BLBaseRequest<A: BLParsable>: BLRequestProtocol {
  public typealias P = A
  
  public let operation: BluetoothWrapper.CBOperation
  public let type: BluetoothWrapper.CBOperation
  fileprivate var requestType: ToRequest! = EmptyRequest.empty
  public let request: ToRequest
  fileprivate let value: ToRequest?
  public var data: Data {
    (String(format: request.toRequestBytes, requestType.hexString) + (value?.hexString ?? "") ).hexadecimal!
  }
  
  public let writeCompletion: WriteCompletion?
  public let readCompletion: ReadCompletion?
  
  public required init(operation: BluetoothWrapper.CBOperation,
       type: BluetoothWrapper.CBOperation? = nil,
       request: ToRequest,
       value: ToRequest? = nil,
       writeCompletion: WriteCompletion? = nil,
       readCompletion: ReadCompletion? = nil) {
    self.operation = operation
    self.type = type ?? operation
    self.request = request
    self.value = value
    self.writeCompletion = writeCompletion
    self.readCompletion = readCompletion
  }
}
