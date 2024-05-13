import SwiftUI
import AppIntents

struct TaskableIntentViewModifier<S: TaskableIntent & AppIntent>: ViewModifier {
    
    @Environment(AppState.self)
    private var app

    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    var intent: S
    
    func body(content: Content) -> some View {
        content.task {
            var intent = intent
            intent.database = database
            intent.service = service
            intent.app = app
            do {
                let _ = try await intent.perform()
            } catch {}
        }
    }
}

struct IdentifiableTaskableIntentViewModifier<ID: Equatable, S: TaskableIntent & AppIntent>: ViewModifier {
    
    @Environment(AppState.self)
    private var app

    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    var id: ID
    var intent: S
    
    func body(content: Content) -> some View {
        content.task(id: id) {
            var intent = intent
            intent.database = database
            intent.service = service
            intent.app = app
            do {
                let _ = try await intent.perform()
            } catch {}
        }
    }
}

struct RefreshableTaskIntentViewModifier<S: TaskableIntent & AppIntent>: ViewModifier {
    
    @Environment(AppState.self)
    private var app

    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    var intent: S
    
    func body(content: Content) -> some View {
        content.refreshable {
            var intent = intent
            intent.database = database
            intent.service = service
            intent.app = app
            do {
                let _ = try await intent.perform()
            } catch {}
        }
    }
}

public extension View {
    func task<Intent: TaskableIntent & AppIntent>(intent: Intent) -> some View {
        self.modifier(TaskableIntentViewModifier(intent: intent))
    }
    
    func task<ID: Equatable, Intent: TaskableIntent & AppIntent>(id: ID, intent: Intent) -> some View {
        self.modifier(IdentifiableTaskableIntentViewModifier(id: id, intent: intent))
    }
}

public extension View {
    func refreshable<Intent: TaskableIntent & AppIntent>(intent: Intent) -> some View {
        self.modifier(RefreshableTaskIntentViewModifier(intent: intent))
    }
}
