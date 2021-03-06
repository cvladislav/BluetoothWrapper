import Foundation

public protocol BLParsable {
  associatedtype P: ToRequest
  
  init(data: Data, request: P?)
}

public protocol BLParserProtocol {
  static func parse<T: BLParsable>(from data: Data, request: T.P?) throws -> T
}
