
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
            Text("The Missing On/Off Scheduler for macOS")
                .font(.largeTitle)
                .padding()
            
            ScheduleView(title: LocalizedStringKey("Power On"), iconName: "power.circle", time: $powerOnTime, days: $powerOnDays)
            
            Divider()
            
            ScheduleView(title: LocalizedStringKey("Shutdown"), iconName: "power.circle.fill", time: $shutdownTime, days: $shutdownDays)
            
            Button(LocalizedStringKey("Apply")) {
                let powerOnSchedule = Schedule(type: "wakeorpoweron", days: convertFullDaysToShort(days: powerOnDays), time: timeString(from: powerOnTime))
                let shutdownSchedule = Schedule(type: "shutdown", days: convertFullDaysToShort(days: shutdownDays), time: timeString(from: shutdownTime))
                
                var schedules = [Schedule]()
                if !powerOnSchedule.days.isEmpty {
                    schedules.append(powerOnSchedule)
                }
                if !shutdownSchedule.days.isEmpty {
                    schedules.append(shutdownSchedule)
                }
                
                var command = "sudo pmset repeat"
                if schedules.isEmpty {
                    command += " cancel"
                } else {
                    for schedule in schedules {
                        command += " \(schedule.type) \(schedule.days.joined()) \(schedule.time)"
                    }
                }
                
                alertMessage = String(localized: "This will execute the following command:\n\n\(command)")
                showingAlert = true
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(LocalizedStringKey("Confirm")),
                    message: Text(alertMessage),
                    primaryButton: .default(Text(LocalizedStringKey("Apply"))) {
                        let powerOnSchedule = Schedule(type: "wakeorpoweron", days: powerOnDays, time: timeString(from: powerOnTime))
                        let shutdownSchedule = Schedule(type: "shutdown", days: shutdownDays, time: timeString(from: shutdownTime))
                        
                        var schedules = [Schedule]()
                        if !powerOnSchedule.days.isEmpty {
                            schedules.append(powerOnSchedule)
                        }
                        if !shutdownSchedule.days.isEmpty {
                            schedules.append(shutdownSchedule)
                        }
                        
                        pmsetManager.setSchedules(schedules: schedules) { success in
                            // Handle success/failure
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
    
    private func convertFullDaysToShort(days: [String]) -> [String] {
        let dayMap = [
            "Monday": "M",
            "Tuesday": "T",
            "Wednesday": "W",
            "Thursday": "R",
            "Friday": "F",
            "Saturday": "S",
            "Sunday": "U"
        ]
        return days.compactMap { dayMap[$0] }
    }
}

struct ScheduleView: View {
    let title: LocalizedStringKey
    let iconName: String
    @Binding var time: Date
    @Binding var days: [String]
    
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: iconName)
                    .font(.headline)
                Text(title)
                    .font(.headline)
            }
            
            HStack {
                DatePicker(LocalizedStringKey("Time"), selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                
                Spacer()
                
                ForEach(weekdays, id: \.self) { day in
                    Button(action: {
                        if days.contains(day) {
                            days.removeAll { $0 == day }
                        } else {
                            days.append(day)
                        }
                    }) {
                        Text(day.prefix(1))
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
