import Foundation

@objc public protocol PowerOnHelperProtocol {
    func setSchedules(_ schedules: [[String: String]], reply: @escaping (Bool, String?) -> Void)
    func getSchedule(reply: @escaping (String?, String?) -> Void)
    func cancelAllSchedules(reply: @escaping (Bool, String?) -> Void)
}

public struct PowerOnHelperConstants {
    public static let machServiceName = "com.naimicyril.poweron.helper"
}