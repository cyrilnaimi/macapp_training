import Foundation
import ServiceManagement
import Security
import PowerOnShared

struct Schedule {
    var type: String
    var days: [String]
    var time: String
    
    var dictionary: [String: String] {
        return [
            "type": type,
            "days": days.joined(),
            "time": time
        ]
    }
}

enum PMSetError: LocalizedError {
    case helperConnectionFailed
    case helperInstallationFailed(String)
    case authorizationFailed
    case invalidConfiguration(String)
    case helperCommunicationError(String)
    
    var errorDescription: String? {
        switch self {
        case .helperConnectionFailed:
            return "Failed to connect to the helper tool. Please try reinstalling the application."
        case .helperInstallationFailed(let message):
            return "Failed to install helper tool: \(message)"
        case .authorizationFailed:
            return "Authorization failed. Please enter your administrator password when prompted."
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .helperCommunicationError(let message):
            return "Communication error: \(message)"
        }
    }
}

class PMSetManager {
    
    private var helperConnection: NSXPCConnection?
    private var authRef: AuthorizationRef?
    
    init() {
        setupAuthorization()
    }
    
    deinit {
        helperConnection?.invalidate()
        if let authRef = authRef {
            AuthorizationFree(authRef, [])
        }
    }
    
    private func setupAuthorization() {
        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        if status == errAuthorizationSuccess {
            self.authRef = authRef
        }
    }
    
    private func installHelper(completion: @escaping (Result<Void, PMSetError>) -> Void) {
        guard let authRef = authRef else {
            completion(.failure(.authorizationFailed))
            return
        }
        
        let rightName = kSMRightBlessPrivilegedHelper
        
        var authItem = rightName.withCString { cString in
            AuthorizationItem(
                name: cString,
                valueLength: 0,
                value: nil,
                flags: 0
            )
        }
        
        let authFlags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
        
        let status = withUnsafeMutablePointer(to: &authItem) { authItemPtr in
            var authRights = AuthorizationRights(count: 1, items: authItemPtr)
            return AuthorizationCopyRights(
                authRef,
                &authRights,
                nil,
                authFlags,
                nil
            )
        }
        
        if status != errAuthorizationSuccess {
            completion(.failure(.authorizationFailed))
            return
        }
        
        var error: Unmanaged<CFError>?
        let result = SMJobBless(
            kSMDomainSystemLaunchd,
            "com.naimicyril.poweron.helper" as CFString,
            authRef,
            &error
        )
        
        if result {
            completion(.success(()))
        } else {
            let errorMessage = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            completion(.failure(.helperInstallationFailed(errorMessage)))
        }
    }
    
    private func connectToHelper(completion: @escaping (Result<NSXPCConnection, PMSetError>) -> Void) {
        if let connection = helperConnection {
            completion(.success(connection))
            return
        }
        
        let connection = NSXPCConnection(machServiceName: PowerOnHelperConstants.machServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: PowerOnHelperProtocol.self)
        
        connection.invalidationHandler = { [weak self] in
            self?.helperConnection = nil
        }
        
        connection.interruptionHandler = { [weak self] in
            self?.helperConnection = nil
        }
        
        connection.resume()
        
        let helper = connection.remoteObjectProxyWithErrorHandler { error in
            completion(.failure(.helperCommunicationError(error.localizedDescription)))
        } as? PowerOnHelperProtocol
        
        if helper != nil {
            self.helperConnection = connection
            completion(.success(connection))
        } else {
            // Helper not installed, try to install it
            installHelper { [weak self] result in
                switch result {
                case .success:
                    // Retry connection after installation
                    self?.helperConnection = nil
                    self?.connectToHelper(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getSchedule(completion: @escaping (Result<String, PMSetError>) -> Void) {
        connectToHelper { result in
            switch result {
            case .success(let connection):
                let helper = connection.remoteObjectProxyWithErrorHandler { error in
                    completion(.failure(.helperCommunicationError(error.localizedDescription)))
                } as? PowerOnHelperProtocol
                
                helper?.getSchedule { scheduleString, errorString in
                    if let scheduleString = scheduleString {
                        completion(.success(scheduleString))
                    } else {
                        completion(.failure(.helperCommunicationError(errorString ?? "Unknown error")))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setSchedules(schedules: [Schedule], completion: @escaping (Result<Void, PMSetError>) -> Void) {
        // Validate schedules
        for schedule in schedules {
            if schedule.days.isEmpty && !schedules.isEmpty {
                completion(.failure(.invalidConfiguration("Schedule enabled but no days selected")))
                return
            }
            
            if schedule.time.isEmpty {
                completion(.failure(.invalidConfiguration("Invalid time format")))
                return
            }
        }
        
        connectToHelper { result in
            switch result {
            case .success(let connection):
                let helper = connection.remoteObjectProxyWithErrorHandler { error in
                    completion(.failure(.helperCommunicationError(error.localizedDescription)))
                } as? PowerOnHelperProtocol
                
                let scheduleDicts = schedules.map { $0.dictionary }
                
                helper?.setSchedules(scheduleDicts) { success, errorString in
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.helperCommunicationError(errorString ?? "Unknown error")))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}