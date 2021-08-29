import BluetoothWrapper

public struct BluetoothDevice: BluetoothIdentifiable, Hashable {
  let id: String = UUID().uuidString
}
