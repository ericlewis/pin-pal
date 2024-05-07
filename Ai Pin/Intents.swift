import AppIntents
import Foundation
import PinKit
import SwiftUI

public struct NoteEntity: Identifiable {
    public let id: UUID
    
    @Property(title: "Name")
    public var title: String
    
    @Property(title: "Body")
    public var text: String
    
    @Property(title: "Creation Date")
    public var createdAt: Date
    
    @Property(title: "Last Modified Date")
    public var modifiedAt: Date
    
    public init(id: UUID, title: String, text: String, createdAt: Date, modifiedAt: Date) {
        self.id = id
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.title = title
        self.text = text
    }
    
    public init(from note: Note) {
        self.id = note.memoryId ?? note.uuid ?? .init()
        self.createdAt = note.createdAt ?? .now
        self.modifiedAt = note.createdAt ?? .now
        self.title = note.title
        self.text = note.text
    }
}

extension NoteEntity: AppEntity {
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(text)")
    }
    
    public static var defaultQuery: NoteEntityQuery = NoteEntityQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Note", numericFormat: "Notes")
}

public struct NoteEntityQuery: EntityQuery, EntityStringQuery, EntityPropertyQuery {
    
    public static var properties = EntityQueryProperties<NoteEntity, NSPredicate> {
        Property(\.$title) {
            ContainsComparator { NSPredicate(format: "title CONTAINS[cd] %@", $0) }
        }
        Property(\.$text) {
            ContainsComparator { NSPredicate(format: "text CONTAINS[cd] %@", $0) }
        }
        Property(\.$createdAt) {
            // TODO: valid the logic in all these since they're basically placeholders
            IsBetweenComparator { NSPredicate(format: "createdAt < %@ AND createdAt > %@", $0 as NSDate, $1 as NSDate) }
            LessThanComparator { NSPredicate(format: "createdAt < %@", $0 as NSDate) }
            EqualToComparator { NSPredicate(format: "createdAt = %@", $0 as NSDate) }
            GreaterThanComparator { NSPredicate(format: "createdAt > %@", $0 as NSDate) }
        }
        Property(\.$modifiedAt) {
            // TODO: valid the logic in all these since they're basically placeholders
            IsBetweenComparator { NSPredicate(format: "createdAt < %@ AND createdAt > %@", $0 as NSDate, $1 as NSDate) }
            LessThanComparator { NSPredicate(format: "createdAt < %@", $0 as NSDate) }
            EqualToComparator { NSPredicate(format: "createdAt = %@", $0 as NSDate) }
            GreaterThanComparator { NSPredicate(format: "createdAt > %@", $0 as NSDate) }
        }
    }
    
    public static var sortingOptions = SortingOptions {
        SortableBy(\.$title)
        SortableBy(\.$text)
        SortableBy(\.$createdAt)
        SortableBy(\.$modifiedAt)
    }
    
    public static var findIntentDescription: IntentDescription? {
        .init("", categoryName: "Notes")
    }
    
    private var service: HumaneCenterService = .live()
    
    public init() {}
    
    public func entities(for ids: [Self.Entity.ID]) async throws -> Self.Result {
        await ids.asyncCompactMap { id in
            guard let note: Note = try? await service.memory(id).get() else {
                return nil
            }
            return NoteEntity(from: note)
        }
    }
    
    public func entities(matching string: String) async throws -> Self.Result {
        try await entities(for: service.search(string, .notes).memories?.map(\.uuid) ?? [])
    }
    
    public func entities(
        matching comparators: [NSPredicate],
        mode: ComparatorMode,
        sortedBy: [EntityQuerySort<NoteEntity>],
        limit: Int?
    ) async throws -> Self.Result {
        let notes: [Note] = try await service.notes(0, limit ?? 1000).content.compactMap({ $0.get() })
        let predicate = NSCompoundPredicate(type: mode == .and ? .and : .or, subpredicates: comparators)
        guard let filteredNotes = Array(((notes as NSArray).filtered(using: predicate) as NSArray).sortedArray(using: sortedBy.map({
            switch $0.by {
            case \.$title:
                NSSortDescriptor(key: "title", ascending: $0.order == .ascending)
            case \.$text:
                NSSortDescriptor(key: "text", ascending: $0.order == .ascending)
            case \.$createdAt:
                NSSortDescriptor(key: "createdAt", ascending: $0.order == .ascending)
            case \.$modifiedAt:
                NSSortDescriptor(key: "modifiedAt", ascending: $0.order == .ascending)
            default:
                NSSortDescriptor(key: "createdAt", ascending: $0.order == .ascending)
            }
        }))) as? [Note] else {
            return []
        }
        return filteredNotes.map(NoteEntity.init(from:))
    }
    
