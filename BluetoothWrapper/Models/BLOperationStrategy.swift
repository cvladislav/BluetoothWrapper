import AsyncOperation

protocol BLOperationStrategy {
  func match<T: BLRequestProtocol>(request: T) -> AsyncOperation
}
