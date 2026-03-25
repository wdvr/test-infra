import SwiftUI

/// Shows a compact overview of all test categories' health across recent commits.
/// Each category shows pass rate, trend, and a mini sparkline of per-commit pass rates.
struct CategoryOverviewView: View {
    @ObservedObject var viewModel: HUDViewModel
    @State private var isExpanded = false

    var body: some View {
        let summaries = viewModel.categoryHealthSummaries
        guard !summaries.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: 0) {
                headerButton
                if isExpanded {
                    categoryGrid(summaries: summaries)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isExpanded)
        )
    }

    private var headerButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.3x3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Test Categories")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if !isExpanded {
                    miniHealthPills
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Test Categories, \(isExpanded ? "expanded" : "collapsed")")
    }

    /// Compact pills showing categories when collapsed.
    private var miniHealthPills: some View {
        let summaries = viewModel.categoryHealthSummaries
        return HStack(spacing: 3) {
            ForEach(summaries.prefix(5)) { summary in
                HStack(spacing: 2) {
                    Circle()
                        .fill(colorForPassRate(summary.passRate))
                        .frame(width: 6, height: 6)
                    Text(summary.category.name)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            if summaries.count > 5 {
                Text("+\(summaries.count - 5)")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func categoryGrid(summaries: [CategoryHealthSummary]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(summaries) { summary in
                categoryCard(summary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func categoryCard(_ summary: CategoryHealthSummary) -> some View {
        Button {
            viewModel.selectCategory(summary.category)
        } label: {
            let isActive = viewModel.selectedCategory?.id == summary.category.id
            VStack(alignment: .leading, spacing: 6) {
                // Header: icon + name + trend
                HStack(spacing: 6) {
                    Image(systemName: summary.category.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(isActive ? .white : .secondary)

                    Text(summary.category.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? .white : .primary)

                    Spacer()

                    trendIndicator(summary.trend)
                }

                // Pass rate + job count
                HStack(spacing: 8) {
                    Text(summary.passRateFormatted)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? .white : colorForPassRate(summary.passRate))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(summary.totalJobs) jobs")
                            .font(.system(size: 8))
                            .foregroundStyle(isActive ? Color.white.opacity(0.7) : Color(.tertiaryLabel))
                        if summary.failureCount > 0 {
                            Text("\(summary.failureCount) failed")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(isActive ? Color.white.opacity(0.9) : AppColors.failure)
                        }
                    }
                }

                // Mini sparkline of pass rates per commit
                if summary.commitPassRates.count >= 2 {
                    MiniSparkline(
                        values: summary.commitPassRates,
                        color: isActive ? .white : colorForPassRate(summary.passRate)
                    )
                    .frame(height: 20)
                }

                // Status bar
                statusMiniBar(summary: summary, isActive: isActive)
            }
            .padding(10)
            .background(isActive ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(summary.category.name): \(summary.passRateFormatted) pass rate, \(summary.totalJobs) jobs, \(summary.failureCount) failures")
    }

    private func trendIndicator(_ trend: CategoryHealthSummary.Trend) -> some View {
        Image(systemName: trend.icon)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(trendColor(trend))
    }

    private func trendColor(_ trend: CategoryHealthSummary.Trend) -> Color {
        switch trend {
        case .improving: return AppColors.success
        case .stable: return .secondary
        case .degrading: return AppColors.failure
        }
    }

    private func colorForPassRate(_ rate: Double) -> Color {
        if rate >= 0.95 { return AppColors.success }
        if rate >= 0.80 { return .orange }
        return AppColors.failure
    }

    private func statusMiniBar(summary: CategoryHealthSummary, isActive: Bool) -> some View {
        let segments: [(Color, Int)] = [
            (isActive ? Color.white.opacity(0.8) : AppColors.success, summary.successCount + summary.flakyCount),
            (isActive ? Color.white.opacity(0.4) : AppColors.failure, summary.failureCount),
            (isActive ? Color.white.opacity(0.2) : AppColors.pending, summary.pendingCount),
        ].filter { $0.1 > 0 }
        let total = segments.reduce(0) { $0 + $1.1 }

        return GeometryReader { geometry in
            HStack(spacing: 0.5) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Rectangle()
                        .fill(segment.0)
                        .frame(width: max(1, geometry.size.width * CGFloat(segment.1) / CGFloat(max(1, total))))
                }
            }
        }
        .frame(height: 3)
        .clipShape(RoundedRectangle(cornerRadius: 1.5))
    }
}

/// A tiny sparkline chart for showing pass rate evolution across commits.
struct MiniSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let count = values.count
            guard count >= 2 else { return AnyView(EmptyView()) }

            let minVal = max(0, (values.min() ?? 0) - 0.05)
            let maxVal = min(1, (values.max() ?? 1) + 0.05)
            let range = max(0.01, maxVal - minVal)

            return AnyView(
                Path { path in
                    for (index, value) in values.enumerated() {
                        // values[0] is most recent (left), values[last] is oldest (right)
                        // Draw left-to-right: most recent on the right
                        let x = width * CGFloat(count - 1 - index) / CGFloat(count - 1)
                        let y = height - height * CGFloat((value - minVal) / range)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            )
        }
    }
}
