/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */



// MARK: - Swift 3

#if swift(>=3.0)

import UIKit
import Foundation
import IBMMobileFirstPlatformFoundation
import SSZipArchive

// MARK: -

// Get the device type as a human-readable string
// http://stackoverflow.com/questions/26028918/ios-how-to-determine-iphone-model-in-swift
internal extension UIDevice {

    var modelName: String {

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in

            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":       return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                   return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                   return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                   return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":  return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":            return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":            return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":            return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":            return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":            return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":            return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                       return identifier
        }
    }
}

@objc public class Feedback : NSObject {

    struct FeedbackJson {
        let id: String
        let comments: [String]
        let screenName: String
        let screenWidth: Int
        let screenHeight: Int
        let sessionID: String
        let username: String
        var timeSent: String

        init(json: [String: Any]) {
            id = json["id"] as? String ?? ""
            comments = json["comments"] as? [String] ?? []
            screenName = json["screenName"] as? String ?? ""
            screenWidth = json["screenWidth"] as? Int ?? 0
            screenHeight = json["screenHeight"] as? Int ?? 0
            sessionID = json["sessionID"] as? String ?? ""
            username = json["username"] as? String ?? ""
            timeSent = json["timeSent"] as? String ?? ""
        }

        var dictionaryRepresentation: [String: Any] {
            return [
                "id": id,
                "comments": comments,
                "screenName": screenName,
                "screenWidth": screenWidth,
                "screenHeight": screenHeight,
                "sessionID": sessionID,
                "username": username,
                "timeSent": timeSent
            ]
        }
    }

    struct SendEntry {
        var timeSent: String
        var sendArray: [String]
        init(timeSent: String, sendArray: [String]) {
            self.timeSent = timeSent
            self.sendArray = sendArray
        }
    }

    struct AppFeedBackSummary {
        var saved: [String]
        var send: [SendEntry]

        init(json: [String: Any]) {
            self.saved = json["saved"] as? [String] ?? []
            self.send = []
            let sendArray: [String: [String]] = (json["send"] as? [String: [String]]) ?? [:]
            for key in sendArray.keys {
                send.append(SendEntry(timeSent: key, sendArray: sendArray[key]!))
            }
        }

        func jsonRepresentation() -> String {
            var savedString: String = "["
            for i in 0..<self.saved.count {
                savedString = savedString + "\""+self.saved[i]+"\""
                if i != self.saved.count-1 {
                    savedString = savedString + ","
                }
            }
            savedString = savedString + "]"

            var sendArray: String = "{"
            for i in 0..<self.send.count {
                let ts: String = "\""+self.send[i].timeSent+"\""+":"
                var sa: String = "["
                for j in 0..<self.send[i].sendArray.count {
                    sa = sa + "\"" + self.send[i].sendArray[j] + "\""
                    if j != self.send[i].sendArray.count-1 {
                        sa = sa + ","
                    }
                }
                sa = sa + "]"
                if i != self.send.count-1 {
                    sa = sa + ","
                }
                sendArray = sendArray + ts + sa
            }
            sendArray = sendArray + "}"

            let returnStr: String = "{\"saved\":"+savedString+", \"send\":"+sendArray+"}"
            return returnStr
        }

        var dictionaryRepresentation: [String: Any] {
            return [
                "saved": self.saved,
                "send": self.send
            ]
        }
    }

    internal static var currentlySendingFeedbackdata = false
    static var screenshot: UIImage?
    static var messages: [String] = [String]()
    static var instanceName: String?
    static var creationDate: String?
    static var timeSent: String?
    static var LOGGER_PKG = "wl.feedback"
    static var FILENAME_FEEDBACK_LOCATION = "/feedback"
    static var globalDocumentPath = ""
    static var returnValue: Int = 0
    
    static var staticUserId = ""
    static var staticSessionId = ""
    static var staticDeviceId = ""
    static var staticUrl = ""
    static var staticApiKey = ""
    static var staticAppName = ""

