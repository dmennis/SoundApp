//
//  AppDelegate.swift
//  Sound
//
//  Created by Hills, Dennis on 1/15/18.
//  Copyright © 2018 Hills, Dennis. All rights reserved.
//

import UIKit
import UserNotifications
import AudioToolbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Check if the app was launched from a remote push notification, otherwise do nothing
        // Note: This is the entry point for all remote push notifications if the app is not running in the foreground
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            guard let userInfo = notification["userInfo"] as! Dictionary<AnyHashable,Any>? else {
                return false
            }
            print("Received push notification while app was backgrounded: \(userInfo)")

            // Send notification to the push notification handler
            pushNotificationHandler(userInfo: userInfo)
        }
      
        // Register for push notifications everytime the app launches
        registerForPushNotifications()
        
        return true
    }
    
    // This is where remote push notifications come in when the app is running in the FOREGROUND or user selects alert from notification center
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let state =  UIApplication.shared.applicationState
        if state == .active {
            print("Received push notification while app was in foreground \(userInfo)")

            // Send notification to the push handler
            pushNotificationHandler(userInfo: userInfo)
        }
        else
        {
            print("User selected the alert from notification center while app was backgrounded \(userInfo)")
        }
    }
    
    // Push Notification handler for all app states
    func pushNotificationHandler(userInfo: Dictionary<AnyHashable,Any>) {
        // Parse any data key/value pairs in userInfo
        let dataPayload = userInfo as! [String: AnyObject]
        if let myKeyVal = dataPayload["myKey"] as? String {
            print("myKey value is: \(myKeyVal)")
        }
        
        // Parse the aps payload
        let apsPayload = userInfo["aps"] as! [String: AnyObject]
        print("Entered pushNotificationReceiver() with payload: \(apsPayload)")
    
        // Play custom push notification sound (if exists) by parsing out the "sound" key and playing the audio file specified
        // For example, if the incoming payload is: { "sound":"tarzanwut.aiff" } the app will look for the tarzanwut.aiff file in the app bundle and play it
        if let mySoundFile : String = apsPayload["sound"] as? String {
            print("sound filename: \(mySoundFile)")
            playSound(fileName: mySoundFile)
        }
    }
    
    // Play the specified audio file with extension
    func playSound(fileName: String) {
        var sound: SystemSoundID = 0
        if let soundURL = Bundle.main.url(forAuxiliaryExecutable: fileName) {
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
            AudioServicesPlaySystemSound(sound)
        }
    }
    
    // Called everytime the app is loaded
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print("Permission granted: \(granted)")
            
            // It's important to get push settings whenever the app finishes launching because
            // the user can, at any time, go into the settings and change the notification permissions
            guard granted else { return }
            self.getPushNotificationSettings()
        }
    }
    
    // Returns the push notification settings the user has granted
    func getPushNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Current push notification settings: \(settings)")
            
            // Verify the authorizationStatus IS authorized, meaning the user has granted push notification permissions
            // If user has authorized, call registerForRemoteNotifications()
            guard settings.authorizationStatus == .authorized else { return }
            
            // registerForRemoteNotifications() must be called from the main thread
            DispatchQueue.main.async(execute: {
                UIApplication.shared.registerForRemoteNotifications()
            })
        }
    }
    
    // Successfully registered for push notifications. If token changed from previous, update your provider.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        // Send device token to provider, if new or changed
        
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
    }
    
    // Failed registering for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for push notifications: \(error)")
    }
    
    //From https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG////SchedulingandHandlingLocalNotifications.html#//apple_ref/doc/uid/TP40008194-CH5-SW2
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // The user dismissed the notification without taking action
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // The user launched the app from the notification
        }
        
        // Else handle any custom actions. . .
        if response.notification.request.content.categoryIdentifier == "TIMER_EXPIRED" {
            // Handle the actions for the expired timer.
            if response.actionIdentifier == "SNOOZE_ACTION" {
                // Invalidate the old timer and create a new one. . .
            }
            else if response.actionIdentifier == "STOP_ACTION" {
                // Invalidate the timer. . .
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Reset the push notification badge count
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