    public func suggestedEntities() async throws -> [NoteEntity] {
        try await service.notes(0, 10).content
            .compactMap({ $0.get() })
            .map(NoteEntity.init(from:))
    }
}

public struct CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    public static var description: IntentDescription? = .init("Creates a note using the content passed as input.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Create note with \(\.$text) named \(\.$title)")
    }
    
    @Parameter(title: "Name")
    public var title: String
    
    @Parameter(title: "Body")
    public var text: String
    
    public init(title: String, text: String) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var notesRepository: NotesRepository
    
    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> {
        guard !title.isEmpty else {
            throw $title.needsValueError("What is the name of the note you would like to add?")
        }
        guard !text.isEmpty else {
            throw $text.needsValueError("What is the content of the note you would like to add?")
        }
        
        await notesRepository.create(note: .init(text: text, title: title))
        navigationStore.activeNote = nil
        
        guard let note: Note = notesRepository.content.first?.get() else {
            fatalError()
        }
        
        return .result(value: .init(from: note))
    }
}

public struct AppendToNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Append to Note"
    public static var description: IntentDescription? = .init("Appends the text passed as input to the specified note.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Append \(\.$text) to \(\.$note)")
    }
    
    @Parameter(title: "Note")
    public var note: NoteEntity
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(note: NoteEntity, text: String) {
        self.note = note
        self.text = text
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> {
        let newBody = """
    \(note.text)
    \(text)
    """
        guard let note: Note = try await service.update(note.id.uuidString, .init(text: newBody, title: note.title)).get() else {
            fatalError()
        }
        
        return .result(value: .init(from: note))
    }
}

public struct DeleteNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Delete Notes"
    public static var description: IntentDescription? = .init("Deletes the specified notes.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        When(\.$confirmBeforeDeleting, .equalTo, true, {
            Summary("Delete \(\.$notes)") {
                \.$confirmBeforeDeleting
            }
        }, otherwise: {
            Summary("Immediately delete \(\.$notes)") {
                \.$confirmBeforeDeleting
            }
        })
    }
    
    @Parameter(title: "Notes")
    public var notes: [NoteEntity]
    
    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the notes will be deleted", default: true)
    var confirmBeforeDeleting: Bool
    
    public init(notes: [NoteEntity]) {
        self.notes = notes
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        let ids = notes.map(\.id)
        if confirmBeforeDeleting {
            let notesList = notes.map { $0.title }
            let formattedList = notesList.formatted(.list(type: .and, width: .short))
            try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete \(formattedList)?"))
            let _ = try await service.bulkRemove(ids)
        } else {
            let _ = try await service.bulkRemove(ids)
        }
        return .result()
    }
}

public enum FavoriteAction: String, AppEnum {
    case add
    case remove
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Favorite Action")
    public static var caseDisplayRepresentations: [FavoriteAction: DisplayRepresentation] = [
        .add: "Add",
        .remove: "Remove"
    ]
}

public struct FavoriteNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Favorite Notes"
    public static var description: IntentDescription? = .init("Adds or removes notes from the set of favorited notes.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$action) \(\.$notes) to favorites")
    }

    @Parameter(title: "Favorite Action", default: FavoriteAction.add)
    public var action: FavoriteAction
    
    @Parameter(title: "Notes")
    public var notes: [NoteEntity]
    
    public init(notes: [NoteEntity]) {
        self.notes = notes
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        let ids = notes.map(\.id)
        if action == .add {
            let _ = try await service.bulkFavorite(ids)
        } else {
            let _ = try await service.bulkUnfavorite(ids)
        }
        return .result()
    }
}

public struct ReplaceNoteBodyIntent: AppIntent {
    public static var title: LocalizedStringResource = "Update Note"
    public static var description: IntentDescription? = .init("Replace the body or title of the specified note.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Update \(\.$body) on \(\.$note)")
    }

    @Parameter(title: "Body")
    public var body: String
    
    @Parameter(title: "Note")
    public var note: NoteEntity
    
    public init(note: NoteEntity) {
        self.note = note
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> {
        guard let note: Note = try await service.update(note.id.uuidString, .init(text: body, title: note.title)).get() else {
            fatalError()
        }
        return .result(value: .init(from: note))
    }
}

