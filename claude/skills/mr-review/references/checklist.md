# Detailed Review Checklists

Extended checklists for comprehensive code review. Load this file when deeper analysis is needed.

---

## Security Checklist (OWASP-Aligned)

### Injection Prevention
- [ ] SQL queries use parameterized statements or ORM properly
- [ ] No string concatenation for queries
- [ ] Command injection: user input not passed to shell commands
- [ ] LDAP injection: proper escaping for directory queries
- [ ] XML/XPath injection: proper parsing configuration

### Authentication & Session
- [ ] Passwords hashed with strong algorithm (bcrypt, argon2)
- [ ] Session tokens generated securely (crypto-random)
- [ ] Session timeout implemented
- [ ] Logout properly invalidates session
- [ ] Multi-factor authentication where required
- [ ] Account lockout after failed attempts

### Authorization
- [ ] Access control checks on every protected resource
- [ ] No direct object references without authorization
- [ ] Principle of least privilege followed
- [ ] Role-based access properly implemented
- [ ] Horizontal privilege escalation prevented

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] TLS for data in transit
- [ ] No sensitive data in logs
- [ ] No secrets in code (API keys, passwords)
- [ ] PII handling compliant with regulations
- [ ] Proper data masking in non-production

### Input Validation
- [ ] All inputs validated (type, length, format, range)
- [ ] Whitelist validation preferred over blacklist
- [ ] File uploads validated (type, size, content)
- [ ] URL redirects validated against whitelist
- [ ] JSON/XML parsing configured securely

### Output Encoding
- [ ] HTML output encoded to prevent XSS
- [ ] JavaScript contexts properly escaped
- [ ] URL parameters encoded
- [ ] CSS contexts handled safely
- [ ] Content-Type headers set correctly

### Error Handling & Logging
- [ ] No sensitive data in error messages
- [ ] Stack traces not exposed to users
- [ ] Security events logged (login, access denied, etc.)
- [ ] Log injection prevented
- [ ] Audit trail for sensitive operations

---

## Performance Checklist

### Algorithm Efficiency
- [ ] Appropriate data structures used
- [ ] No O(n^2) when O(n) or O(n log n) possible
- [ ] Early exits and short-circuits used
- [ ] Lazy evaluation where beneficial
- [ ] Memoization for expensive repeated computations

### Database Performance
- [ ] Indexes used for filtered/sorted columns
- [ ] N+1 queries eliminated (use eager loading)
- [ ] Batch operations instead of loops
- [ ] Pagination for large result sets
- [ ] Connection pooling configured
- [ ] Query execution plans reviewed for complex queries

### Memory Management
- [ ] No memory leaks (unclosed resources)
- [ ] Large collections processed in chunks/streams
- [ ] Object pooling for frequently created objects
- [ ] Weak references where appropriate
- [ ] No unnecessary object creation in loops

### Caching
- [ ] Appropriate cache invalidation strategy
- [ ] Cache keys designed to avoid collisions
- [ ] TTL set appropriately
- [ ] Cache stampede prevention
- [ ] Cold cache handling

### Concurrency
- [ ] Thread-safe data structures where needed
- [ ] No race conditions
- [ ] Deadlock-free locking order
- [ ] Appropriate lock granularity
- [ ] Async operations where beneficial

### Network & I/O
- [ ] Connection timeouts configured
- [ ] Retry logic with exponential backoff
- [ ] Circuit breaker pattern for external services
- [ ] Response compression enabled
- [ ] Appropriate batch sizes for bulk operations

---

## Clean Architecture Checklist

### Dependency Rule
- [ ] Inner layers have no knowledge of outer layers
- [ ] Domain entities have no framework dependencies
- [ ] Use cases depend only on domain and interfaces
- [ ] Dependency injection used for outer layer implementations

### Layer Responsibilities
- [ ] **Entities**: Business rules, no I/O
- [ ] **Use Cases**: Application-specific business rules
- [ ] **Interface Adapters**: Format conversion, controllers, presenters
- [ ] **Frameworks**: Database, web framework, external services

### Interface Segregation
- [ ] Interfaces are small and focused
- [ ] Clients don't depend on methods they don't use
- [ ] Repository interfaces in domain, implementations in infrastructure

### Testability
- [ ] Business logic testable without frameworks
- [ ] External dependencies mockable via interfaces
- [ ] No hidden dependencies (service locator anti-pattern)

---

## SOLID Principles Checklist

### Single Responsibility
- [ ] Each class has one reason to change
- [ ] Methods do one thing
- [ ] Cohesive modules

### Open/Closed
- [ ] Classes open for extension, closed for modification
- [ ] New behavior via new classes, not changing existing
- [ ] Strategy pattern for varying algorithms

### Liskov Substitution
- [ ] Subtypes substitutable for base types
- [ ] No strengthened preconditions in subtypes
- [ ] No weakened postconditions in subtypes

### Interface Segregation
- [ ] No fat interfaces
- [ ] Clients depend only on what they use
- [ ] Role interfaces over header interfaces

### Dependency Inversion
- [ ] High-level modules don't depend on low-level modules
- [ ] Both depend on abstractions
- [ ] Abstractions don't depend on details

---

## Code Smell Checklist

### Bloaters
- [ ] No long methods (>20 lines consider splitting)
- [ ] No large classes (>300 lines consider splitting)
- [ ] No primitive obsession (use value objects)
- [ ] No long parameter lists (>3-4 parameters)

### Object-Orientation Abusers
- [ ] No switch statements on type (use polymorphism)
- [ ] No parallel inheritance hierarchies
- [ ] No refused bequest (subclass not using parent)

### Change Preventers
- [ ] No divergent change (one class changed for different reasons)
- [ ] No shotgun surgery (one change requires many class changes)

### Dispensables
- [ ] No dead code
- [ ] No speculative generality
- [ ] No duplicate code
- [ ] No lazy classes (classes that don't do enough)

### Couplers
- [ ] No feature envy (method uses other class's data excessively)
- [ ] No inappropriate intimacy (classes too coupled)
- [ ] No message chains (a.getB().getC().getD())
- [ ] No middle man (class only delegates)

---

## Testing Checklist

### Unit Tests
- [ ] Happy path tested
- [ ] Edge cases tested (null, empty, boundary values)
- [ ] Error conditions tested
- [ ] Tests are independent and isolated
- [ ] Tests are deterministic (no flaky tests)

### Integration Tests
- [ ] Component interactions tested
- [ ] Database operations tested
- [ ] External service integration tested (or mocked appropriately)

### Test Quality
- [ ] Tests document expected behavior
- [ ] One assertion concept per test
- [ ] Arrange-Act-Assert pattern followed
- [ ] No logic in tests
- [ ] Tests run fast

### Coverage
- [ ] New code has tests
- [ ] Critical paths have high coverage
- [ ] Coverage not gamed (meaningful tests, not just coverage)

---

## Documentation Checklist

### Code Documentation
- [ ] Public APIs documented
- [ ] Complex algorithms explained
- [ ] Non-obvious decisions commented with "why"
- [ ] TODO/FIXME items tracked properly

### Change Documentation
- [ ] MR description explains what and why
- [ ] Breaking changes clearly documented
- [ ] Migration steps provided if needed
- [ ] API changes reflected in API docs
