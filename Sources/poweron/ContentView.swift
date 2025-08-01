
import SwiftUI

struct ContentView: View {
    @State private var powerOnTime = Date()
    @State private var powerOnDays = [String]()
    @State private var shutdownTime = Date()
    @State private var shutdownDays = [String]()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let pmsetManager = PMSetManager()
    
    var body: some View {
        VStack {
            Text("PowerOn")
                .font(.largeTitle)
                .padding()
            
            ScheduleView(title: "Power On", time: $powerOnTime, days: $powerOnDays)
            ScheduleView(title: "Shutdown", time: $shutdownTime, days: $shutdownDays)
            
            Button("Apply") {
                let powerOnSchedule = Schedule(type: "wakeorpoweron", days: powerOnDays, time: timeString(from: powerOnTime))
                let shutdownSchedule = Schedule(type: "shutdown", days: shutdownDays, time: timeString(from: shutdownTime))
                
                var commands = [String]()
                if !powerOnSchedule.days.isEmpty {
                    commands.append("sudo pmset repeat \(powerOnSchedule.type) \(powerOnSchedule.days.joined()) \(powerOnSchedule.time)")
                }
                if !shutdownSchedule.days.isEmpty {
                    commands.append("sudo pmset repeat \(shutdownSchedule.type) \(shutdownSchedule.days.joined()) \(shutdownSchedule.time)")
                }
                
                alertMessage = "This will execute the following commands:\n\n\(commands.joined(separator: "\n"))"
                showingAlert = true
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Confirm"),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("Apply")) {
                        let powerOnSchedule = Schedule(type: "wakeorpoweron", days: powerOnDays, time: timeString(from: powerOnTime))
                        if !powerOnSchedule.days.isEmpty {
                            pmsetManager.setSchedule(schedule: powerOnSchedule) { success in
                                // Handle success/failure
                            }
                        }
                        
                        let shutdownSchedule = Schedule(type: "shutdown", days: shutdownDays, time: timeString(from: shutdownTime))
                        if !shutdownSchedule.days.isEmpty {
                            pmsetManager.setSchedule(schedule: shutdownSchedule) { success in
                                // Handle success/failure
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding()
        .onAppear(perform: loadSchedule)
    }
    
    private func loadSchedule() {
        pmsetManager.getSchedule { scheduleString in
            // Parse the schedule string and update the UI state
            // This is a simplified example. A more robust implementation would be needed to parse the output of `pmset -g sched`
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct ScheduleView: View {
    let title: String
    @Binding var time: Date
    @Binding var days: [String]
    
    private let weekdays = ["M", "T", "W", "R", "F", "S", "U"]
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
            
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Button(action: {
                        if days.contains(day) {
                            days.removeAll { $0 == day }
                        } else {
                            days.append(day)
                        }
                    }) {
                        Text(day)
                            .padding(8)
                            .background(days.contains(day) ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
