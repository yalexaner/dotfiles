# Conventional Commit Types

Reference for selecting the appropriate commit type.

## Primary Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature or functionality |
| `fix` | Bug fix or error correction |
| `refactor` | Code restructuring without behavior change |
| `chore` | Maintenance tasks, config changes |
| `docs` | Documentation only changes |
| `test` | Adding or modifying tests |
| `perf` | Performance improvements |

## Secondary Types

| Type | When to Use |
|------|-------------|
| `style` | Code style changes (formatting, whitespace) |
| `ci` | CI/CD configuration changes |
| `build` | Build system or dependency changes |
| `revert` | Reverting previous commits |
| `deps` | Dependency updates (alternative to chore) |
| `ops` | Infrastructure, deployment, operational changes |
| `security` | Security-related fixes or improvements |

## Breaking Changes

For breaking changes, add `BREAKING CHANGE:` footer:

```
feat(api): change authentication flow

- replace session tokens with jwt
- update login endpoint response format

BREAKING CHANGE: login endpoint now returns jwt instead of session cookie
```

## Type Selection Guide

1. **Does it add new functionality?** → `feat`
2. **Does it fix a bug?** → `fix`
3. **Does it change code structure without changing behavior?** → `refactor`
4. **Does it only affect tests?** → `test`
5. **Does it only affect documentation?** → `docs`
6. **Does it improve performance?** → `perf`
7. **Does it update dependencies?** → `deps` or `chore`
8. **Does it change CI/CD?** → `ci`
9. **Does it change build config?** → `build`
10. **Everything else** → `chore`
