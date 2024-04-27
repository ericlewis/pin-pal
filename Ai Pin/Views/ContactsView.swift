import SwiftUI

struct ContactsView: View {
    
    struct ViewState {
        var contacts: [Contact] = []
        var isLoading = false
        var firstLoad = true
    }
    
    @State
    private var state = ViewState()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(state.contacts, id: \.id) { contact in
                    Text(contact.id.uuidString)
                }
            }
            .searchable(text: .constant(""))
            .navigationTitle("Contacts")
        }
        .overlay {
            if state.isLoading && state.contacts.isEmpty {
                ProgressView()
            }
            if !state.isLoading && state.contacts.isEmpty && !state.firstLoad {
                ContentUnavailableView("No contacts yet", systemImage: "person.circle")
            }
        }
        .onAppear {
            ContactsAPI.shared.prepare()
        }
        .task(id: ContactsAPI.shared.isReady) {
            if ContactsAPI.shared.isReady {
                state.isLoading = true
                await load()
                state.isLoading = false
                state.firstLoad = false
            }
        }
    }
    
    func load() async {
        do {
            let contacts = try await ContactsAPI.shared.contacts()
            withAnimation {
                self.state.contacts = contacts.sorted { $0.displayName ?? "" > $1.displayName ?? "" }
            }
        } catch {
            print(error)
        }
    }
}

#Preview {
    ContactsView()
}
