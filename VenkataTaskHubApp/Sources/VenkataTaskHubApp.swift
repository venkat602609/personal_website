import SwiftUI

@main
struct VenkataTaskHubApp: App {
    @StateObject private var scenarioStore = ScenarioStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scenarioStore)
        }
    }
}
