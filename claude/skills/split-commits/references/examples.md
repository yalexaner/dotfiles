# Commit Splitting Examples

## Good Examples

### Example 1: Feature with Multiple Components

**Changes:** New user authentication with API, ViewModel, and UI changes

**Good split:**
```
Commit 1: feat(api): add authentication endpoint
  - AuthApi.kt
  - AuthResponse.kt
  Reason: API layer foundation

Commit 2: feat(auth): add authentication repository
  - AuthRepository.kt
  - AuthRepositoryImpl.kt
  Reason: Domain layer using new API

Commit 3: feat(auth): add login viewmodel
  - LoginViewModel.kt
  Reason: Presentation layer using repository

Commit 4: feat(auth): add login screen ui
  - LoginScreen.kt
  - LoginComponents.kt
  Reason: UI layer using ViewModel
```

**Why good:** Each commit compiles, follows dependency order, can be bisected.

---

### Example 2: Mixed Changes in Same Area

**Changes:** OfflineScreen gets renamed variables + new feature

**Good split:**
```
Commit 1: refactor(offline): rename isConnecting to isLoading
  - OfflineViewModel.kt
  - OfflineScreen.kt
  Reason: Naming improvement (independent)

Commit 2: feat(offline): add retry countdown timer
  - OfflineViewModel.kt
  - OfflineScreen.kt
  Reason: New feature (independent)
```

**Why good:** Each could be cherry-picked or reverted independently.

---

### Example 3: Tightly Coupled Changes

**Changes:** New data class + single place that uses it

**Good approach - ONE commit:**
```
Commit 1: feat(user): add user preferences model and screen
  - UserPreferences.kt (new model)
  - PreferencesScreen.kt (uses model)
  Reason: Tightly coupled, splitting breaks compilation
```

**Why good:** Can't have consumer without model, no benefit to splitting.

---

## Bad Examples

### Example 1: Split Too Granularly

**Bad:**
```
Commit 1: rename variable foo to bar
Commit 2: rename variable baz to qux
Commit 3: rename function doThing to performAction
Commit 4: add return type annotation
```

**Problem:** These are all part of one refactoring effort. Should be one commit.

---

### Example 2: Wrong Dependency Order

**Bad:**
```
Commit 1: feat(ui): update screen to use new event type
Commit 2: feat(model): add new event type
```

**Problem:** Commit 1 won't compile because the event type doesn't exist yet.

---

### Example 3: Mixing Unrelated Changes

**Bad:**
```
Commit 1: feat(auth): add login + fix typo in README + update CI config
```

**Problem:** Three unrelated things. Should be three commits.

---

## Decision Flowchart

```
For each change, ask:

1. Does this change compile alone?
   NO  → Must be grouped with dependencies
   YES → Continue

2. Could this be cherry-picked independently?
   YES → Consider splitting
   NO  → Keep with related changes

3. Does this serve the same logical purpose?
   YES → Keep together
   NO  → Split

4. Would splitting break the "story" of the commit?
   YES → Keep together
   NO  → Split is fine
```

## Size Guidelines

Research suggests optimal commit sizes for review:

| Lines Changed | Review Quality |
|---------------|----------------|
| < 50 | Easy to review |
| 50-200 | Good for review |
| 200-400 | Acceptable |
| 400-800 | Review quality drops |
| > 800 | Significantly harder to review |

**However:** Logic trumps size. A 500-line commit for one cohesive feature is better than 5 arbitrary 100-line commits.

## Sources

- [Atomic Commits - LeanIX Engineering](https://engineering.leanix.net/blog/atomic-commit/)
- [How Atomic Commits Increased Productivity - DEV Community](https://dev.to/samuelfaure/how-atomic-git-commits-dramatically-increased-my-productivity-and-will-increase-yours-too-4a84)
- [Git Best Practices - freeCodeCamp](https://www.freecodecamp.org/news/git-best-practices-commits-and-code-reviews/)
- [Commit Best Practices - AlgoMaster](https://algomaster.io/learn/git/commit-best-practices)
