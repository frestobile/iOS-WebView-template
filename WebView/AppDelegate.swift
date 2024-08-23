//  OnlineAppCreator.com
//  WebViewGold for iOS // webviewgold.com

/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */
/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */
/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */

import UIKit
import UserNotifications
import OneSignal
import GoogleMobileAds
import Firebase
import FirebaseMessaging
import SwiftyStoreKit
import AVFoundation
import FBSDKCoreKit
import FBAudienceNetwork
import AppTrackingTransparency
import WonderPush
import Pushwoosh

@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate, PWMessagingDelegate {
    
    var isActive = false
    var orientationLock = UIInterfaceOrientationMask.all
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }

        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
    
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if(kWonderPushEnabled) {
            WonderPush.setClientId(kWonderPushClientId, secret: kWonderPushClientSecret)
            WonderPush.setupDelegate(for: application)
            WonderPush.setupDelegateForUserNotificationCenter()
           
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if (Constants.useFacebookAds){
            FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)
        }
        //handle Universal Link
           if let url = launchOptions?[.url] as? URL {
               handleUniversalLink(url)
           }
        
        
        //handle terminate notification
        if let option = launchOptions {
            let info = option[UIApplication.LaunchOptionsKey.remoteNotification]
            if (info != nil) {
                if let dict = info as? NSDictionary {
                    if let x = dict.value(forKey: "custom") as? NSDictionary {
                        if let y = x.value(forKey: "a") as? NSDictionary{
                            if y.value(forKey: "url") as? String ?? "" != "" {
                                let noti_url = y.value(forKey: "url") as? String ?? ""
                                UserDefaults.standard.set(noti_url, forKey: "Noti_Url")
                                UserDefaults.standard.set(true, forKey: "isFromPush")
                            }
                        }
                        else{
                            UserDefaults.standard.set(nil, forKey: "Noti_Url")
                            UserDefaults.standard.set(false, forKey: "isFromPush")
                        }
                    }
                }
            }
        }
        
        if (Constants.kFirebasePushEnabled && askforpushpermissionatfirstrun)
        {
            UIApplication.shared.registerForRemoteNotifications()
            FirebaseApp.configure()
            registerForPushNotifications(application: application)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: NSNotification.Name.MessagingRegistrationTokenRefreshed, object: nil)

            connectToFcm()

            Messaging.messaging().token { token, error in
              if let error = error {
                print("Error fetching FCM registration token: \(error)")
                UserDefaults.standard.set("", forKey: "FirebaseID")
              } else if let token = token {
                print("FCM registration token: \(token)")
                UserDefaults.standard.set(token, forKey: "FirebaseID")
                self.connectToFcm()
              }
            }
        }
       
       
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                case .failed, .purchasing, .deferred:
                    break 
                @unknown default:
                    break 
                }
            }
        }
        
        if (Constants.kPushEnabled) {
            OneSignal.setAppId(Constants.oneSignalID)
            OneSignal.initWithLaunchOptions(launchOptions)
            OneSignal.setLaunchURLsInApp(false)
        }
        
        let notifWillShowInForegroundHandler: OSNotificationWillShowInForegroundBlock = { notification, completion in
            print("Received Notification: ", notification.notificationId ?? "no id")
            print("launchURL: ", notification.launchURL ?? "no launch url")
            print("content_available = \(notification.contentAvailable)")
            if notification.notificationId == "example_silent_notif" {
                completion(nil)
            } else {
                completion(notification)
            }
        }
        
        let notificationOpenedBlock: OSNotificationOpenedBlock = { result in
            // This block gets called when the user reacts to a notification received
            let notification: OSNotification = result.notification
            print("Message: ", notification.body ?? "empty body")
            print("badge number: ", notification.badge)
            print("notification sound: ", notification.sound ?? "No sound")
                    
            if let additionalData = notification.additionalData {
                print("additionalData: ", additionalData)
                if let actionSelected = notification.actionButtons {
                    print("actionSelected: ", actionSelected)
                }
//                if let actionID = result.action.actionId {
//                    //handle the action
//                }
            }
        }
        
        if (Constants.kPushEnabled) {
            OneSignal.setNotificationOpenedHandler(notificationOpenedBlock)
            OneSignal.setNotificationWillShowInForegroundHandler(notifWillShowInForegroundHandler)
            //        OneSignal.setAppSettings(onesignalInitSettings)
        
        
        if let deviceState = OneSignal.getDeviceState() {
            let userId = deviceState.userId
            print(userId ?? "userId = n/a")
            let pushToken = deviceState.pushToken
            print(pushToken ?? "pushToken = n/a")
            let subscribed = deviceState.isSubscribed
            print(subscribed)
         }
        }
        
        if(kWonderPushEnabled) {
            WonderPush.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        if(kPushwooshEnable) {
            Pushwoosh.sharedInstance().delegate = self;
            Pushwoosh.sharedInstance().registerForPushNotifications()
        }
        
//        let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
//            let payload: OSNotificationPayload = result!.notification.payload
//
//            var fullMessage = payload.body
//
//
//            if payload.additionalData != nil {
//                if payload.title != nil {
//                    let messageTitle = payload.title
//                    print("Message Title = \(messageTitle!)")
//                }
//                
//                let additionalData = payload.additionalData
//                if additionalData?["actionSelected"] != nil {
//                    fullMessage = fullMessage! + "\nPressed ButtonID: \(String(describing: additionalData!["actionSelected"]))"
//                }
//            }
//        }
//        if Constants.kPushEnabled
//        {
//            let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false,
//                                         kOSSettingsKeyInAppLaunchURL: true]
//
//
//            OneSignal.initWithLaunchOptions(launchOptions,appId: Constants.oneSignalID,handleNotificationAction: {(result) in let payload = result?.notification.payload
//                if let additionalData = payload?.additionalData {
//
//                    var noti_url = ""
//                    if additionalData["url"] != nil {
//                    noti_url = additionalData["url"] as! String
//                    }
//                    UserDefaults.standard.set(noti_url, forKey: "Noti_Url")
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithNotificationURL"), object: nil, userInfo: nil)
//
//                }},settings: onesignalInitSettings)
//
//            OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
//
//        }
        if (Constants.showBannerAd || Constants.showFullScreenAd) {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
        if UserDefaults.standard.value(forKey: "IsPurchase") == nil
        {
            UserDefaults.standard.setValue("NO", forKey: "IsPurchase")
        }
        
        if askforpushpermissionatfirstrun {
            registerForPushNotifications(application: application)
        }
        
        
        if Constants.kPushEnabled
        {
            if askforpushpermissionatfirstrun {
                
                OneSignal.promptForPushNotifications(userResponse: { accepted in
                    print("User accepted notifications: \(accepted)")
                })
                if application.responds(to: #selector(getter: application.isRegisteredForRemoteNotifications))
                {
                    if #available(iOS 10.0, *)
                    {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) {(accepted, error) in
                            if !accepted {
                                print("Notification access denied")
                            }
                        }
                    }
                    else
                    {
                        application.registerUserNotificationSettings(UIUserNotificationSettings(types: ([.sound, .alert, .badge]), categories: nil))
                        application.registerForRemoteNotifications()
                    }
                }
                else
                {
                    let center = UNUserNotificationCenter.current()
                            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                                // Enable or disable features based on authorization.
                            }
                            application.registerForRemoteNotifications()
                }
            }
            
            return true
        }
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func deactivatedarkmode() {
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let webpageURL = userActivity.webpageURL else {
            return false
        }
        print("Coming back from background: Universal Link triggered")
        handleUniversalLink(webpageURL)
        return true
    }

    
    
    private func handleUniversalLink(_ url: URL) { //Universal Links API
        if ShowExternalLink{
        if let urlToOpen = url.absoluteString.removingPercentEncoding {
            webviewurl = urlToOpen
                
            UserDefaults.standard.set(webviewurl, forKey: "DeepLinkUrl-applinkstype")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithExternalLink"), object: nil, userInfo: nil)
        }
        }
    }
    
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        
        let deepLink = url.absoluteString
        
        // Check if the URL contains "?link=" (required for Deep Linking API)
        guard deepLink.contains("?link=") else {
            
            if let deepLink = userActivity?.webpageURL {
                handleUniversalLink(deepLink) //Go for Universal Links API as Fallback instead of Deep Linking API
              
            }
            
            return false
        }

        // Collect the deep link URL after "scheme://url?link="
//        if let index = deepLink.firstIndex(of: "=") {
//            let sliceIndex = deepLink.index(after: index)
//            let deepLinkURL: String = String(deepLink[sliceIndex...])
//            
//            // Collect the deep link URL host
//            var deepLinkURLHost = deepLinkURL.replacingOccurrences(of: "www.", with: "")
//            deepLinkURLHost = deepLinkURLHost.replacingOccurrences(of: "https://", with: "")
//            deepLinkURLHost = deepLinkURLHost.replacingOccurrences(of: "http://", with: "")
//            
//            host = deepLinkURLHost
//            webviewurl = deepLinkURL
//
//            if ShowExternalLink{
//                UserDefaults.standard.set(deepLinkURL, forKey: "DeepLinkUrl")
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithExternalLink"), object: nil, userInfo: nil)
//            }
//            return true
//        } else {
//            print("URL missing")
//            return false
//        }
        return ApplicationDelegate.shared.application(application, open: url, options: options)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {


    do {
    if #available(iOS 11.0, *) {
    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longForm, options: [.mixWithOthers, .allowAirPlay])
    } else {
    }
    try AVAudioSession.sharedInstance().setActive(true)
    } catch {
    print(error)
    }

    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                    switch status {
                    case .authorized:
                        // Tracking authorization dialog was shown
                        // and we are authorized
                        print("Authorized")
                    case .denied:
                        // Tracking authorization dialog was
                        // shown and permission is denied
                        print("Denied")
                        if (!Constants.ATTDeniedShowAds) {
                            Constants.useFacebookAds = false;
                            showBannerAd = false;
                            showFullScreenAd = false;
                        }
                    case .notDetermined:
                        // Tracking authorization dialog has not been shown
                        print("Not Determined")
                        if (!Constants.ATTDeniedShowAds) {
                            Constants.useFacebookAds = false;
                            showBannerAd = false;
                            showFullScreenAd = false;
                        }
                    case .restricted:
                        print("Restricted")
                        if (!Constants.ATTDeniedShowAds) {
                            Constants.useFacebookAds = false;
                            showBannerAd = false;
                            showFullScreenAd = false;
                        }
                    @unknown default:
                        print("Unknown")
                    }
                })
            }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
        if (deletecacheonexit){
            NotificationCenter.default.post(name: NSNotification.Name("ApplicationWillTerminate"), object: nil)
        }}
}

extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    func registerForPushNotifications(application: UIApplication)
    {
        if #available(iOS 11.0, *)
        {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            if (Constants.kFirebasePushEnabled)
            {
                // For iOS 10 data message (sent via FCM)
                Messaging.messaging().delegate = self
                print("Notification: registration for iOS >= 11 using UNUserNotificationCenter")
            }
        }
        else
        {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            print("Notification: registration for iOS < 10 using Basic Notification Center")
        }
        
        application.registerForRemoteNotifications()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "n/a")")
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    @objc func tokenRefreshNotification(_ notification: Notification)
    {
        connectToFcm()
    }
    
    func connectToFcm() {
        if (Constants.kFirebasePushEnabled)
        {
            Messaging.messaging().token { token, error in
                if let error = error {
                    UserDefaults.standard.set("", forKey: "FirebaseID")
                    print("Error fetching remote instance ID: \(error)")
                    print("FCM: Token does not exist.")
                } else if let token = token {
                    print("Remote instance ID token: \(token)")
                    UserDefaults.standard.set(token, forKey: "FirebaseID")
                }
            }
        }
    }

    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Notification: Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        print("Registered for Remote Notifications with Device Token")
        if (Constants.kFirebasePushEnabled)
        {
            Messaging.messaging().apnsToken = deviceToken as Data
            
            if (Constants.firebaseTopic != "") {
                Messaging.messaging().subscribe(toTopic: Constants.firebaseTopic) { error in
                    if error != nil {
                        print("Failed to subscribe to topic: \(error!.localizedDescription)")
                    } else {
                        print("Subscribed to Firebase topic: " + Constants.firebaseTopic)
                    }
                }
            }
        }
        
        if(kWonderPushEnabled) {
            WonderPush.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }
    
    func application(application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        
        if let x = userInfo["custom"] as? [AnyHashable: Any] {
            if let y = x["a"] as? [String:String] {
                guard y["url"] != nil else {return}
                let noti_url = y["url"]!
                UserDefaults.standard.set(noti_url, forKey: "Noti_Url")
                UserDefaults.standard.set(true, forKey: "isFromPush")
            }
            else{
                UserDefaults.standard.set(nil, forKey: "Noti_Url")
                UserDefaults.standard.set(false, forKey: "isFromPush")
            }
        }
        else if let urlNotification = userInfo["url"] as? String {
            UserDefaults.standard.set(urlNotification, forKey: "Noti_Url")
            UserDefaults.standard.set(true, forKey: "isFromPush")
        }
        
        let state : UIApplication.State = application.applicationState
        switch state
        {
        case .active:
            print("Application is in Active Mode!")
            if userInfo["custom"] is [AnyHashable: Any] {
                if(self.isActive){
                    DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
                        self.isActive = false
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithNotificationURL"), object: nil, userInfo: nil)
                    })
                }
                else{
                    self.isActive = true
                }
            }
            completionHandler(UIBackgroundFetchResult.newData)
        case .inactive:
            if let x = userInfo["custom"] as? [AnyHashable: Any] {
                if let y = x["a"] as? [String:String] {
                    guard y["url"] != nil else {return}
                    let noti_url = y["url"]!
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        UserDefaults.standard.set(noti_url, forKey: "Noti_Url")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithNotificationURL"), object: nil, userInfo: nil)
                    })
                }
                else{
                    UserDefaults.standard.set(nil, forKey: "Noti_Url")
                }
            }
            else if let urlNotification = userInfo["url"] as? String {
                UserDefaults.standard.set(urlNotification, forKey: "Noti_Url")
                UserDefaults.standard.set(true, forKey: "isFromPush")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithNotificationURL"), object: nil, userInfo: nil)
            }
            completionHandler(UIBackgroundFetchResult.newData)
        case .background:
            print("Application is in Backgound mode!")
            completionHandler(UIBackgroundFetchResult.newData)
        @unknown default:
            completionHandler(UIBackgroundFetchResult.newData)
            break
        }
        
        if(kWonderPushEnabled) {
            WonderPush.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        }
    }
    
    //MARK:- Handling local notification when application is in foreground state
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.badge,.sound])
    }
    
    //Method to handle the application tap when it is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if let x = userInfo["custom"] as? [AnyHashable: Any] {
            if let y = x["a"] as? [String:String] {
                guard y["url"] != nil else {return}
                let noti_url = y["url"]!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    UserDefaults.standard.set(noti_url, forKey: "Noti_Url")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithNotificationURL"), object: nil, userInfo: nil)
                })
            }
            else{
                UserDefaults.standard.set(nil, forKey: "Noti_Url")
            }
        }
        else if let urlNotification = userInfo["url"] as? String {
            UserDefaults.standard.set(urlNotification, forKey: "Noti_Url")
            UserDefaults.standard.set(true, forKey: "isFromPush")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenWithNotificationURL"), object: nil, userInfo: nil)
        }
    }
    
}


