import AsyncOperation

protocol BLOperationStrategy {
  func match<T>(manager: BluetoothWrapper,
                peripheral: BluetoothIdentifiable,
                request: T,
                queue: DispatchQueue) -> AsyncOperation where T : BLRequestProtocol
}
