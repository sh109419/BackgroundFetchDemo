//
//  AppDelegate.swift
//  BackgroundFetchDemo
//
//  Created by hyf on 2018/8/28.
//  Copyright © 2018年 Deng Junqiang. All rights reserved.
//

import UIKit
import UserNotifications
import os.log


// cache data while background fetch
var airData: [String: Any]?


@UIApplicationMain
class AppDelegate: UIResponder {

    var window: UIWindow?
    
    /// The URLRequest for seeing if there is data to fetch.
    
    fileprivate var fetchRequest: URLRequest {
        // create this however appropriate for your app
        //创建NSURL对象
        let url = URL(string: "https://api.waqi.info/feed/Heihe/?token=demo")
        //创建请求对象
        let request: URLRequest = URLRequest(url: url!)
        
        return request
    }
    
    /// A `OSLog` with my subsystem, so I can focus on my log statements and not those triggered
    /// by iOS internal subsystems. This isn't necessary (you can omit the `log` parameter to `os_log`,
    /// but it just becomes harder to filter Console for only those log statements this app issued).
    
    fileprivate let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "myLog")
}

// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // turn on background fetch
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // issue log statement that app launched
        os_log("didFinishLaunching", log: log)
        
        // turn on user notifications if you want them
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        os_log("applicationWillEnterForeground", log: log)
        //ViewController().refresh() --->Fatal error: Unexpectedly found nil while unwrapping an Optional value
        //let viewController = window?.rootViewController as! ViewController
        //viewController.refresh()
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        os_log("performFetchWithCompletionHandler", log: log)
        processRequest(completionHandler: completionHandler)
    }
    
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // run if app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        os_log("willPresent %{public}@", log: log, notification)
        completionHandler(.alert)
    }
    
    // run after clicking the popup notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        os_log("didReceive %{public}@", log: log, response)
        completionHandler()
    }
}

// MARK: - Various utility methods

extension AppDelegate {
    
    /// Issue and process request to see if data is available
    ///
    /// - Parameters:
    ///   - prefix: Some string prefix so I know where request came from (i.e. from ViewController or from background fetch; we'll use this solely for logging purposes.
    ///   - completionHandler: If background fetch, this is the handler passed to us by`performFetchWithCompletionHandler`.
    
    func processRequest(completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
        let task = URLSession.shared.dataTask(with: fetchRequest) { data, response, error in
            
            // since I have so many paths execution, I'll `defer` this so it captures all of them
            
            var result = UIBackgroundFetchResult.failed
            var message = "Unknown"
            
            defer {
                self.postNotification(message)
                completionHandler?(result)
            }
            
            // handle network errors
            
            guard let data = data, error == nil else {
                message = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                return
            }
            
            // my web service returns JSON with key of `success` if there's data to fetch, so check for that
            
            guard
                let json = try? JSONSerialization.jsonObject(with: data),
                let dictionary = json as? [String: Any],
                let status = dictionary["status"] as? String
            else {
                    message = "JSON parsing failed"
                    return
            }
            
            // report back whether there is data to fetch or not
            let success = status.isEqual("ok")
            if success {
                result = .newData
                message = "New Data"
                airData = dictionary["data"] as? [String: Any]// update data in memory
            } else {
                result = .noData
                message = "No Data"
            }
        }
        task.resume()
    }
    
    /// Post notification if app is running in the background.
    ///
    /// - Parameters:
    ///
    ///   - message:           `String` message to be posted.
    
    func postNotification(_ message: String) {
        
        // if background fetch, let the user know that there's data for them
        
        let content = UNMutableNotificationContent()
        content.title = "MyApp"
        content.body = message
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let notification = UNNotificationRequest(identifier: "timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(notification)
        
        // for debugging purposes, log message to console
        
        os_log("postNotification %{public}@", log: self.log, message)  // need `public` for strings in order to see them in console ... don't log anything private here like user authentication details or the like
    }
    
}
