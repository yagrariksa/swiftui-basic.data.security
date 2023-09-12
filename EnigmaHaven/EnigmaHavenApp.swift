//
//  EnigmaHavenApp.swift
//  EnigmaHaven
//
//  Created by Daffa Yagrariksa on 11/09/23.
//

import SwiftUI

@main
struct EnigmaHavenApp: App {
    let persistenceController = PersistenceController.shared
    @ObservedObject var keyObservable = KeyObservable()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(keyObservable)
        }
    }
}
