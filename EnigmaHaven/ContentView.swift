//
//  ContentView.swift
//  EnigmaHaven
//
//  Created by Daffa Yagrariksa on 11/09/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var keyObservable: KeyObservable
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var showSheetAddItem: Bool = false
    @State private var editedItem: Item? = nil
    
    var body: some View {
        if !keyObservable.isAuthenticate {
            AuthView()
        } else {
            List {
                ForEach(items) { item in
                    ItemRow(item: item, onClick: editItem)
                }
                .onDelete(perform: deleteItems)
            }
            .onAppear {
                // check anything!
            }
            .navigationTitle("Secret Data")
            .listStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: toggleSheetAddItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showSheetAddItem) {
                AddItemSheet(dismiss: toggleSheetAddItem, editedItem: $editedItem)
            }
            .onChange(of: editedItem) { _ in
                if editedItem != nil {
                    toggleSheetAddItem()
                }
            }
        }
    }
    
    private func toggleSheetAddItem() {
        showSheetAddItem.toggle()
    }
    
    
    private func editItem(_ item: Item) {
        editedItem = item
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
                print("🟢SUCCESS: delete Item")
            } catch {
                print("🔴ERROR: delete Item: \(String(describing: error))")
            }
        }
    }
}

struct ItemRow: View {
    var item: Item
    var onClick: (_ item: Item) -> Void
    
    var body: some View {
        Section {
            Button {
                onClick(item)
            } label: {
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.title!)
                            .font(.headline)
                        Spacer()
                        Text(item.timestamp!, formatter: itemFormatter)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if item.hide && item.data != "" {
                        HStack(alignment: .bottom) {
                            Text("*******\n*****")
                                .multilineTextAlignment(.leading)
                                .padding(.vertical,1)
                            Spacer()
                            Text("Data hidden\nbecause it's secret")
                                .multilineTextAlignment(.trailing)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else if let data = item.data, data != "" {
                        Text(data)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical,1)
                    }
                }
                .foregroundColor(Color(uiColor: .label))
                .clipShape(Rectangle())
            }
            .buttonStyle(.borderless)
        }
    }
}

struct AddItemSheet: View {
    
    @EnvironmentObject private var keyObservable: KeyObservable
    
    var dismiss: () -> Void
    @Binding var editedItem: Item?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var title: String = ""
    @State private var data: String = ""
    @State private var hide: Bool = false
    
    @State private var cipherText = ""
    @State private var nonce: Data? = nil
    @State private var tag: Data? = nil
    
    private var navTitle: String {
        editedItem == nil ? "Add Item" : "Edit Item"
    }
    
    private var decrypt: String {
        do {
            guard let key = keyObservable.key,
                  let tag = tag
            else { return "noKey" }
            if let nonce = self.nonce {
                
                return try Item.decrypt(ciphertext: cipherText, key: key, nonce: nonce, tag: tag)
            }else {
                return "no Nonce"
            }
        } catch {
            return "error \(String(describing: error))"
        }
    }

    
    var body: some View {
        
        NavigationView {
            VStack {
                List {
                    Section("Title") {
                        TextField("Personal Data", text: $title)
                    }
                    
                    Section("Hide Data") {
                        Toggle(isOn: $hide) {
                            Text("cover data when in list view")
                        }
                    }
                    
                    Section("Data") {
                        TextEditor(text: $data)
                    }
                    
                    Section("ENCRYPT-result") {
                        Text(cipherText)
                    }
                    
                    if nonce != nil && cipherText != "" {
                        Section("DECRYPT-test-result") {
                            Text(decrypt)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .onChange(of: data, perform: { _ in
                guard data != "", let key = keyObservable.key else { return }
                do {
                    let enc = try Item.encrypt(plaintext: data, key: key)
                    self.cipherText =  enc.ciphertext
                    self.nonce = enc.nonce
                    self.tag = enc.tag
                } catch { }
            })
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: onAppear)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveItem) {
                        Text("Save")
                    }
                    .disabled(title == "")
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: _dismiss) {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        
    }
    
    private func clearInput() {
        title = ""
        data = ""
        editedItem = nil
    }
    
    private func _dismiss() {
        clearInput()
        dismiss()
    }
    
    private func onAppear() {
        guard let item = editedItem,
              let title = item.title
        else { return }
        print("🔵item found: \(title)")
        
        self.title = title
        self.data = item.data ?? ""
        self.hide = item.hide
    }
    
    private func saveItem() {
        guard title != "" else { return }
        
        do {
            if editedItem == nil {
                try Item.create(viewContext, title, data, hide)
            } else {
                guard let item = editedItem else { return }
                
                item.title = title
                item.data = data
                item.timestamp = Date()
                item.hide = hide
                
                try viewContext.save()
            }
            clearInput()
            dismiss()
            print("🟢SUCCESS: Save Data")
        } catch {
            print("🔴ERROR: \(String(describing: error))")
        }
        
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
