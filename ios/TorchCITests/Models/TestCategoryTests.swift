import XCTest
@testable import TorchCI

final class TestCategoryTests: XCTestCase {

    // MARK: - Pattern Matching

    func testMacCategoryMatchesMacOSJobs() {
        let mac = TestCategory.allCategories.first { $0.id == "mac" }!
        XCTAssertTrue(mac.matches("macos-14-py3-arm64 / test (default)"))
        XCTAssertTrue(mac.matches("trunk / macos-13-py3-x86 / build"))
        XCTAssertTrue(mac.matches("mac-build / test"))
        XCTAssertFalse(mac.matches("linux-jammy-py3.8-gcc11 / test"))
        XCTAssertFalse(mac.matches("windows-py3 / build"))
    }

    func testLinuxCategoryMatchesLinuxJobs() {
        let linux = TestCategory.allCategories.first { $0.id == "linux" }!
        XCTAssertTrue(linux.matches("linux-jammy-py3.8-gcc11 / test (default, 1, 5)"))
        XCTAssertTrue(linux.matches("trunk / linux-focal / build"))
        XCTAssertFalse(linux.matches("macos-14 / test"))
        XCTAssertFalse(linux.matches("windows-py3 / build"))
    }

    func testWindowsCategoryMatchesWindowsJobs() {
        let windows = TestCategory.allCategories.first { $0.id == "windows" }!
        XCTAssertTrue(windows.matches("windows-py3 / build"))
        XCTAssertTrue(windows.matches("win-vs2019 / test"))
        XCTAssertFalse(windows.matches("linux-jammy / test"))
    }

    func testInductorCategoryMatchesInductorJobs() {
        let inductor = TestCategory.allCategories.first { $0.id == "inductor" }!
        XCTAssertTrue(inductor.matches("inductor / cuda12.4-py3.12-gcc9-sm86 / test"))
        XCTAssertTrue(inductor.matches("trunk / inductor-test / build"))
        XCTAssertFalse(inductor.matches("trunk / linux-build / test"))
    }

    func testCUDACategoryMatchesCUDAJobs() {
        let cuda = TestCategory.allCategories.first { $0.id == "cuda" }!
        XCTAssertTrue(cuda.matches("inductor / cuda12.4-py3.12 / test"))
        XCTAssertTrue(cuda.matches("trunk / linux-cuda11 / build"))
        XCTAssertFalse(cuda.matches("trunk / linux-cpu / test"))
    }

    func testROCmCategoryMatchesROCmJobs() {
        let rocm = TestCategory.allCategories.first { $0.id == "rocm" }!
        XCTAssertTrue(rocm.matches("trunk / linux-rocm / build"))
        XCTAssertFalse(rocm.matches("trunk / linux-cuda / build"))
    }

    func testTrunkCategoryMatchesTrunkJobs() {
        let trunk = TestCategory.allCategories.first { $0.id == "trunk" }!
        XCTAssertTrue(trunk.matches("trunk / linux-build / test"))
        XCTAssertFalse(trunk.matches("pull / linux-build / test"))
    }

    func testPullCategoryMatchesPullJobs() {
        let pull = TestCategory.allCategories.first { $0.id == "pull" }!
        XCTAssertTrue(pull.matches("pull / linux-build / test"))
        XCTAssertFalse(pull.matches("trunk / linux-build / test"))
    }

    func testPeriodicCategoryMatchesPeriodicJobs() {
        let periodic = TestCategory.allCategories.first { $0.id == "periodic" }!
        XCTAssertTrue(periodic.matches("periodic / linux-nightly / build"))
        XCTAssertFalse(periodic.matches("trunk / linux / test"))
    }

    func testLintCategoryMatchesLintJobs() {
        let lint = TestCategory.allCategories.first { $0.id == "lint" }!
        XCTAssertTrue(lint.matches("lint / flake8-py3"))
        XCTAssertTrue(lint.matches("lintrunner / check"))
        XCTAssertFalse(lint.matches("trunk / linux / test"))
    }

    func testMatchIsCaseInsensitive() {
        let mac = TestCategory.allCategories.first { $0.id == "mac" }!
        XCTAssertTrue(mac.matches("MacOS-14 / Test"))
        XCTAssertTrue(mac.matches("MACOS / BUILD"))
    }

    func testNoMatchReturnsEmpty() {
        let cuda = TestCategory.allCategories.first { $0.id == "cuda" }!
        XCTAssertFalse(cuda.matches("completely-unrelated / job"))
    }

    // MARK: - All Categories Exist

    func testAllCategoriesHaveUniqueIds() {
        let ids = TestCategory.allCategories.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Category IDs should be unique")
    }

    func testAllCategoriesHaveNonEmptyPatterns() {
        for category in TestCategory.allCategories {
            XCTAssertFalse(category.patterns.isEmpty, "\(category.name) should have patterns")
        }
    }

    // MARK: - CategoryHealthSummary

    func testPassRateComputation() {
        let summary = CategoryHealthSummary(
            category: TestCategory.allCategories[0],
            totalJobs: 100,
            successCount: 80,
            failureCount: 10,
            newFailureCount: 5,
            flakyCount: 5,
            pendingCount: 5,
            commitPassRates: []
        )
        // (80 + 5) / (80 + 5 + 10 + 5) = 85/100 = 0.85
        XCTAssertEqual(summary.passRate, 0.85, accuracy: 0.001)
        XCTAssertEqual(summary.passRateFormatted, "85%")
    }

    func testPassRateWithZeroJobs() {
        let summary = CategoryHealthSummary(
            category: TestCategory.allCategories[0],
            totalJobs: 0,
            successCount: 0,
            failureCount: 0,
            newFailureCount: 0,
            flakyCount: 0,
            pendingCount: 0,
            commitPassRates: []
        )
        XCTAssertEqual(summary.passRate, 0)
    }

    func testTrendDetection() {
        // Improving: recent commits have higher pass rates
        let improving = CategoryHealthSummary(
            category: TestCategory.allCategories[0],
            totalJobs: 100,
            successCount: 90, failureCount: 10, newFailureCount: 5,
            flakyCount: 0, pendingCount: 0,
            commitPassRates: [0.95, 0.93, 0.90, 0.80, 0.75, 0.70]
        )
        XCTAssertEqual(improving.trend, .improving)

        // Degrading: recent commits have lower pass rates
        let degrading = CategoryHealthSummary(
            category: TestCategory.allCategories[0],
            totalJobs: 100,
            successCount: 70, failureCount: 30, newFailureCount: 15,
            flakyCount: 0, pendingCount: 0,
            commitPassRates: [0.70, 0.72, 0.75, 0.90, 0.92, 0.95]
        )
        XCTAssertEqual(degrading.trend, .degrading)

        // Stable: similar pass rates
        let stable = CategoryHealthSummary(
            category: TestCategory.allCategories[0],
            totalJobs: 100,
            successCount: 90, failureCount: 10, newFailureCount: 5,
            flakyCount: 0, pendingCount: 0,
            commitPassRates: [0.90, 0.91, 0.89, 0.90, 0.91, 0.90]
        )
        XCTAssertEqual(stable.trend, .stable)
    }
}
