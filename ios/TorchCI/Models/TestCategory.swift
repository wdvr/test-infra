import Foundation

/// Predefined test categories for filtering HUD jobs by platform/type.
/// Each category defines a pattern that matches against job names.
struct TestCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    /// Case-insensitive patterns to match in job names (OR logic).
    let patterns: [String]

    func matches(_ jobName: String) -> Bool {
        let lowered = jobName.lowercased()
        return patterns.contains { lowered.contains($0) }
    }

    /// All predefined categories.
    static let allCategories: [TestCategory] = [
        TestCategory(id: "mac", name: "Mac", icon: "desktopcomputer", patterns: ["macos", "mac-"]),
        TestCategory(id: "linux", name: "Linux", icon: "server.rack", patterns: ["linux"]),
        TestCategory(id: "windows", name: "Windows", icon: "pc", patterns: ["windows", "win-"]),
        TestCategory(id: "inductor", name: "Inductor", icon: "bolt.fill", patterns: ["inductor"]),
        TestCategory(id: "cuda", name: "CUDA", icon: "cpu", patterns: ["cuda"]),
        TestCategory(id: "rocm", name: "ROCm", icon: "cpu.fill", patterns: ["rocm"]),
        TestCategory(id: "trunk", name: "Trunk", icon: "arrow.triangle.branch", patterns: ["trunk"]),
        TestCategory(id: "pull", name: "Pull", icon: "arrow.triangle.pull", patterns: ["pull"]),
        TestCategory(id: "periodic", name: "Periodic", icon: "clock.arrow.circlepath", patterns: ["periodic"]),
        TestCategory(id: "lint", name: "Lint", icon: "checkmark.seal", patterns: ["lint"]),
    ]
}

/// Health summary for a single test category across all visible commits.
struct CategoryHealthSummary: Identifiable {
    let category: TestCategory
    let totalJobs: Int
    let successCount: Int
    let failureCount: Int
    let newFailureCount: Int
    let flakyCount: Int
    let pendingCount: Int
    /// Per-commit pass rates (most recent first) for trend visualization.
    let commitPassRates: [Double]

    var id: String { category.id }

    var passRate: Double {
        let passing = successCount + flakyCount
        let total = passing + failureCount + pendingCount
        return total > 0 ? Double(passing) / Double(total) : 0
    }

    var passRateFormatted: String {
        String(format: "%.0f%%", passRate * 100)
    }

    var trend: Trend {
        guard commitPassRates.count >= 2 else { return .stable }
        let recent = commitPassRates.prefix(3).reduce(0, +) / max(1, Double(min(3, commitPassRates.count)))
        let older = commitPassRates.suffix(from: min(3, commitPassRates.count)).reduce(0, +) / max(1, Double(commitPassRates.count - min(3, commitPassRates.count)))
        let delta = recent - older
        if delta > 0.05 { return .improving }
        if delta < -0.05 { return .degrading }
        return .stable
    }

    enum Trend {
        case improving, stable, degrading

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .degrading: return "arrow.down.right"
            }
        }

        var color: String {
            switch self {
            case .improving: return "green"
            case .stable: return "secondary"
            case .degrading: return "red"
            }
        }
    }
}
