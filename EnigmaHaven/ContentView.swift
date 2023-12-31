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
            NavigationView {
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
                HStack {
                    Text(item.title!)
                        .font(.headline)
                    Spacer()
                    Text(item.timestamp!, formatter: itemFormatter)
                        .font(.caption)
                        .foregroundColor(.gray)
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
    
    private var navTitle: String {
        editedItem == nil ? "Add Item" : "Edit Item"
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
                }
                .listStyle(.insetGrouped)
            }
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
              let title = item.title,
              let key = keyObservable.key
        else { return }
        print("🔵item found: \(title)")
        
        guard let nonce = item.nonce, let tag = item.tag else { return }
        keyObservable.verify(nonce: nonce, tag: tag)
        
        self.title = title
        self.data = item.dataRead(key)
        self.hide = item.hide
    }
    
    private func saveItem() {
        guard title != "", let key = keyObservable.key else { return }
        
        do {
            if editedItem == nil {
                try Item.create(viewContext, key, title, data, hide)
            } else {
                guard let item = editedItem else { return }
                
                item.title = title
                item.data = data
                item.timestamp = Date()
                item.hide = hide
                
                item.encrypt(key)
                
                keyObservable.nonce = item.nonce
                keyObservable.tag = item.tag
                
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
