# TorchCI iOS App - Development Notes

## Test Category Filtering Feature (2026-03-25)

### What was added

A new test category filtering and health overview system for the HUD page that lets users quickly filter and visualize CI job health by platform/type categories (Mac, Linux, Windows, Inductor, CUDA, ROCm, Trunk, Pull, Periodic, Lint).

### Files added

- `TorchCI/Models/TestCategory.swift` - `TestCategory` model with predefined categories and pattern matching, plus `CategoryHealthSummary` for per-category health stats with trend detection
- `TorchCI/Features/HUD/Components/CategoryChipsBar.swift` - Horizontal scrollable row of category filter chips with job counts
- `TorchCI/Features/HUD/Components/CategoryOverviewView.swift` - Collapsible overview showing per-category pass rates, trends, sparklines, and status bars
- `TorchCITests/Models/TestCategoryTests.swift` - 17 unit tests for category matching, pass rate computation, and trend detection

### Files modified

- `TorchCI/Features/HUD/HUDViewModel.swift`:
  - Added `selectedCategory` published property
  - Added category filtering to `filteredJobIndices` computed property
  - Added `selectCategory()` and updated `clearFilter()` to include category
  - Added `categoryHealthSummaries` computed property
- `TorchCI/Features/HUD/Components/FilterBar.swift`:
  - Added `CategoryChipsBar` below the quick filter toggles
  - Updated `hasActiveFilters` to include category selection
- `TorchCI/Features/HUD/HUDView.swift`:
  - Added `CategoryOverviewView` between quick stats and main content
- `TorchCITests/ViewModels/HUDViewModelTests.swift`:
  - Added 4 tests for category filtering, clearing, health summaries, and search combination

### How it works

1. **Category chips** appear in the FilterBar when HUD data is loaded. Each chip shows the category name and number of matching jobs. Tapping a chip filters the grid to only show jobs matching that category's patterns.

2. **Category overview** is a collapsible panel below the quick stats bar. When expanded, it shows a 2-column grid of cards, each displaying:
   - Category name and icon
   - Pass rate (color-coded: green >= 95%, orange >= 80%, red < 80%)
   - Trend arrow (improving/stable/degrading based on recent vs older commit pass rates)
   - Mini sparkline of per-commit pass rates
   - Status bar (success/failure/pending ratio)
   - Tapping a card activates that category filter

3. **Category filter** integrates with all existing filters (search, failures only, hide unstable, etc.) using AND logic. The category check is the first filter applied in `filteredJobIndices`.

### Category definitions

| Category | Patterns | Icon |
|----------|----------|------|
| Mac | macos, mac- | desktopcomputer |
| Linux | linux | server.rack |
| Windows | windows, win- | pc |
| Inductor | inductor | bolt.fill |
| CUDA | cuda | cpu |
| ROCm | rocm | cpu.fill |
| Trunk | trunk | arrow.triangle.branch |
| Pull | pull | arrow.triangle.pull |
| Periodic | periodic | clock.arrow.circlepath |
| Lint | lint | checkmark.seal |

### Testing

21 new tests added:
- 17 in `TestCategoryTests` (pattern matching, uniqueness, pass rate, trends)
- 4 in `HUDViewModelTests` (filtering, clearing, health summaries, search combination)

Run with:
```bash
xcodegen generate
xcodebuild test -scheme TorchCI -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

### Architecture decisions

- Categories are static (not fetched from API) to avoid latency. They can be extended by adding to `TestCategory.allCategories`.
- Pattern matching is case-insensitive substring matching (not regex) for performance.
- `categoryHealthSummaries` is computed fresh each time (not cached) since it depends on `hudData` which changes on pagination/refresh.
- The overview panel is collapsed by default to avoid overwhelming the UI.
- Sparkline shows oldest commits on left, newest on right.

## Sensitive Data

The `.gitignore` covers:
- `Secrets.plist` (bot token)
- Code signing certs (*.p12, *.p8, *.cer, *.mobileprovision)
- Environment files (.env*)
- Terraform state (*.tfstate, .terraform/)
- Fastlane bundle

The Team ID `N324UX8D9M` is in project.yml/Fastfile which is normal for code signing configuration.

## Build

```bash
cd ios
xcodegen generate      # Regenerate project after adding/removing files
xcodebuild build -scheme TorchCI -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```
