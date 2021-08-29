import Foundation

public protocol EnumValueConvertible {
  var value: EnumValue { get }
}

public struct EnumValue {
  let bytes: String
  
  init(_ value: Data) {
    bytes = value.reduce("") {$0 + String(format: "%02x", $1)}
  }
  
  init(_ value: UInt8) {
    self.init(value: value)
  }
  
  public init<T: UnsignedInteger>(value: T) {
    self.bytes = String(format:"%0\(MemoryLayout<T>.size * 2)X", value as! CVarArg)
  }
}
