# Branch Naming Conventions

Format: `<type>/<description-in-kebab-case>`

## Type Prefixes

| Prefix | When to Use | Commit Type |
|---|---|---|
| `feat/` | new feature or functionality | `feat` |
| `fix/` | bug fix or error correction | `fix` |
| `refactor/` | code restructuring without behavior change | `refactor` |
| `chore/` | maintenance, config, tooling | `chore` |
| `docs/` | documentation-only changes | `docs` |
| `test/` | test-related changes | `test` |
| `perf/` | performance improvements | `perf` |
| `hotfix/` | critical production fix | `fix` |

## Naming Rules

- lowercase only
- kebab-case (hyphens between words)
- max 50 characters total
- no special characters except hyphens
- use present-tense action words
- include component scope when relevant (e.g., `feat/auth-add-jwt`)

## Examples

- `feat/user-authentication`
- `fix/login-validation-error`
- `chore/update-dependencies`
- `refactor/api-client-structure`
- `docs/installation-guide`
- `feat/add-dark-mode`
- `fix/resolve-memory-leak`
- `hotfix/critical-db-connection`

## Deriving Type from Changes

1. adds new functionality? → `feat/`
2. fixes a bug? → `fix/`
3. restructures without behavior change? → `refactor/`
4. only affects tests? → `test/`
5. only affects documentation? → `docs/`
6. improves performance? → `perf/`
7. maintenance, deps, config? → `chore/`
8. critical production issue? → `hotfix/`
