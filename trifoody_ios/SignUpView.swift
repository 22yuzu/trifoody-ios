//
//  SignUpView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var userType: String = "individual"
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSignUpSuccessful: Bool = false

    var body: some View {
       // NavigationView {
            VStack {
                Text("サインアップ")
                    .font(.custom("Hiragino Sans", size: 22))
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                Picker("User Type", selection: $userType) {
                    Text("個人").tag("individual")
                    Text("ビジネス").tag("business")
                    Text("チャリティー").tag("charity")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Group {
                    TextField("ユーザーネーム", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("パスワード確認", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                Button("Sign Up") {
                    signUpUser()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 250, height: 50)
                .background(Color(hex: "E28B7D"))
                .cornerRadius(22)
                .padding(.top, 200)
                .disabled(!isFormValid)

                Spacer()
            }
            .navigationBarHidden(false)

            NavigationLink(destination: destinationView(), isActive: $isSignUpSuccessful) {
                EmptyView()
            }
        }
   // }

    var isFormValid: Bool {
        return !username.isEmpty && !email.isEmpty && password == confirmPassword && password.count >= 6
    }

    func signUpUser() {
        guard password == confirmPassword else {
            self.errorMessage = "パスワードが一致しません"
            self.showError = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }

            if let userId = authResult?.user.uid {
                let db = Firestore.firestore()
                db.collection("users").document(userId).setData([
                    "username": self.username,
                    "userType": self.userType,
                    "email": self.email
                ]) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.isSignUpSuccessful = true
                        }
                    }
                }
            }
        }
    }



    func destinationView() -> some View {
        switch userType {
        case "individual":
            return AnyView(IndividualHomeView())
        case "business":
            return AnyView(BusinessHomeView())
        case "charity":
            return AnyView(CharityHomeView())
        default:
            return AnyView(Text("不明なユーザータイプ"))
        }
    }
}

// HEXカラーコードをColorに変換するための拡張
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}


struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}


