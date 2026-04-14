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
        }
        .tint(Color("AccentColor"))
    }
}

#Preview {
    ContentView()
}
