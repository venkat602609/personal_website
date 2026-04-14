import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MortgageCalculatorView()
                .tabItem {
                    Label("Mortgage", systemImage: "house")
                }

            CompoundInterestView()
                .tabItem {
                    Label("Investing", systemImage: "chart.line.uptrend.xyaxis")
                }

            AboutAppView()
                .tabItem {
                    Label("About", systemImage: "person.crop.circle")
                }
        }
        .tint(Color("AccentColor"))
    }
}

#Preview {
    ContentView()
}
