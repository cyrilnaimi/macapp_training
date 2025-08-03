import Foundation
import PowerOnShared

class PowerOnHelper: NSObject, NSXPCListenerDelegate, PowerOnHelperProtocol {
    
    private let listener: NSXPCListener
    
    override init() {
        self.listener = NSXPCListener(machServiceName: PowerOnHelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }
    
    func run() {
        self.listener.resume()
        RunLoop.current.run()
    }
    
    // MARK: - NSXPCListenerDelegate
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: PowerOnHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
    
    // MARK: - PowerOnHelperProtocol
    
    func setSchedules(_ schedules: [[String: String]], reply: @escaping (Bool, String?) -> Void) {
        var arguments = ["pmset", "repeat"]
        
        if schedules.isEmpty {
            arguments.append("cancel")
        } else {
            for schedule in schedules {
                guard let type = schedule["type"],
                      let days = schedule["days"],
                      let time = schedule["time"] else {
                    reply(false, "Invalid schedule format")
                    return
                }
                
                if !days.isEmpty && !time.isEmpty {
                    arguments.append(type)
                    arguments.append(days)
                    arguments.append(time)
                }
            }
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = arguments
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                reply(true, nil)
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                reply(false, errorString)
            }
        } catch {
            reply(false, error.localizedDescription)
        }
    }
    
    func getSchedule(reply: @escaping (String?, String?) -> Void) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["pmset", "-g", "sched"]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if task.terminationStatus == 0 {
                // Even with success, pmset might return empty output if no schedules
                reply(output.isEmpty ? "No scheduled events." : output, nil)
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                reply(nil, errorString)
            }
        } catch {
            reply(nil, error.localizedDescription)
        }
    }
    
    func cancelAllSchedules(reply: @escaping (Bool, String?) -> Void) {
        setSchedules([], reply: reply)
    }
}