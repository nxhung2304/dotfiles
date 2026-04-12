# Clean Code Principles

A set of universal rules to keep code **readable, maintainable, and predictable**.
These principles apply to **all programming languages and architectures**.

---

# Table of Contents

1. Magic Numbers
2. Hardcoded Strings
3. Return Early (Guard Clauses)
4. Avoid Deep Nesting
5. Meaningful Names
6. Single Responsibility
7. DRY (Don't Repeat Yourself)
8. Function Size
9. Parameter Limit
10. Avoid God Classes
11. Prefer Immutability
12. Explicit Error Handling
13. Prefer Composition Over Inheritance
14. Readability Over Cleverness
15. Avoid Premature Optimization
16. File Size Limits
17. Consistent Code Style
18. Checklist Before Committing

---

# Magic Numbers

❌ Avoid using unexplained numeric values directly in code.

```
if (status.length > 5) { ... }
if (age >= 18) { ... }
retryCount < 3
```

✅ Extract them into named constants.

```
MAX_STATUS_LENGTH = 5
LEGAL_ADULT_AGE = 18
MAX_RETRIES = 3

if (status.length > MAX_STATUS_LENGTH)
if (age >= LEGAL_ADULT_AGE)
if (retryCount < MAX_RETRIES)
```

Benefits:

* Self-documenting code
* Easy to update values
* Prevents scattered constants

---

# Hardcoded Strings

❌ Avoid repeating hardcoded user-facing text.

```
print("Error occurred")
showMessage("User not found")
label = "Submit"
```

✅ Extract to constants or localization.

```
ERROR_OCCURRED = "Error occurred"
USER_NOT_FOUND = "User not found"
SUBMIT_LABEL = "Submit"

print(ERROR_OCCURRED)
showMessage(USER_NOT_FOUND)
```

Benefits:

* Easier localization
* Consistent messaging
* Centralized control

---

# Return Early (Guard Clauses)

❌ Avoid deeply nested conditionals.

```
if user != null
  if user.isActive
    if user.hasPermission
      process()
```

✅ Use guard clauses.

```
if user == null
  return

if not user.isActive
  return

if not user.hasPermission
  return

process()
```

Benefits:

* Flatter code
* Easier to read
* Reduces cognitive load

---

# Avoid Deep Nesting

❌ Avoid nesting deeper than 3 levels.

```
if a
  if b
    if c
      if d
        doSomething()
```

✅ Flatten logic.

```
if not a return
if not b return
if not c return
if not d return

doSomething()
```

Guideline:

Level 1–2: acceptable
Level 3: consider refactoring
Level 4+: refactor required

---

# Meaningful Names

❌ Avoid unclear names.

```
x
data
tmp
obj
val
```

✅ Use descriptive names.

```
userAge
errorMessage
orderTotal
validatedEmail
```

Naming rules:

Variables → nouns
Functions → verbs
Booleans → questions

Examples:

```
calculateTotal()
validateInput()
isActive
hasPermission
canDelete
```

Avoid:

* Abbreviations
* Single-letter variables (except loop counters)
* Generic names like `data` or `value`

---

# Single Responsibility

Each function, class, or module should **do one thing only**.

❌ Bad

```
saveUser()
  validateInput()
  parseData()
  sendRequest()
  updateUI()
```

✅ Better

```
validateUserInput()
parseUserData()
sendUserRequest()
updateUserInterface()
```

Benefits:

* Easier testing
* Easier maintenance
* Clearer structure

---

# DRY (Don't Repeat Yourself)

❌ Duplicate logic.

```
if startDate is empty
  showError()

if endDate is empty
  showError()

(repeated in multiple places)
```

✅ Extract shared logic.

```
validateDates(startDate, endDate)
```

When to extract:

* Logic appears more than twice
* Logic may change
* Logic is complex

---

# Function Size

Functions should be **small and focused**.

Recommended limit:

```
20–30 lines per function
```

❌ Bad

```
processOrder()
  validateInput
  calculatePrice
  applyDiscount
  updateInventory
  sendPayment
  logTransaction
  notifyUser
```

✅ Better

```
processOrder()
  validateOrder()
  calculatePrice()
  processPayment()
  finalizeOrder()
```

---

# Parameter Limit

Too many parameters make functions difficult to use.

Recommended limit:

```
max 3–4 parameters
```

❌ Bad

```
createUser(name, age, email, phone, address, role)
```

✅ Better

```
createUser(userRequest)
```

or

```
createUser({
  name,
  email,
  phone
})
```

---

# Avoid God Classes

❌ A class that handles too many responsibilities.

```
UserManager
  login
  logout
  sendEmail
  uploadAvatar
  calculateScore
  generateReport
```

✅ Split responsibilities.

```
AuthService
UserRepository
NotificationService
ReportService
```

Benefits:

* Clear boundaries
* Easier scaling
* Better testing

---

# Prefer Immutability

Immutable data reduces bugs.

❌ Mutable

```
user.name = "John"
user.age = 30
```

✅ Immutable

```
user = User(name="John", age=30)
```

or

```
updatedUser = user.copy(age=31)
```

Benefits:

* Predictable state
* Easier debugging
* Safer concurrency

---

# Explicit Error Handling

Never ignore errors.

❌ Bad

```
try
  riskyOperation()
catch
  doNothing()
```

✅ Good

```
try
  riskyOperation()
catch error
  logError(error)
  notifyUser()
```

Benefits:

* Easier debugging
* Safer systems

---

# Prefer Composition Over Inheritance

Inheritance chains become fragile.

❌ Bad

```
User
PremiumUser
PremiumUserWithDiscount
PremiumUserWithSpecialDiscount
```

✅ Prefer composition.

```
User
  discountPolicy
  permissionPolicy
```

Benefits:

* Flexible design
* Easier changes
* Lower coupling

---

# Readability Over Cleverness

Readable code is better than clever code.

❌ Hard to read

```
return list.filter(x => x.a && x.b || !x.c).map(x => x.value)
```

✅ Clear logic

```
validItems = list.filter(item =>
  item.isActive and
  item.hasPermission and
  not item.isExpired
)

return validItems.map(item => item.value)
```

Rule:

Code should be understandable **within seconds**.

---

# Avoid Premature Optimization

Do not optimize before measuring.

❌ Premature optimization

```
manual caching
bit manipulation
complex micro-optimizations
```

✅ First write clear code, then optimize if needed.

Steps:

1. Write readable code
2. Measure performance
3. Optimize bottlenecks

---

# File Size Limits

Large files become hard to maintain.

Recommended guideline:

```
300–400 lines per file
```

If a file grows too large:

* Split into modules
* Extract helpers
* Separate responsibilities

---

# Consistent Code Style

Maintain consistent formatting across the project.

Examples:

* consistent naming conventions
* consistent indentation
* consistent folder structure
* consistent error handling

Use:

* linters
* formatters
* automated checks

---

# Named Condition Variables

When a condition has **2+ checks**, extract to named boolean variables.

❌ Hard to read

```
if (value.isNotEmpty && index < total - 1) { ... }

color: isFilled || isActive ? colorA : colorB
border: isFilled || isActive ? colorC : colorD
```

✅ Self-documenting

```
hasInput = value.isNotEmpty
isNotLastField = index < total - 1

if (hasInput && isNotLastField) { ... }

isActiveState = isFilled || isActive
color: isActiveState ? colorA : colorB
border: isActiveState ? colorC : colorD
```

Rules:

* Condition with 2+ checks → name each check separately
* Condition repeated ≥ 2 times → extract one shared variable
* Boolean variable name must be a question: `isNotLastField`, `hasInput`, `canDelete`

---

# Checklist Before Committing

Before submitting code, verify:

* No magic numbers
* No duplicated logic
* No deep nesting (>3 levels)
* Functions are small and focused
* Names are descriptive
* Errors are handled
* No unnecessary complexity
* Code is readable
* Compound conditions (2+ checks) use named variables

Final rule:

If a new developer reads the code,
they should understand it **within minutes**.

---

# Core Philosophy

Good code is:

* readable
* predictable
* maintainable
* simple

Always prioritize:

```
clarity > cleverness
simplicity > complexity
maintainability > shortcuts
```

