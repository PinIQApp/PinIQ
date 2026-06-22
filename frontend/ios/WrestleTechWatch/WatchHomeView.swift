import SwiftUI

struct WatchHomeView: View {
  @EnvironmentObject private var viewModel: WatchHomeViewModel

  var body: some View {
    TabView {
      VStack(alignment: .leading, spacing: 10) {
        Text("Pin IQ")
          .font(.headline)
        MetricRow(title: "Unread", value: "\(viewModel.unreadMessages)")
        MetricRow(title: "Alerts", value: "\(viewModel.alerts)")
        MetricRow(title: "Event", value: viewModel.nextEvent)
        MetricRow(title: "Weigh-in", value: viewModel.nextWeighIn)
      }
      .padding()
      .tabItem {
        Label("Queue", systemImage: "message")
      }

      VStack(alignment: .leading, spacing: 10) {
        Text("Health")
          .font(.headline)
        MetricRow(title: "Heart rate", value: viewModel.heartRate)
        MetricRow(title: "Steps", value: viewModel.steps)
      }
      .padding()
      .tabItem {
        Label("Health", systemImage: "heart")
      }
    }
  }
}

private struct MetricRow: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.body.weight(.semibold))
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(8)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}
