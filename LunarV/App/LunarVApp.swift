import SwiftUI

@main
struct LunarVApp: App {
    @StateObject private var viewModel = LunarMenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            LunarMenuBarView(viewModel: viewModel)
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
