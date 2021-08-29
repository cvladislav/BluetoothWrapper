import SwiftUI

struct ContentView: View {
  let model: ContentViewModel = ContentViewModel()
  
    var body: some View {
      List {
        ForEach(model.devices, id: \.self) {
          Text($0)
        }
      }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
