//
//  KeyObservable.swift
//  EnigmaHaven
//
//  Created by Daffa Yagrariksa on 11/09/23.
//

import Foundation
import CryptoKit

class KeyObservable: ObservableObject {
    @Published var key: SymmetricKey? = nil
    @Published var isAuthenticate: Bool = false
    
    func setKey(_ key: SymmetricKey) {
        self.key = key
    }
}
