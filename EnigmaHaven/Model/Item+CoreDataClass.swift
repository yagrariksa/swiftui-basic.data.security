//
//  Item+CoreDataClass.swift
//  EnigmaHaven
//
//  Created by Daffa Yagrariksa on 11/09/23.
//
//

import Foundation
import CoreData
import CryptoKit

@objc(Item)
public class Item: NSManagedObject {
    static func create(
        _ viewContext: NSManagedObjectContext,
        _ key: SymmetricKey,
        _ title: String,
        _ data: String?,
        _ hide: Bool = false
    ) throws {
        let newItem = Item(context: viewContext)
        
        newItem.title = title
        newItem.data = data
        newItem.timestamp = Date()
        newItem.hide = hide
        
        newItem.encrypt(key)
        
        
        
        do {
            try viewContext.save()
            print("🟢SUCCESS: create Item")
        } catch {
            print("🔴ERROR: create Item: \(String(describing: error))")
            throw ItemError.FailCreateItem
        }
    }
    
    func dataRead(_ key: SymmetricKey) -> String {
        guard let data = self.data,
              data != "",
              let nonce = self.nonce,
              let tag = self.nonce
        else {
            print("🔴Error Guard Data")
            return ""
        }
        
        do {
            print("🔵Decrypting... \(String(describing: self))")
            let result = try self.decrypt(ciphertext: data, key: key, nonce: nonce, tag: tag)
            print("🟢Success Read Data")
            return result
        } catch {
            print("🔴Error decrypt data: \(String(describing: error))")
            return ""
        }
    }
    
    func encrypt(_ key: SymmetricKey) {
        guard let data = self.data, data != "" else { return }
        do {
            let enc = try self.encrypt(plaintext: data, key: key)
            self.data = enc.ciphertext
            self.nonce = enc.nonce
            self.tag = enc.tag
            print("🟢success to ENCRYPT data: \(String(describing: self))")
        } catch {
            print("🔴fail to ENCRYPT data")
        }
        
    }
    
    private func encrypt(plaintext: String, key: SymmetricKey) throws -> (ciphertext: String, nonce: Data, tag: Data) {
        let plaintextData = Data(plaintext.utf8)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: nonce)
        let tag = sealedBox.tag
        return (ciphertext: Data(sealedBox.ciphertext).base64EncodedString(), nonce: Data(nonce), tag: tag)
    }

    private func decrypt(ciphertext: String, key: SymmetricKey, nonce: Data, tag: Data) throws -> String {
        guard let ciphertextData = Data(base64Encoded: ciphertext) else {
            throw ItemError.invalidInputData
        }
        
        let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: ciphertextData, tag: tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw ItemError.decryptionFailed
        }
        
        return decryptedString
    }
}

enum ItemError: Error {
    case FailCreateItem
    case decryptionFailed
    case invalidInputData
}

