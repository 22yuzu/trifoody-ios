//
//  trifoody_iosApp.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

@main
struct trifoody_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            if isFirstLaunch() {
                StartView()
            } else {
                HomeViewBasedOnUserType()
            }
        }
    }

    func isFirstLaunch() -> Bool {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            return true
        }
        return false
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

struct HomeViewBasedOnUserType: View {
    @State private var userType: String? = nil

    var body: some View {
        Group {
            if let userType = userType {
                switch userType {
                case "individual":
                    IndividualHomeView()
                case "business":
                    BusinessHomeView()
                case "charity":
                    CharityHomeView()
                default:
                    StartView()
                }
            } else {
                ProgressView().onAppear(perform: checkUserType)
            }
        }
    }

    private func checkUserType() {
        guard let userId = Auth.auth().currentUser?.uid else {
            userType = "none" // サインインしていない場合
            return
        }

        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let userType = document.get("userType") as? String ?? "individual"
                self.userType = userType
            } else {
                userType = "none"
            }
        }
    }
}

