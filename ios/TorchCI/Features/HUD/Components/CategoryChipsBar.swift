import SwiftUI

/// Horizontal scrollable row of test category chips for quick filtering.
struct CategoryChipsBar: View {
    @ObservedObject var viewModel: HUDViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TestCategory.allCategories) { category in
                    let jobCount = countJobs(for: category)
                    if jobCount > 0 {
                        categoryChip(category: category, jobCount: jobCount)
                    }
                }
            }
        }
    }

    private func countJobs(for category: TestCategory) -> Int {
        guard let names = viewModel.hudData?.jobNames else { return 0 }
        return names.filter { category.matches($0) }.count
    }

    private func categoryChip(category: TestCategory, jobCount: Int) -> some View {
        let isActive = viewModel.selectedCategory?.id == category.id
        return Button {
            viewModel.selectCategory(category)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 9))
                Text(category.name)
                    .font(.caption2.weight(.medium))
                Text("\(jobCount)")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(isActive ? Color.white.opacity(0.3) : Color(.systemGray4))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundStyle(isActive ? .white : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .accessibilityLabel("\(category.name), \(jobCount) jobs\(isActive ? ", active" : "")")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
