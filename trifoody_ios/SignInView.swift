//
//  SignInView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToIndividualHome = false
    @State private var navigateToBusinessHome = false
    @State private var navigateToCharityHome = false

    var body: some View {
        VStack {
            
            Text("サインイン")
                .font(.custom("Hiragino Sans", size: 22))
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 20)

            TextField("メールアドレス", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("パスワード", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Forgot your password?") {
                resetPassword()
            }
            //.padding()

            Button("Sign In") {
                signInUser()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 250, height: 50)
            .background(Color(hex: "E28B7D"))
            .cornerRadius(22)
            .padding(.top, 250)
            .disabled(!isFormValid)

            NavigationLink(destination: IndividualHomeView(), isActive: $navigateToIndividualHome) { EmptyView() }
            NavigationLink(destination: BusinessHomeView(), isActive: $navigateToBusinessHome) { EmptyView() }
            NavigationLink(destination: CharityHomeView(), isActive: $navigateToCharityHome) { EmptyView() }
            
            Spacer()
        }
        .navigationBarHidden(false)
    }

    var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty
    }

    func signInUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }

            guard let userId = authResult?.user.uid else {
                self.errorMessage = "ユーザーが見つかりません"
                self.showError = true
                return
            }

            Firestore.firestore().collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists {
                    let userType = document.get("userType") as? String ?? "individual"
                    switch userType {
                    case "business":
                        self.navigateToBusinessHome = true
                    case "charity":
                        self.navigateToCharityHome = true
                    default:
                        self.navigateToIndividualHome = true
                    }
                } else {
                    self.errorMessage = "ユーザー情報の取得に失敗しました"
                    self.showError = true
                }
            }
        }
    }

    func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
            } else {
                self.errorMessage = "パスワードリセットメールを送信しました"
                self.showError = true
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
