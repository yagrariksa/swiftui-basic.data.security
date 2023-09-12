//
//  AuthView.swift
//  EnigmaHaven
//
//  Created by Daffa Yagrariksa on 11/09/23.
//

import SwiftUI
import LocalAuthentication
import SwiftKeychainWrapper
import CryptoKit

struct AuthView: View {
    @EnvironmentObject private var keyObservable: KeyObservable
    
    @State private var passcode: String = ""
    // @State private var isAuthenticationSuccessful: Bool = false
    @State private var tryFaceID: Int = 3
    
    @State private var showAlertSetPasscode = false
    @State private var newPasscode = ""
    @State private var newPasscodeConfirm = ""
    
    var body: some View {
        
        VStack {
            Text("Enter Passcode or Use Biometric")
            
            // Passcode Entry
            SecureField("Passcode", text: $passcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Biometric Authentication
            Button("Use Biometric") {
                authenticateWithBiometric()
            }
            .buttonStyle(.borderedProminent)
            .disabled(tryFaceID <= 0)
            .padding()
            
            // Authenticate Button
            Button("Authenticate") {
                authenticateWithPasscode()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
        }
        .alert("Create Passcode",isPresented: $showAlertSetPasscode, actions:  {
            SecureField("Passcode (6 digit)", text: $newPasscode)
            SecureField("Passcode Confirmation", text: $newPasscodeConfirm)
            
            Button("Confirm") {
                guard newPasscode == newPasscodeConfirm && newPasscode.count == 6 else { return }
                KeychainWrapper.standard.set(newPasscode, forKey: "enigma_passcode")
                print("🟢SUCCESS CREATE PASSCODE")
                showAlertSetPasscode.toggle()
            }
        })
        .alert(isPresented: $keyObservable.isAuthenticate) {
            Alert(title: Text("Authentication Successful"))
        }
        .onAppear(perform: isFirstLaunch)
        
    }
    
    private func authenticateWithBiometric() {
        guard tryFaceID > 0 else { return }
        tryFaceID -= 1
        let context = LAContext()
        
        // Check if biometric authentication is available and can be used
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate using biometrics") { success, error in
                if success {
                    DispatchQueue.main.async {
                        // Retrieve keys securely after successful authentication
                        retrieveKeysFromKeychain()
                    }
                }
            }
        }
    }
    
    private func isFirstLaunch() {
        if KeychainWrapper.standard.bool(forKey: "firstLaunch") == nil ||
            KeychainWrapper.standard.string(forKey: "enigma_passcode") == nil {
            KeychainWrapper.standard.set(true, forKey: "firstLaunch")
            showAlertSetPasscode.toggle()
        }else {
            authenticateWithBiometric()
        }
    }
    
    private func authenticateWithPasscode() {
        // Implement passcode authentication logic here
        // Compare the entered passcode with a stored passcode
        // If the passcode is correct, set isAuthenticationSuccessful to true
        // Then, retrieve keys securely after successful authentication
        
        if let storedPasscode = KeychainWrapper.standard.string(forKey: "enigma_passcode") {
            // Compare the entered passcode with the stored passcode
            if passcode == storedPasscode {
                retrieveKeysFromKeychain()
            }else {
                print("🔴PASSCODE not sync")
            }
        }else {
            print("🔴THERE IS NO PASSCODE")
        }
    }
    
    private func retrieveKeysFromKeychain() {
        
        if let key = KeychainWrapper.standard.data(forKey: "enigma_key") {
            
            let symKey = SymmetricKey(data: key)
            keyObservable.setKey(symKey)
            print("GET FROM KeychainWrapper")
            
        }else {
            
            let key = SymmetricKey(size: .bits256)
            keyObservable.setKey(key)
            
            let keyData =  key.withUnsafeBytes { Data($0) }
            KeychainWrapper.standard.set(keyData, forKey: "enigma_key")
            
            print("CREATE NEW Sym and SAVE TO KeychainWrapper")
        }
        
//        print("🟢Key: \(String(describing: keyObservable.key))")
        keyObservable.isAuthenticate = true
        
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
