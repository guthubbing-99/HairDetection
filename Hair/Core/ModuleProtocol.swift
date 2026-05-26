import SwiftUI

enum ModuleCardSize {
    case large
    case small
}

protocol HairModule: Identifiable {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }
    var tintColor: Color { get }
    var cardSize: ModuleCardSize { get }
    func makeHomeCard() -> AnyView
    func makeDetailView() -> AnyView
}
