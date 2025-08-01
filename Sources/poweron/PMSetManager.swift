
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
    
    func setSchedule(schedule: Schedule, completion: @escaping (Bool) -> Void) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        
        let days = schedule.days.joined()
        task.arguments = ["sudo", "pmset", "repeat", schedule.type, days, schedule.time]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        completion(task.terminationStatus == 0)
    }
}
