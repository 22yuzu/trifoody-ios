//
//  StartView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI

struct StartView: View {
    // HEXカラーコードをSwiftUIのColorに変換するためのユーティリティ関数
    func hexStringToColor(hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Color(red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                        green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                        blue: Double(rgb & 0x0000FF) / 255.0)

        return red
    }

    var body: some View {
            NavigationView { // ナビゲーションビューを追加
                ZStack {
            
                    VStack {

                        Spacer()

                        VStack(spacing: 20) {
                            Image("trifoody_logo") // ロゴ画像
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .padding(.bottom, 50)
                            
                            NavigationLink(destination: SignUpView()) { // サインアップビューへのリンク
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 250, height: 50)
                                    .background(hexStringToColor(hex: "E28B7D"))
                                    .cornerRadius(22)
                            }
                            
                            NavigationLink(destination: SignInView()) { // サインインビューへのリンク
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 250, height: 50)
                                    .background(hexStringToColor(hex: "E28B7D"))
                                    .cornerRadius(22)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
}


#Preview {
    StartView()
}
