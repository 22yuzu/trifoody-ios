//
//  BusinessHomeView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct BusinessHomeView: View {
    var body: some View {
        TabView {
            Business_HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }

            Business_ListingView()
                .tabItem {
                    Image(systemName: "plus.app")
                    Text("出品")
                }

            Business_SettingView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
            
        }
    }
}

struct Business_HomeView: View {
    @ObservedObject var viewModel = BusinessHomeViewModel()

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



struct Business_ListingView: View {
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var price: String = ""
    @State private var pickupLocation: String = ""
    @State private var pickupTime = Date()
    private var db = Firestore.firestore()

    var body: some View {
        Form {
            Section(header: Text("商品情報")) {
                TextField("タイトル", text: $title)
                TextField("説明", text: $description)
                TextField("価格", text: $price)
                    .keyboardType(.decimalPad)
                TextField("受け取り場所", text: $pickupLocation)
                DatePicker("受け取り時間", selection: $pickupTime, displayedComponents: .date)
            }
            Button("出品") {
                uploadProduct()
            }
        }
    }

    private func uploadProduct() {
        let newProduct = Product(title: title,
                                 description: description,
                                 price: Double(price) ?? 0.0,
                                 pickupLocation: pickupLocation,
                                 pickupTime: pickupTime,
                                 ownerID: Auth.auth().currentUser?.uid ?? "",
                                 isTrading: false,
                                 ownerType: "business")

        do {
            try db.collection("products").addDocument(from: newProduct)
            clearFields()
        } catch let error {
            print("Error writing product to Firestore: \(error)")
        }
    }

    private func clearFields() {
        title = ""
        description = ""
        price = ""
        pickupLocation = ""
        pickupTime = Date()
    }
}


struct Business_SettingView: View {
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
            TextField("ユーザーネーム", text: $username, onCommit: updateBusinessUserData)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("住所")
                .font(.headline)
                .padding(.top)
            TextField("住所", text: $address, onCommit: updateBusinessUserData)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()

            Text("紹介文")
                .font(.headline)
                .padding(.top)
            TextField("紹介文", text: $introduction, onCommit: updateBusinessUserData)
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

    func updateBusinessUserData() {
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



struct BusinessHomeView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessHomeView()
    }
}
