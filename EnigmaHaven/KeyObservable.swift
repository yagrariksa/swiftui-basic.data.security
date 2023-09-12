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
    
    @Published var nonce: Data? = nil
    @Published var tag: Data? = nil
    
    func setKey(_ key: SymmetricKey) {
        self.key = key
    }
    
    func verify(nonce: Data, tag: Data) {
        
        if self.tag != tag {
            print("🔴tag is not same")
        }
        
        if self.nonce != nonce {
            print("🔴nonce is not same")
        }
    }
}
