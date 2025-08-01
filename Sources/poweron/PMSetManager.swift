
import Foundation

struct Schedule {
    var type: String
    var days: [String]
    var time: String
}

class PMSetManager {
    
    func getSchedule(completion: @escaping (String) -> Void) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["pmset", "-g", "sched"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        completion(output)
    }
    
    func setSchedules(schedules: [Schedule], completion: @escaping (Bool) -> Void) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        
        var arguments = ["sudo", "pmset", "repeat"]
        if schedules.isEmpty {
            arguments.append("cancel")
        } else {
            for schedule in schedules {
                let days = schedule.days.joined()
                if !days.isEmpty && !schedule.time.isEmpty {
                    arguments.append(schedule.type)
                    arguments.append(days)
                    arguments.append(schedule.time)
                }
            }
        }
        
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        _ = String(data: data, encoding: .utf8) ?? ""
        
        completion(task.terminationStatus == 0)
    }
}
