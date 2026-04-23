import SwiftUI

@main
struct PolishPad2App: App {
    @State private var model = PolishWorkflowModel()

    var body: some Scene {
        WindowGroup {
            MainView(model: model)
        }
    }
}
