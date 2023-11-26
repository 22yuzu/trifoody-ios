//
//  Models.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/26.
//

import FirebaseFirestoreSwift
import Firebase
import FirebaseFirestore

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var price: Double
    var pickupLocation: String
    var pickupTime: Date
    var ownerID: String
    var isTrading: Bool // 取引中かどうか
    var ownerType: String // 出品者タイプ
}


struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var productID: String
    var buyerID: String
    var sellerID: String
    var status: String // 取引のステータス
}

class IndividualViewModel: ObservableObject {
    @Published var tradingProducts = [Product]()
    private var db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        fetchTradingProducts()
    }

    func fetchTradingProducts() {
        guard let userId = userId else { return }

        db.collection("transactions")
            .whereField("buyerID", isEqualTo: userId)
            .whereField("status", isEqualTo: "trading") // 取引中のものだけをフィルタリング
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in 'transactions'")
                    return
                }

                // ここで取得した取引から関連する商品を取得
                for document in documents {
                    let transaction = try? document.data(as: Transaction.self)
                    if let productId = transaction?.productID {
                        self?.fetchProduct(productId: productId)
                    }
                }
            }
    }

    private func fetchProduct(productId: String) {
        db.collection("products").document(productId).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let product = try? document.data(as: Product.self)
                if let product = product {
                    DispatchQueue.main.async {
                        self?.tradingProducts.append(product)
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

class BusinessHomeViewModel: ObservableObject {
    @Published var tradingProducts = [Product]()
    private var db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        fetchTradingProducts()
    }

    func fetchTradingProducts() {
        guard let userId = userId else { return }

        db.collection("products")
            .whereField("ownerID", isEqualTo: userId)
            .whereField("isTrading", isEqualTo: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in 'products'")
                    return
                }

                self?.tradingProducts = documents.compactMap { document -> Product? in
                    try? document.data(as: Product.self)
                }
            }
    }
}

class CharityHomeViewModel: ObservableObject {
    @Published var tradingProducts = [Product]()
    private var db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        fetchTradingProducts()
    }

    func fetchTradingProducts() {
        guard let userId = userId else { return }

        db.collection("transactions")
            .whereField("buyerID", isEqualTo: userId)
            .whereField("status", isEqualTo: "trading") // 取引中のものだけをフィルタリング
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in 'transactions'")
                    return
                }

                for document in documents {
                    let transaction = try? document.data(as: Transaction.self)
                    if let productId = transaction?.productID {
                        self?.fetchProduct(productId: productId)
                    }
                }
            }
    }

    private func fetchProduct(productId: String) {
        db.collection("products").document(productId).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let product = try? document.data(as: Product.self)
                if let product = product {
                    DispatchQueue.main.async {
                        self?.tradingProducts.append(product)
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}


class BusinessProductsViewModel: ObservableObject {
    @Published var products = [Product]()
    private var db = Firestore.firestore()

    func fetchBusinessProducts() {
        db.collection("products")
            .whereField("ownerType", isEqualTo: "business") // ownerTypeをビジネスとする
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in 'products'")
                    return
                }

                self.products = documents.compactMap { document -> Product? in
                    try? document.data(as: Product.self)
                }
            }
    }
}

class CharityBrowseViewModel: ObservableObject {
    @Published var products = [Product]()
    private var db = Firestore.firestore()

    init() {
        fetchAllProducts()
    }

    func fetchAllProducts() {
        db.collection("products")
            .whereField("isTrading", isEqualTo: false) // まだ取引されていない商品
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in 'products'")
                    return
                }

                self.products = documents.compactMap { document -> Product? in
                    try? document.data(as: Product.self)
                }
            }
    }
}


