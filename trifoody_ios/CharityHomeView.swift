//
//  CharityHomeView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct  CharityHomeView: View {
    var body: some View {
        TabView {
            Charity_HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }

            Charity_SearchView()
                .tabItem {
                    Image(systemName: "plus.app")
                    Text("探す")
                }

            Charity_SettingView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
            
        }
    }
}

struct Charity_HomeView: View {
    @ObservedObject var viewModel = CharityHomeViewModel()

    var body: some View {
        List(viewModel.tradingProducts) { product in
            VStack(alignment: .leading) {
                Text(product.title).font(.headline)
                Text(product.description).font(.subheadline)
                Text("価格: ¥\(product.price, specifier: "%.2f")")
                Text("受け取り場所: \(product.pickupLocation)")
            }
        }
        .onAppear {
            viewModel.fetchTradingProducts()
        }
    }
}


struct Charity_SearchView: View {
    @ObservedObject var viewModel = CharityBrowseViewModel()
    private var db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        List(viewModel.products) { product in
            VStack(alignment: .leading) {
                Text(product.title).font(.headline)
                Text(product.description).font(.subheadline)
                Text("価格: ¥\(product.price, specifier: "%.2f")")
                Text("受け取り場所: \(product.pickupLocation)")
                Button("取引開始") {
                    startTransaction(with: product)
                }
            }
        }
        .onAppear {
            viewModel.fetchAllProducts()
        }
    }

    private func startTransaction(with product: Product) {
        guard let userId = userId, let productId = product.id else { return }

        let newTransaction = Transaction(productID: productId, buyerID: userId, sellerID: product.ownerID, status: "trading")

        do {
            try db.collection("transactions").addDocument(from: newTransaction)
            // 取引開始後に商品の状態を取引中に変更
            updateProductStatus(productId: productId)
        } catch let error {
            print("Error creating transaction: \(error)")
        }
    }

    private func updateProductStatus(productId: String) {
        db.collection("products").document(productId).updateData([
            "isTrading": true
        ]) { error in
            if let error = error {
                print("Error updating product status: \(error)")
            }
        }
    }
}

struct Charity_SettingView: View {
    @State private var username: String = ""
    @State private var address: String = ""
    @State private var introduction: String = ""
    @State private var showingImagePicker: Bool = false
    @State private var inputImage: UIImage?
    @State private var profileImageURL: URL?

    var body: some View {
        VStack {
            // プロフィール画像
            Button(action: {
                self.showingImagePicker = true
            }) {
                VStack {
                    if let profileImageURL = profileImageURL {
                        // URLから画像をダウンロードして表示する
                        FirebaseImageView(imageURL: profileImageURL)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            .sheet(isPresented: $showingImagePicker, onDismiss: uploadProfileImage) {
                ImagePicker(image: self.$inputImage)
            }

            // ユーザーネーム
            TextField("ユーザーネーム", text: $username, onCommit: updateCharityUserData)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("住所")
                .font(.headline)
                .padding(.top)
            TextField("住所", text: $address, onCommit: updateCharityUserData)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()

            Text("紹介文")
                .font(.headline)
                .padding(.top)
            // 一言コメント
            TextField("紹介文", text: $introduction, onCommit: updateCharityUserData)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()

            // ログアウトボタン
            Button("ログアウト", action: logout)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color(hex: "E28B7D"))
                .cornerRadius(10)
                .padding()
                //.padding(.top, 30)

            Spacer()
        }
        .padding()
        .navigationBarTitle("設定", displayMode: .inline)
        .onAppear(perform: loadUserData)
        .navigationBarBackButtonHidden(true)
    }

    func loadUserData() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let docRef = Firestore.firestore().collection("users").document(userId)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    self.username = data?["username"] as? String ?? ""
                    if let urlString = data?["profileImageUrl"] as? String,
                       let url = URL(string: urlString) {
                        self.profileImageURL = url
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }

    func uploadProfileImage() {
            guard let inputImage = inputImage else { return }
            guard let imageData = inputImage.jpegData(compressionQuality: 0.05) else { return }
            guard let userId = Auth.auth().currentUser?.uid else { return }

            let storageRef = Storage.storage().reference().child("profileImages/\(userId).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else { return }
                    self.profileImageURL = downloadURL
                    // ダウンロードURLをFirestoreに保存
                    Firestore.firestore().collection("users").document(userId).updateData([
                        "profileImageUrl": downloadURL.absoluteString
                    ])
                }
            }
        }

    func updateCharityUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(userId)

        docRef.setData([
            "username": self.username, // 既に存在するフィールド
            "address": self.address,   // 新しいフィールド、存在しない場合は追加される
            "introduction": self.introduction // 新しいフィールド、存在しない場合は追加される
        ], merge: true) { error in // 既存のデータを保持しながら更新
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("User data successfully updated")
            }
        }
    }


    func logout() {
            do {
                try Auth.auth().signOut()
                //presentationMode.wrappedValue.dismiss()
            } catch {
                print(error.localizedDescription)
            }
        }
}



struct CharityHomeView_Previews: PreviewProvider {
    static var previews: some View {
        CharityHomeView()
    }
}
