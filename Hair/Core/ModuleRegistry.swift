import SwiftUI

class ModuleRegistry: ObservableObject {
    @Published var modules: [any HairModule] = []

    init() {
        registerDefaultModules()
    }

    private func registerDefaultModules() {
        modules = [
            MedicationModule(),
            CombModule(),
            SleepModule(),
        ]
    }

    var largeModules: [any HairModule] {
        modules.filter { $0.cardSize == .large }
    }

    var smallModules: [any HairModule] {
        modules.filter { $0.cardSize == .small }
    }
}