public struct OpenNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Note"
    public static var description: IntentDescription? = .init("Opens a specific note in Pin Pal", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$note)")
    }

    @Parameter(title: "Note")
    public var note: NoteEntity
    
    public init(note: NoteEntity) {
        self.note = note
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore

    public func perform() async throws -> some IntentResult {
        navigationStore.activeNote = .init(
            uuid: note.id,
            memoryId: note.id,
            text: note.text,
            title: note.title,
            createdAt: note.createdAt,
            modifedAt: note.modifiedAt
        )
        return .result()
    }
}

public struct ShowNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Show Notes"
    public static var description: IntentDescription? = .init("Get quick access to notes in Pin Pal", categoryName: "Notes")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigationStore: NavigationStore
    
    public func perform() async throws -> some IntentResult {
        navigationStore.selectedTab = .notes
        return .result()
    }
}

public struct ToggleVisionAccessIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Vision Beta"
    public static var description: IntentDescription? = .init("Turns on or off the Vision Beta access on your Ai Pin.", categoryName: "Device")
    public static var parameterSummary: some ParameterSummary {
        Summary("Vision beta is \(\.$enabled)")
    }
    
    @Parameter(title: "Enabled")
    public var enabled: Bool
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true

    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let result = try await service.toggleFeatureFlag(.visionAccess, enabled)
        return .result(value: result.isEnabled)
    }
}

public struct ToggleDeviceBlockIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Blocked"
    public static var description: IntentDescription? = .init("Turns on or off the device block feature.", categoryName: "Device")
    public static var parameterSummary: some ParameterSummary {
        Summary("Device block is \(\.$enabled)")
    }
    
    @Parameter(title: "Enabled")
    public var enabled: Bool
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let deviceId = try await service.deviceIdentifiers().first else {
            fatalError()
        }
        let result = try await service.toggleLostDeviceStatus(deviceId, enabled)
        return .result(value: result.isLost)
    }
}

public struct GetPinPhoneNumberBlockIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Phone Number"
    public static var description: IntentDescription? = .init("Retrieve the phone number associated with your Ai Pin", categoryName: "Device")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = try await service.subscription()
        return .result(value: info.phoneNumber)
    }
}

public enum WifiSecurityType: String, AppEnum {
    case wpa = "WPA"
    case wep = "WEP"
    case none = "nopass"
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "WiFi Security Type")
    public static var caseDisplayRepresentations: [WifiSecurityType: DisplayRepresentation] = [
        .wpa: "WPA",
        .wep: "WEP",
        .none: "None"
    ]
}

public struct AddWifiNetworkIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create WiFi Quick Setup Code"
    public static var description: IntentDescription? = .init("""
Create a QR code for use with quick setup on Ai Pin.

How to Scan:
1. Tap and hold the touchpad on your Ai Pin and say “turn on WiFi”
2. Raise your palm to activate the Laser Ink display and select “quick setup” and then “scan code”
3. Position the QR code in front of your Ai Pin to begin scanning. If successful, you should hear a chime."
""", categoryName: "Device")
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$type, .equalTo, WifiSecurityType.none) {
            Summary("Create WiFi QR Code") {
                \.$name
                \.$type
                \.$hidden
            }
        } otherwise: {
            Summary("Create WiFi QR Code") {
                \.$name
                \.$type
                \.$password
                \.$hidden
            }
        }
    }
    
    @Parameter(title: "Name (SSID)")
    public var name: String
    
    @Parameter(title: "Security Type", default: WifiSecurityType.wpa)
    public var type: WifiSecurityType
    
    @Parameter(title: "Password")
    public var password: String
    
    @Parameter(title: "Is Hidden")
    public var hidden: Bool
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let image = generateQRCode(from: "WIFI:S:\(name);T:\(type.rawValue);P:\(password);H:\(hidden ? "true" : "false");;")
        guard let data = image.pngData() else {
            fatalError()
        }
        let file = IntentFile(data: data, filename: "qrCode.png")
        return .result(value: file)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 12, y: 12)
            let scaledImage2 = outputImage.transformed(by: transform, highQualityDownsample: true)
            if let cgImage = context.createCGImage(scaledImage2, from: scaledImage2.extent) {
                let res = UIImage(cgImage: cgImage)
                return res
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