    @objc
    public func invokeFeedback(_ userId: String, withSessionId:String, withDeviceId: String, withUrl: String, withApiKey: String, withAppName: String, withMethodName: String) -> Int {
        Feedback.staticUserId = userId
        Feedback.staticSessionId = withSessionId
        Feedback.staticDeviceId = withDeviceId
        Feedback.staticUrl = withUrl
        Feedback.staticApiKey = withApiKey
        Feedback.staticAppName = withAppName
        if(withMethodName == "triggerFeedbackMode"){
            DispatchQueue.main.async(execute: {
                Feedback.invokeFeedback()
            })
            if(Feedback.returnValue == 1 ) {
                Feedback.returnValue = 0
                return 1
            }else{
                return 0
            }
        }else if(withMethodName == "triggerSendFeedback"){
            Feedback.send(fromSentButton: false)
        }
        return 0
    }
    
    public static func invokeFeedback() -> Void {
        //let bmsClient = BMSClient.sharedInstance
        //if bmsClient.bluemixRegion == nil || bmsClient.bluemixRegion == "" {
        //    BMSLogger.internalLogger.error(message: "Failed to invoke feedback mode because the client was not yet initialized. Make sure that the BMSClient class has been initialized.")
        //} else {
            messages = [String]()
            instanceName = ""
            screenshot=nil

            let uiViewController:UIViewController?
            //if BMSAnalytics.callersUIViewController != nil {
            //    uiViewController = BMSAnalytics.callersUIViewController
            //} else {
                uiViewController = topController(nil)
            //}

            let instance: String = NSStringFromClass(uiViewController!.classForCoder)
            Feedback.instanceName = instance.replacingOccurrences(of: "_", with: "")
            Feedback.creationDate = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
            takeScreenshot(uiViewController!.view)

            let feedbackBundle = Bundle(for: UIImageControllerViewController.self)
            let feedbackStoryboard: UIStoryboard!
            feedbackStoryboard = UIStoryboard(name: "Feedback", bundle: feedbackBundle)
            let feedbackViewController: UIViewController = feedbackStoryboard.instantiateViewController(withIdentifier: "feedbackImageView")
            uiViewController!.present(feedbackViewController, animated: true, completion: nil)
        //}
    }

    public static func send(fromSentButton: Bool) -> Void {
        
        /* Sudo code:
         If called from send action
         - Save Image
         - Save other image related info into json file
         - Update summary json (AppFeedBackSummary.json)
         fi
         -Get the list of images need to send
         -iterate the list
         - Add timeSent to feedback.json
         - create zip and send
         - Send the file
         - if Sucess Update summary json (AppFeedBackSummary.json)
         */

        if fromSentButton == true {
            saveImage(Feedback.screenshot!)
            createFeedbackJsonFile()
            updateSummaryJsonFile(getInstanceName(), timesent: "", remove: false)
        }
        let filesToSend: [String] = getListOfFeedbackFilesToSend()
        if filesToSend.count != 0 {
            NSLog("[DEBUG] [FEEDBACK]","filesToSend count = \(String(filesToSend.count))")
            for i in 0..<filesToSend.count {
                NSLog("[DEBUG] [FEEDBACK]","filesToSend = \(filesToSend[i])")
                if FileManager.default.fileExists(atPath: getDocumentPath(FILENAME_FEEDBACK_LOCATION+"/") + filesToSend[i]){
                    Feedback.timeSent = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
                    Feedback.timeSent = addAndReturnTimeSent(instanceName: filesToSend[i], timeSent: Feedback.timeSent!)
                    let zippath = createZip(instanceName: filesToSend[i])
                    if(!zippath.isEmpty) {
                        sendFeedback(instanceName: filesToSend[i])
                    }
                }
            }
        } else {
            NSLog("[DEBUG] [FEEDBACK]","Nothing to Send")
        }
    }

    // MARK: - Internal methods
    internal static func takeScreenshot(_ view: UIView) -> Void {
        DispatchQueue.main.async(execute: {
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
            view.layer.render(in: UIGraphicsGetCurrentContext()!)
            Feedback.screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        })
    }

