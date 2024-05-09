import SwiftData

public typealias CurrentScheme = SchemaV1

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }
    
    public static var models: [any PersistentModel.Type] {
        [Note.self, Device.self]
    }
}
