//
//  IndividualHomeView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct IndividualHomeView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
            
            SupportView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("サポート")
                }

            ListingView()
                .tabItem {
                    Image(systemName: "plus.app")
                    Text("出品")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
            
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel = IndividualViewModel()

    var body: some View {
        List(viewModel.tradingProducts) { product in
            VStack(alignment: .leading) {
                Text(product.title).font(.headline)
                Text(product.description).font(.subheadline)
                Text("受け取り場所: \(product.pickupLocation)")
                Text("受け取り時間: \(product.pickupTime, formatter: itemFormatter)")
            }
        }
        .onAppear {
            viewModel.fetchTradingProducts()
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()


struct SupportView: View {
    @ObservedObject var viewModel = BusinessProductsViewModel()
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
            viewModel.fetchBusinessProducts()
        }
    }

    private func startTransaction(with product: Product) {
        guard let userId = userId, let productId = product.id else { return }

        let newTransaction = Transaction(productID: productId, buyerID: userId, sellerID: product.ownerID, status: "trading")

        do {
            try db.collection("transactions").addDocument(from: newTransaction)
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



struct ListingView: View {
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
                // 出品処理
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
                                 isTrading: false, ownerType: "individual")
        
        do {
            try db.collection("products").addDocument(from: newProduct)
            // 処理成功後にフィールドをクリアする
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



struct SettingsView: View {
    @State private var username: String = ""
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
            TextField("ユーザーネーム", text: $username, onCommit: updateUsername)
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

    func updateUsername() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let docRef = Firestore.firestore().collection("users").document(userId)
            docRef.updateData([
                "username": self.username
            ]) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Username successfully updated")
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



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        IndividualHomeView()
    }
}

