import SwiftUI

@main
struct WrestleTechWatchApp: App {
  @StateObject private var viewModel = WatchHomeViewModel()

  var body: some Scene {
    WindowGroup {
      WatchHomeView()
        .environmentObject(viewModel)
    }
  }
}
