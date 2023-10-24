//
//  AppDelegate.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 04/05/2023.
//

import Firebase
import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start()
        return true
    }
}
