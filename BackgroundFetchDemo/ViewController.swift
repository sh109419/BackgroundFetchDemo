//
//  ViewController.swift
//  BackgroundFetchDemo
//
//  Created by hyf on 2018/8/28.
//  Copyright © 2018年 Deng Junqiang. All rights reserved.
//

/*
    How to call ViewController.refresh() when "UIApplicationWillEnterForeground"
 
    1) at AppDelegate.swift
    func applicationWillEnterForeground(_ application: UIApplication) {
        let viewController = window?.rootViewController as! ViewController
        viewController.refresh()
    }
    * set refresh() to PUBLIC
 
    2) to register for UIApplicationWillEnterForeground Notification in your ViewController
    sample as this file

 
 */

import UIKit
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var lbRefresh: UILabel!
    
    // update label after background fetch data
    
    @objc private func applicationWillEnterForeground(notification: NSNotification) {
        print("applicationWillEnterForeground@ViewController")
        refresh()
    }

    private func refresh() {
        guard
            let data = airData,
            let city = data["city"] as? [String: Any],
            let name = city["name"] as? String
            else { return }
        
        lbRefresh.text = name
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register for UIApplicationWillEnterForeground Notification
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
        
        
        // request authorization to perform user notifications
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { granted, error in
            if !granted {
                // check if notifications are enabled
                // Either denied or notDetermined
                let alertController = UIAlertController(title: "Notification Alert",
                                                        message: "please enable notifications",
                                                        preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        })
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }


}

