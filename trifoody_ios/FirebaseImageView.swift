//
//  FirebaseImageView.swift
//  trifoody_ios
//
//  Created by 冨岡哲平 on 2023/11/26.
//

import SwiftUI
import FirebaseStorage

struct FirebaseImageView: View {
    @State private var imageData: Data?
    
    let imageURL: URL
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Image(systemName: "photo")
                    .resizable()
            }
        }
        .onAppear(perform: loadImage)
    }
    
    func loadImage() {
        // imageDataをダウンロードして更新する処理をここに書きます
        let storageRef = Storage.storage().reference(forURL: imageURL.absoluteString)
        storageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
            } else {
                imageData = data
            }
        }
    }
}