    internal static func topController(_ parent: UIViewController? = nil) -> UIViewController {
        if let vc = parent {
            if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
                return topController(selected)
            } else if let nav = vc as? UINavigationController, let top = nav.topViewController {
                return topController(top)
            } else if let presented = vc.presentedViewController {
                return topController(presented)
            } else {
                return vc
            }
        } else {
            return topController(UIApplication.shared.keyWindow!.rootViewController!)
        }
    }

    internal static func getiOSDeviceInfo() -> (String, String) {

        var osVersion = "", model = ""

        let device = UIDevice.current
        osVersion = device.systemVersion
        model = device.modelName

        return (osVersion, model)
    }
    
    internal static var sdkVersion: String {

        if let bundle = Bundle(identifier: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics") {
            return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        }
        return ""
    }
    
    internal static func generateOutboundRequestMetadata() -> String? {

        // All of this data will go in a header for the request
        var requestMetadata: [String: String] = [:]

        // Device info
        var osVersion = "", model = ""

        (osVersion, model) = getiOSDeviceInfo()
        requestMetadata["os"] = "iOS"

        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = staticDeviceId
        requestMetadata["mfpAppName"] = staticAppName
        requestMetadata["appStoreLabel"] = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        requestMetadata["appStoreId"] = Bundle.main.bundleIdentifier ?? ""
        requestMetadata["appVersionCode"] = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
        requestMetadata["appVersionDisplay"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        requestMetadata["sdkVersion"] = sdkVersion

        var requestMetadataString: String?

        do {
            let requestMetadataJson = try JSONSerialization.data(withJSONObject: requestMetadata, options: [])
            requestMetadataString = String(data: requestMetadataJson, encoding: .utf8)
        }
        catch let error {
            NSLog("[DEBUG] [FEEDBACK]", "Failed to append analytics metadata to request. Error: \(error)")
        }

        return requestMetadataString
    }
    
    internal static func sendFeedback(instanceName: String) {

        // Wait for sending next file
        while currentlySendingFeedbackdata {
            sleep(1)
        }

        guard !currentlySendingFeedbackdata else {
            NSLog("[DEBUG] [FEEDBACK]", "Ignoring Analytics.sendFeedback() until the previous send request finishes.")
            return
        }

        let zipFile: String = getDocumentPath(FILENAME_FEEDBACK_LOCATION + "/") + instanceName + ".zip"
        let instanceDocPath: String = getDocumentPath(FILENAME_FEEDBACK_LOCATION + "/") + instanceName

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
            do {
                if FileManager.default.fileExists(atPath: zipFile) {
                    let fileurl = URL(fileURLWithPath: zipFile)
                    let fileData = try Data(contentsOf: fileurl)

                    var request: WLResourceRequest? = nil
                    let url: URL = URL(string: staticUrl + "/data/events/inappfeedback/")!
                    request = WLResourceRequest(url: url, method: WLHttpMethodPost)
                    request?.addHeaderValue(staticApiKey as NSObject, forName: "x-mfp-analytics-api-key")
                    request?.addHeaderValue(generateOutboundRequestMetadata()! as NSObject, forName: "x-mfp-analytics-metadata")
                    request?.addHeaderValue("multipart/form-data" as NSObject, forName: "Content-Type")

                    NSLog("[DEBUG] [FEEDBACK]","Send URL: \(url.absoluteString)")
                    NSLog("[DEBUG] [FEEDBACK]","File to send: \(fileurl.absoluteString)")

                    request?.send(with: fileData, completionHandler: { response, error in
                        if error == nil && response?.status == 201 {
                            NSLog("[DEBUG] [FEEDBACK]", "Feedback data successfully sent to the server." + (response?.responseText)! + " \nStatus code: " + String(describing: response?.status))
                            if let responseText = response?.responseText {
                                NSLog("[DEBUG] [FEEDBACK]", "Response text: " + responseText)
                            }

                            do {
                                try FileManager.default.removeItem(atPath: zipFile)
                                try FileManager.default.removeItem(atPath: instanceDocPath)
                            }catch let error{ print(error.localizedDescription)}
                            updateSummaryJsonFile(instanceName, timesent: Feedback.timeSent!, remove: true)
                        }else {
                            do {
                                NSLog("[DEBUG] [FEEDBACK]", "Feedback data failed to send")
                                try FileManager.default.removeItem(atPath: zipFile)
                            }catch let error{ print(error.localizedDescription)}
                        }
                    })
                }
            }catch let error as NSError {
                NSLog("[DEBUG] [FEEDBACK]","Error: " + error.localizedDescription)
            }
        })
    }

    internal static func saveImage(_ image: UIImage) -> Void {
        if let data = UIImagePNGRepresentation(image) {
            var objcBool: ObjCBool = true
            let isExist = FileManager.default.fileExists(atPath: getDocumentPath(FILENAME_FEEDBACK_LOCATION+"/") + getInstanceName() + "/" , isDirectory: &objcBool)

            // If the folder with the given path doesn't exist already, create it
            if isExist == false {
                do {
                    try FileManager.default.createDirectory(atPath: getDocumentPath(FILENAME_FEEDBACK_LOCATION+"/") + getInstanceName() + "/", withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("[DEBUG] [FEEDBACK]","Something went wrong while creating a new folder")
                }
            }

            let filename = getDocumentPath(FILENAME_FEEDBACK_LOCATION+"/") + getInstanceName() + "/image.png"
            NSLog("[DEBUG] [FEEDBACK]","Creating image at" + filename)
            let result = FileManager.default.createFile(atPath: filename, contents: data, attributes: nil)
            if result != true {
                NSLog("[DEBUG] [FEEDBACK]","Failed to create image file")
            }
        }
    }

    internal static func getInstanceName() -> String {
        return Feedback.instanceName!+"_"+Feedback.creationDate!
    }

    // Function adds timeSent to feedback.json if its not exists otherwise returns the timestamp
    internal static func addAndReturnTimeSent(instanceName: String, timeSent: String) -> String {
        let instanceJsonFile: String = getDocumentPath(FILENAME_FEEDBACK_LOCATION+"/") + instanceName+"/feedback.json"
        if FileManager.default.fileExists(atPath: instanceJsonFile) {
            let feedbackData = convertFileToData(filepath: instanceJsonFile)
            do {
                let json = try JSONSerialization.jsonObject(with: feedbackData!, options: JSONSerialization.ReadingOptions.mutableContainers)
                var feedback = FeedbackJson(json: json as! [String: Any])
                if feedback.timeSent.isEmpty {
                    feedback.timeSent=timeSent
                    write(toFile: instanceJsonFile, feedbackdata: convertToJSON(feedback.dictionaryRepresentation)!, append: false)
                    return timeSent
                } else {
                    return feedback.timeSent
                }
            } catch let error {
                NSLog("[DEBUG] [FEEDBACK]", "addTimeSent: Error: " + error.localizedDescription)
            }
        }
        return ""
    }

    internal static func getDocumentPath(_ appendpath: String) -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        globalDocumentPath = paths[0]
        return globalDocumentPath + "/" + appendpath
    }
    
    internal static func getListOfFeedbackFilesToSend() -> [String] {
        let afbsFile = getDocumentPath(FILENAME_FEEDBACK_LOCATION)+"/AppFeedBackSummary.json"
        let afbs = convertFileToData(filepath: afbsFile)
        if afbs != nil {
            do {
                let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
                let summary = AppFeedBackSummary(json: json as! [String: Any])
                return summary.saved
            } catch let jsonErr {
                NSLog("[DEBUG] [FEEDBACK]","getListOfFeedbackFilesToSend: Error : " + jsonErr.localizedDescription)
            }
        }
        return []
    }

    internal static func updateSummaryJsonFile(_ entry: String, timesent: String, remove: Bool) -> Void {
        let afbsFile = getDocumentPath(FILENAME_FEEDBACK_LOCATION)+"/AppFeedBackSummary.json"
        let afbs = convertFileToData(filepath: afbsFile)
        var summary: AppFeedBackSummary
        do {
            if afbs == nil {
                summary = AppFeedBackSummary(json: [:])
            } else {
                let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
                summary = AppFeedBackSummary(json: json as! [String: Any])
            }

            if remove == false {
                summary.saved.append(entry)
            } else {
                if summary.saved.contains(entry) == true {
                    // Remove from saved
                    for i in 0..<summary.saved.count {
                        if summary.saved[i] == entry {
                            summary.saved.remove(at: i)
                            break
                        }
                    }

                    var updated: Bool = false
                    // Add to send
                    for i in 0..<summary.send.count {
                        if summary.send[i].timeSent == timesent {
                            summary.send[i].sendArray.append(entry)
                            updated = true
                            break
                        }
                    }

                    if updated == false {
                        summary.send.append(SendEntry(timeSent: timesent, sendArray: [entry]))
                        updated = true
                    }
                } else {
                    // No need to write anything
                    return
                }
            }
            NSLog("[DEBUG] [FEEDBACK]","updateSummaryJsonFile: FeedbackSummary.json : " + summary.jsonRepresentation())
            write(toFile: afbsFile, feedbackdata: summary.jsonRepresentation(), append: false)
        } catch let jsonErr {
            NSLog("[DEBUG] [FEEDBACK]","updateSummaryJsonFile: Exception:" + jsonErr.localizedDescription)
        }
    }

    internal static func createZip(instanceName: String) -> String {
        let dirToZip = getDocumentPath(FILENAME_FEEDBACK_LOCATION)+"/"+instanceName
        let zipPath = getDocumentPath(FILENAME_FEEDBACK_LOCATION)+"/"+instanceName+".zip"

        let success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: dirToZip)
        if success {
            NSLog("[DEBUG] [FEEDBACK]","Success zip")
            return zipPath;
        } else {
            NSLog("[DEBUG] [FEEDBACK]","No success zip")
            return ""
        }
    }

    internal static func convertFileToString(filepath: String) -> String? {
        let fileURL = URL(fileURLWithPath: filepath)
        var fileContent: String? = ""
        do {
            fileContent = try String(contentsOf: fileURL, encoding: .utf8)
        } catch let error {
           NSLog(error.localizedDescription)
        }
        return fileContent
    }

    internal static func convertFileToData(filepath: String) -> Data? {
        var fileContent: Data? = nil
        do {
            fileContent = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
        } catch let error {
            NSLog(error.localizedDescription)
            return nil
        }
        return fileContent
    }

    internal static func createFeedbackJsonFile() -> Void {
        let screenName = getInstanceName()
        let deviceID: String = staticDeviceId
        let id: String = deviceID + "_" + screenName

        let screenSize = UIScreen.main.bounds
        let screenWidth: Int = Int(screenSize.width)
        let screenHeight: Int = Int(screenSize.height)
        let sessionId: String = staticSessionId
        var userID: String = staticUserId
        
        if userID.isEmpty {
            userID = "UNKNOWN"
        }
        
        let jsonObject: [String: Any] = [
            "id": id,
            "comments": Feedback.messages,
            "screenName": screenName,
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "sessionID": sessionId,
            "username": userID
        ]

        let feedbackJsonString = convertToJSON(jsonObject)
        guard feedbackJsonString != nil else {
            let errorMessage = "Failed to write feedback json data to file. This is likely because the feedback data could not be parsed."
            NSLog("[DEBUG] [FEEDBACK]",errorMessage)
            return
        }
        let filename = getDocumentPath(FILENAME_FEEDBACK_LOCATION+"/")+getInstanceName()+"/feedback.json"
        write(toFile: filename, feedbackdata: feedbackJsonString!, append: false)
    }

    internal static func convertToJSON(_ feedbackData: [String: Any]?) -> String? {
        let logData: Data
        do {
            logData = try JSONSerialization.data(withJSONObject: feedbackData as Any, options: [])
        } catch let error {
            NSLog( "[DEBUG] [FEEDBACK]", "convertToJSON: Error: " + error.localizedDescription)
            return nil
        }

        return String(data: logData, encoding: .utf8)
    }

    // Append log message to the end of the log file
    internal static func write(toFile file: String, feedbackdata: String, append: Bool) {

        do {
            // Remove the file if its already exists
            if append == false {
                if FileManager.default.fileExists(atPath: file) {
                    try FileManager.default.removeItem(atPath: file)
                }
            }

            if !FileManager.default.fileExists(atPath: file) {
                FileManager.default.createFile(atPath: file, contents: nil, attributes: nil)
            }

            let fileHandle = FileHandle(forWritingAtPath: file)
            let data = feedbackdata.data(using: .utf8)

            if fileHandle != nil && data != nil {
                fileHandle!.seekToEndOfFile()
                fileHandle!.write(data!)
                fileHandle!.closeFile()
            }
            else {
                let errorMessage = "Cannot write to file: \(file)."
                NSLog("[DEBUG] [FEEDBACK]",errorMessage)
            }
        } catch {}
    }

}

// **************************************************************************************************
    // MARK: - Swift 2
#else

#endif
