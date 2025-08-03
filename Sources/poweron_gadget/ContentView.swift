import SwiftUI

struct ContentView: View {
    @State private var powerOnTime = defaultPowerOnTime()
    @State private var powerOnDays: Set<String> = []
    @State private var powerOnEnabled = false
    
    @State private var shutdownTime = defaultShutdownTime()
    @State private var shutdownDays: Set<String> = []
    @State private var shutdownEnabled = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Confirm"
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var isLoadingSchedule = true
    
    private let pmsetManager = PMSetManager()
    
    var body: some View {
        VStack {
            Text(LocalizedStringKey("The Missing On/Off Scheduler for macOS"))
                .font(.largeTitle)
                .padding()
            
            if isLoadingSchedule {
                ProgressView(LocalizedStringKey("Loading current schedule..."))
                    .padding()
            } else {
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
                // Validate configuration
                if !validateConfiguration() {
                    return
                }
                
                let powerOnSchedule = Schedule(type: "wakeorpoweron", days: convertFullDaysToShort(days: powerOnDays), time: timeString(from: powerOnTime))
                let shutdownSchedule = Schedule(type: "shutdown", days: convertFullDaysToShort(days: shutdownDays), time: timeString(from: shutdownTime))
                
                var schedulesToApply = [Schedule]()
                if powerOnEnabled && !powerOnDays.isEmpty {
                    schedulesToApply.append(powerOnSchedule)
                }
                if shutdownEnabled && !shutdownDays.isEmpty {
                    schedulesToApply.append(shutdownSchedule)
                }
                
                var command = "pmset repeat"
                if schedulesToApply.isEmpty {
                    command += " cancel"
                } else {
                    for schedule in schedulesToApply {
                        command += " \(schedule.type) \(schedule.days.joined()) \(schedule.time)"
                    }
                }
                
                alertTitle = "Confirm"
                alertMessage = String(localized: "This will set the following power schedule:\n\n%@") + "\n\n" + command
                showingAlert = true
                }
                .disabled(isProcessing || isLoadingSchedule)
                .padding()
            }
            
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
        .padding()
        .onAppear(perform: loadSchedule)
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
                    
                    isProcessing = true
                    pmsetManager.setSchedules(schedules: schedulesToApply) { result in
                        DispatchQueue.main.async {
                            isProcessing = false
                            switch result {
                            case .success:
                                // Success - optionally show success message
                                break
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                showingErrorAlert = true
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(LocalizedStringKey("Error"), isPresented: $showingErrorAlert) {
            Button(LocalizedStringKey("OK")) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func validateConfiguration() -> Bool {
        // Check if at least one schedule is enabled
        if !powerOnEnabled && !shutdownEnabled {
            errorMessage = String(localized: "Please enable at least one schedule")
            showingErrorAlert = true
            return false
        }
        
        // Check if enabled schedules have days selected
        if powerOnEnabled && powerOnDays.isEmpty {
            errorMessage = String(localized: "Please select at least one day for Power On schedule")
            showingErrorAlert = true
            return false
        }
        
        if shutdownEnabled && shutdownDays.isEmpty {
            errorMessage = String(localized: "Please select at least one day for Shutdown schedule")
            showingErrorAlert = true
            return false
        }
        
        // Check for potential conflicts
        if powerOnEnabled && shutdownEnabled {
            let powerOnHour = Calendar.current.component(.hour, from: powerOnTime)
            let powerOnMinute = Calendar.current.component(.minute, from: powerOnTime)
            let shutdownHour = Calendar.current.component(.hour, from: shutdownTime)
            let shutdownMinute = Calendar.current.component(.minute, from: shutdownTime)
            
            let powerOnMinutes = powerOnHour * 60 + powerOnMinute
            let shutdownMinutes = shutdownHour * 60 + shutdownMinute
            
            // Warn if shutdown is within 5 minutes of power on
            if abs(shutdownMinutes - powerOnMinutes) < 5 {
                errorMessage = String(localized: "Warning: Shutdown time is very close to Power On time. This may cause issues.")
                showingErrorAlert = true
                return false
            }
        }
        
        return true
    }
    
    private func loadSchedule() {
        pmsetManager.getSchedule { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let scheduleString):
                    // Reset to defaults first
                    self.powerOnEnabled = false
                    self.shutdownEnabled = false
                    self.powerOnDays = []
                    self.shutdownDays = []
                    
                    let lines = scheduleString.split(whereSeparator: \.isNewline)
                    var hasSchedule = false
                    
                    for line in lines {
                        if line.contains("wakeorpoweron") {
                            hasSchedule = true
                            self.powerOnEnabled = true
                            let components = line.split(separator: " ")
                            if let timeIndex = components.firstIndex(where: { $0.contains(":") }) {
                                let timeString = String(components[timeIndex])
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm:ss"
                                if let date = formatter.date(from: timeString) {
                                    self.powerOnTime = date
                                }
                                if timeIndex > 0 {
                                    let daysString = String(components[timeIndex - 1])
                                    self.powerOnDays = self.convertShortDaysToFull(days: daysString)
                                }
                            }
                        } else if line.contains("shutdown") {
                            hasSchedule = true
                            self.shutdownEnabled = true
                            let components = line.split(separator: " ")
                            if let timeIndex = components.firstIndex(where: { $0.contains(":") }) {
                                let timeString = String(components[timeIndex])
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm:ss"
                                if let date = formatter.date(from: timeString) {
                                    self.shutdownTime = date
                                }
                                if timeIndex > 0 {
                                    let daysString = String(components[timeIndex - 1])
                                    self.shutdownDays = self.convertShortDaysToFull(days: daysString)
                                }
                            }
                        }
                    }
                    
                    // If no schedule found, keep the default times
                    if !hasSchedule {
                        self.powerOnTime = Self.defaultPowerOnTime()
                        self.shutdownTime = Self.defaultShutdownTime()
                    }
                    
                case .failure(let error):
                    // On failure, use default times
                    print("Failed to load existing schedule: \(error.localizedDescription)")
                    self.powerOnTime = Self.defaultPowerOnTime()
                    self.shutdownTime = Self.defaultShutdownTime()
                }
                
                // Mark loading as complete
                self.isLoadingSchedule = false
            }
        }
    }
    
    private static func defaultPowerOnTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }
    
    private static func defaultShutdownTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
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