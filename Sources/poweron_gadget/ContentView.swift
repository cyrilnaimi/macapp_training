import SwiftUI

struct ContentView: View {
    @State private var powerOnTime = Date()
    @State private var powerOnDays: Set<String> = []
    @State private var powerOnEnabled = false
    
    @State private var shutdownTime = Date()
    @State private var shutdownDays: Set<String> = []
    @State private var shutdownEnabled = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let pmsetManager = PMSetManager()
    
    var body: some View {
        VStack {
            Text(LocalizedStringKey("The Missing On/Off Scheduler for macOS"))
                .font(.largeTitle)
                .padding()
            
            HStack {
                // Power On Column
                VStack {
                    ScheduleView(title: LocalizedStringKey("Power On"), iconName: "power.circle", time: $powerOnTime, days: $powerOnDays, isEnabled: $powerOnEnabled)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Shutdown Column
                VStack {
                    ScheduleView(title: LocalizedStringKey("Shutdown"), iconName: "power.circle.fill", time: $shutdownTime, days: $shutdownDays, isEnabled: $shutdownEnabled)
                    Spacer()
                }
                .padding()
            }
            
            Button(LocalizedStringKey("Apply")) {
                let powerOnSchedule = Schedule(type: "wakeorpoweron", days: convertFullDaysToShort(days: powerOnDays), time: timeString(from: powerOnTime))
                let shutdownSchedule = Schedule(type: "shutdown", days: convertFullDaysToShort(days: shutdownDays), time: timeString(from: shutdownTime))
                
                var schedulesToApply = [Schedule]()
                if powerOnEnabled && !powerOnDays.isEmpty {
                    schedulesToApply.append(powerOnSchedule)
                }
                if shutdownEnabled && !shutdownDays.isEmpty {
                    schedulesToApply.append(shutdownSchedule)
                }
                
                var command = "sudo pmset repeat"
                if schedulesToApply.isEmpty {
                    command += " cancel"
                } else {
                    for schedule in schedulesToApply {
                        command += " \(schedule.type) \(schedule.days.joined()) \(schedule.time)"
                    }
                }
                
                alertMessage = String(localized: "This will execute the following command:\n\n%@") + "\n\n" + command
                showingAlert = true
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(LocalizedStringKey("Confirm")),
                    message: Text(alertMessage),
                    primaryButton: .default(Text(LocalizedStringKey("Apply"))) {
                        let powerOnSchedule = Schedule(type: "wakeorpoweron", days: convertFullDaysToShort(days: powerOnDays), time: timeString(from: powerOnTime))
                        let shutdownSchedule = Schedule(type: "shutdown", days: convertFullDaysToShort(days: shutdownDays), time: timeString(from: shutdownTime))
                        
                        var schedulesToApply = [Schedule]()
                        if powerOnEnabled && !powerOnDays.isEmpty {
                            schedulesToApply.append(powerOnSchedule)
                        }
                        if shutdownEnabled && !shutdownDays.isEmpty {
                            schedulesToApply.append(shutdownSchedule)
                        }
                        
                        pmsetManager.setSchedules(schedules: schedulesToApply) { success in
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
            let lines = scheduleString.split(whereSeparator: \.isNewline)
            for line in lines {
                if line.contains("wakeorpoweron") {
                    powerOnEnabled = true
                    let components = line.split(separator: " ")
                    if let timeIndex = components.firstIndex(where: { $0.contains(":") }) {
                        let timeString = String(components[timeIndex])
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm:ss"
                        if let date = formatter.date(from: timeString) {
                            powerOnTime = date
                        }
                        let daysString = String(components[timeIndex - 1])
                        powerOnDays = convertShortDaysToFull(days: daysString)
                    }
                } else if line.contains("shutdown") {
                    shutdownEnabled = true
                    let components = line.split(separator: " ")
                    if let timeIndex = components.firstIndex(where: { $0.contains(":") }) {
                        let timeString = String(components[timeIndex])
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm:ss"
                        if let date = formatter.date(from: timeString) {
                            shutdownTime = date
                        }
                        let daysString = String(components[timeIndex - 1])
                        shutdownDays = convertShortDaysToFull(days: daysString)
                    }
                }
            }
        }
    }

    private func convertShortDaysToFull(days: String) -> Set<String> {
        let dayMap = [
            "M": "Monday",
            "T": "Tuesday",
            "W": "Wednesday",
            "R": "Thursday",
            "F": "Friday",
            "S": "Saturday",
            "U": "Sunday"
        ]
        var fullDays = Set<String>()
        for char in days {
            if let day = dayMap[String(char)] {
                fullDays.insert(day)
            }
        }
        return fullDays
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func convertFullDaysToShort(days: Set<String>) -> [String] {
        let dayMap = [
            "Monday": "M",
            "Tuesday": "T",
            "Wednesday": "W",
            "Thursday": "R",
            "Friday": "F",
            "Saturday": "S",
            "Sunday": "U"
        ]
        return days.compactMap { dayMap[$0] }.sorted()
    }
}

struct ScheduleView: View {
    let title: LocalizedStringKey
    let iconName: String
    @Binding var time: Date
    @Binding var days: Set<String>
    @Binding var isEnabled: Bool
    
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isEnabled) {
                HStack {
                    Image(systemName: iconName)
                        .font(.headline)
                    Text(title)
                        .font(.headline)
                }
            }
            .toggleStyle(.switch)
            
            DatePicker(LocalizedStringKey("Time"), selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading) {
                ForEach(weekdays, id: \.self) { day in
                    Toggle(isOn: Binding(
                        get: { days.contains(day) },
                        set: {
                            if $0 {
                                days.insert(day)
                            } else {
                                days.remove(day)
                            }
                        }
                    )) {
                        Text(LocalizedStringKey(day))
                            .frame(width: 80, alignment: .leading) // Adjust width as needed for alignment
                    }
                    .toggleStyle(.switch)
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