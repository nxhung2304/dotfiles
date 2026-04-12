# AI Coding Rules

Guidelines for AI systems generating code.
These rules ensure that generated code is **predictable, maintainable, and consistent**.

These rules should always be applied together with `clean-code.md`.

---

# Core Principles

When generating code, always prioritize:

```
clarity > cleverness
simplicity > complexity
readability > brevity
maintainability > shortcuts
```

The generated code should be **easy for humans to read and modify**.

---

# Follow Existing Codebase

Always respect the current project structure.

Rules:

* Follow the same folder structure
* Follow the same naming conventions
* Follow the same coding style
* Reuse existing utilities if possible

Never introduce a completely different coding style.

---

# Prefer Predictable Patterns

Avoid creative or unusual implementations.

Prefer **well-known patterns** that most developers recognize.

Example:

Prefer:

```
Repository pattern
Service layer
Dependency injection
```

Avoid:

```
unusual abstractions
experimental patterns
over-engineered solutions
```

Predictable code is easier to maintain.

---

# Generate Small Functions

Functions should be small and focused.

Guidelines:

```
max 20–30 lines per function
one clear responsibility
```

Bad example:

```
processOrder()
  validateInput
  calculatePrice
  sendPayment
  updateInventory
  notifyUser
  logTransaction
```

Better:

```
processOrder()
  validateOrder()
  processPayment()
  finalizeOrder()
```

---

# Avoid Deep Nesting

Use **guard clauses** instead of nested conditions.

Bad:

```
if user
  if user.active
    if user.hasPermission
      process()
```

Better:

```
if user == null return
if not user.active return
if not user.hasPermission return

process()
```

Maximum recommended nesting depth:

```
3 levels
```

---

# Reuse Existing Code

Before generating new code:

1. Search for existing functions
2. Search for shared utilities
3. Search for similar modules

If similar logic exists, reuse it instead of duplicating.

---

# Avoid Code Duplication

Never generate duplicated logic.

If similar code appears twice:

```
extract a helper function
```

If similar logic appears across modules:

```
create shared utilities
```

---

# Use Descriptive Naming

Names should clearly describe purpose.

Good examples:

```
calculateTotalPrice
validateUserInput
fetchUserProfile
isUserAuthenticated
```

Avoid:

```
tmp
data
obj
x
value
```

Names should communicate **intent**.

---

# Limit Parameters

Prefer functions with few parameters.

Recommended limit:

```
3–4 parameters
```

If more parameters are needed:

```
create a request object
```

Example:

Bad:

```
createUser(name, age, email, phone, address)
```

Better:

```
createUser(userRequest)
```

---

# Handle Errors Explicitly

Never ignore errors.

Bad:

```
try
  riskyOperation()
catch
  doNothing()
```

Better:

```
try
  riskyOperation()
catch error
  logError(error)
  return failure
```

Errors should always be:

* logged
* propagated
* handled clearly

---

# Avoid Over-Engineering

Do not add unnecessary layers.

Avoid:

```
excessive abstractions
unnecessary design patterns
deep inheritance trees
```

Use the **simplest solution that works**.

---

# Prefer Composition Over Inheritance

Avoid deep inheritance chains.

Bad:

```
User
PremiumUser
PremiumUserWithDiscount
PremiumUserWithSpecialDiscount
```

Better:

```
User
  discountPolicy
  permissionPolicy
```

Composition creates more flexible designs.

---

# Respect Module Boundaries

Do not mix responsibilities across modules.

Example:

Bad:

```
UserController
  calls database directly
  performs business logic
  renders UI
```

Better:

```
Controller -> Service -> Repository
```

Each layer has a clear responsibility.

---

# Write Self-Documenting Code

Prefer code that explains itself.

Avoid unnecessary comments explaining obvious logic.

Bad:

```
# increment i by 1
i = i + 1
```

Good code should be understandable without comments.

Comments should explain:

* why something exists
* complex business logic

---

# Avoid Large Files

Recommended limits:

```
300–400 lines per file
```

If a file grows too large:

* split modules
* extract helpers
* separate responsibilities

---

# Add Defensive Checks

AI-generated code should validate inputs.

Example:

```
if input == null
  return error
```

Never assume inputs are always valid.

---

# Prefer Deterministic Behavior

Avoid hidden side effects.

Functions should:

```
receive input
return output
```

Avoid:

```
modifying global state
hidden dependencies
unexpected mutations
```

---

# Code Should Be Easy to Modify

Generated code should allow future developers to:

* extend functionality
* replace components
* modify behavior safely

Avoid rigid designs that are difficult to change.

---

# Before Finishing Code Generation

Verify the following checklist:

```
no magic numbers
no duplicated logic
functions are small
nesting <= 3 levels
names are descriptive
errors are handled
existing utilities reused
no unnecessary abstractions
```

If any rule is violated:

```
refactor before finalizing code
```

---

# Final Rule

Generated code should feel like it was written by:

```
a careful senior engineer
```

The goal is not just working code, but **clean and maintainable code**.

---
