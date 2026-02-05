# Manual Reconstruction Examples

## Example 1: API Field Rename Across Multiple Layers

### The Messy Commit

You have one commit that:
- Renames `ip` to `url` in a data class
- Updates 3 ViewModels to use the new field name
- Adds a loading indicator to the UI

### Reconstruction Plan

```
Reference commit: abc123

Commit 1 (Layer 1): refactor(model): rename ip to url in ValidationEvent
  - ValidationEvent.kt: change field name

Commit 2 (Layer 3): refactor(viewmodel): update event field references
  - SavedViewModel.kt: event.ip → event.url
  - ManualViewModel.kt: event.ip → event.url
  - MdnsViewModel.kt: event.ip → event.url

Commit 3 (Layer 4): feat(ui): add loading indicator
  - ConnectionScreen.kt: add CircularProgressIndicator
```

### Why This Order?

- Commit 1 must come first - ViewModels can't reference `event.url` until it exists
- Commit 2 uses the new field - depends on Commit 1
- Commit 3 is independent UI work - could be separate PR entirely

### Execution

```bash
# Setup
jj bookmark create messy-reference -r @
jj new @-

# Commit 1: Rename field
jj new -m "WIP: rename ip to url"
# Edit ValidationEvent.kt - change the field name
# Verify: build passes
jj desc -m "refactor(model): rename ip to url in ValidationEvent"

# Commit 2: Update consumers
jj new -m "WIP: update viewmodels"
# Edit each ViewModel - update field references
# Verify: build passes
jj desc -m "refactor(viewmodel): update event field references"

# Commit 3: Add UI feature
jj new -m "WIP: loading indicator"
# Edit ConnectionScreen.kt - add the indicator
# Verify: build passes
jj desc -m "feat(ui): add loading indicator to connection screen"

# Cleanup
jj abandon messy-reference
jj bookmark delete messy-reference
```

---

## Example 2: Same File, Different Logical Changes

### The Messy Commit

`UserViewModel.kt` has mixed changes:
- Lines 20-35: Renamed `isConnecting` to `isLoading` (refactoring)
- Lines 50-80: Added new `retryWithBackoff()` function (feature)
- Lines 90-100: Fixed null check bug (bugfix)

### Reconstruction Plan

```
Reference commit: xyz789

Commit 1: fix(user): add null check before network call
  - UserViewModel.kt lines 90-100: add safe call operator

Commit 2: refactor(user): rename isConnecting to isLoading
  - UserViewModel.kt lines 20-35: rename variable and usages

Commit 3: feat(user): add retry with exponential backoff
  - UserViewModel.kt lines 50-80: new function
```

### Why This Order?

- Bugfix first - most likely to be cherry-picked or reverted independently
- Refactoring second - pure rename, no behavior change
- Feature last - new functionality built on clean foundation

### Key Insight

With tool-based splitting, you'd need TUI interaction to select specific lines from the same file. With manual reconstruction, you just implement each change separately - no tools needed.

---

## Example 3: Feature with Tests

### The Messy Commit

New authentication feature with:
- `AuthRepository.kt` - new repository
- `AuthViewModel.kt` - uses repository
- `LoginScreen.kt` - UI
- `AuthRepositoryTest.kt` - tests for repository
- `AuthViewModelTest.kt` - tests for viewmodel

### Reconstruction Plan

```
Commit 1: feat(auth): add authentication repository
  - AuthRepository.kt (interface)
  - AuthRepositoryImpl.kt (implementation)
  - AuthRepositoryTest.kt (tests)

Commit 2: feat(auth): add authentication viewmodel
  - AuthViewModel.kt
  - AuthViewModelTest.kt

Commit 3: feat(auth): add login screen
  - LoginScreen.kt
```

### Key Insight

Tests go with the code they test - not in a separate "add tests" commit. Each commit is independently testable and verifiable.

---

## When NOT to Split

### Example: Tightly Coupled Changes

```kotlin
// New data class
data class UserPrefs(val theme: Theme, val language: String)

// Single place that uses it
class SettingsScreen {
    fun display(prefs: UserPrefs) { ... }
}
```

**Don't split this.** The data class has no meaning without its consumer. One commit is correct:

```
feat(settings): add user preferences model and screen
```

---

## Decision Guide

Ask these questions:

1. **Can each commit compile?**
   - NO → Must be same commit or reorder
   - YES → Continue

2. **Could this be cherry-picked independently?**
   - YES → Consider splitting
   - NO → Keep together

3. **Would a reviewer understand this commit alone?**
   - YES → Good split
   - NO → Maybe combine with related changes

4. **Does the commit message need "and"?**
   - YES → Probably should split
   - NO → Probably fine

---

## Sources

- [Stacked Diffs - Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/stacked-diffs)
- [Benefits of Stacked Diffs - Graphite](https://www.graphite.com/guides/benefits-of-stacked-diffs-in-code-review)
- [Atomic Commits - LeanIX Engineering](https://engineering.leanix.net/blog/atomic-commit/)
- [Deliberate Practice for Programmers](https://www.freecodecamp.org/news/how-to-use-deliberate-practice-to-learn-programming-fast/)
