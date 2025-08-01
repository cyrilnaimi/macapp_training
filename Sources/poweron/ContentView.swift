
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("PowerOn")
                .font(.largeTitle)
                .padding()
            
            Button("Schedule Wake Up") {
                // Add action to schedule wake up
            }
            .padding()
            
            Button("Schedule Shutdown") {
                // Add action to schedule shutdown
            }
            .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
