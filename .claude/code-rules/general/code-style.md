# Code Style Guidelines

This document defines formatting and readability rules to keep code **consistent, easy to scan, and easy to maintain**.
These rules apply to **all languages unless a language-specific formatter overrides them**.

The goal is **visual clarity and predictable structure**.

---

# Table of Contents

1. Indentation
2. Line Length
3. One Statement Per Line
4. Blank Lines Between Logical Steps
5. Guard Clause Spacing
6. Blank Line Before Return Blocks
7. Avoid Dense Code
8. Condition Formatting
9. Function Formatting
10. Parameter Formatting
11. Chained Calls Formatting
12. Comments Style
13. Vertical Alignment
14. Trailing Commas
15. Consistent Braces
16. File Structure
17. Checklist

---

# Indentation

Use consistent indentation.

Recommended:

```
2 or 4 spaces
```

Avoid tabs unless the project explicitly requires them.

❌ Bad

```
if (condition){
doSomething()
}
```

✅ Good

```
if (condition) {
  doSomething()
}
```

---

# Line Length

Keep lines reasonably short for readability.

Recommended limit:

```
100–120 characters
```

If a line exceeds the limit, break it into multiple lines.

---

# One Statement Per Line

Each line should contain only one statement.

❌ Bad

```
if (a) doSomething()
```

✅ Good

```
if (a) {
  doSomething()
}
```

This improves readability and debugging.

---

# Blank Lines Between Logical Steps

Use blank lines to separate logical blocks.

❌ Bad

```
validateInput()
price = calculatePrice()
sendPayment(price)
notifyUser()
```

✅ Good

```
validateInput()

price = calculatePrice()

sendPayment(price)

notifyUser()
```

Blank lines act like **paragraphs in code**.

---

# Guard Clause Spacing

Add a blank line after guard clauses before the main logic.

❌ Bad

```
function process(user) {
  if (user == null) return
  if (!user.active) return
  runProcess()
}
```

✅ Good

```
function process(user) {
  if (user == null) return
  if (!user.active) return

  runProcess()
}
```

This clearly separates **validation** from **main logic**.

---

# Blank Line Before Return Blocks

When a return statement ends a logical block, separate it visually.

❌ Bad

```
if (!isValid) {
  logError()
  return error
}
```

✅ Good

```
if (!isValid) {
  logError()

  return error
}
```

This emphasizes the exit point.

---

# Avoid Dense Code

Do not compress multiple operations into one line.

❌ Bad

```
total = price * quantity - discount + tax
```

If the expression becomes complex, break it apart.

✅ Good

```
subtotal = price * quantity
discounted = subtotal - discount
total = discounted + tax
```

---

# Condition Formatting

Complex conditions should be split across lines.

❌ Bad

```
if (user.active && user.hasPermission && !user.expired && user.balance > 0)
```

✅ Good

```
if (
  user.active &&
  user.hasPermission &&
  !user.expired &&
  user.balance > 0
) {
  processUser()
}
```

This improves readability.

---

# Function Formatting

Leave a blank line between functions.

❌ Bad

```
function a() { }
function b() { }
```

✅ Good

```
function a() {
}


function b() {
}
```

This visually separates functions.

---

# Parameter Formatting

When parameters are long or numerous, place them on separate lines.

❌ Bad

```
createUser(name, email, phone, address, role)
```

✅ Good

```
createUser(
  name,
  email,
  phone,
  address,
  role
)
```

---

# Chained Calls Formatting

Long method chains should be broken across lines.

❌ Bad

```
result = list.filter(a).map(b).sort(c).limit(10)
```

✅ Good

```
result = list
  .filter(a)
  .map(b)
  .sort(c)
  .limit(10)
```

This makes pipelines easier to read.

---

# Comments Style

Prefer **self-documenting code** over excessive comments.

Use comments for:

* explaining complex logic
* documenting business rules
* clarifying non-obvious decisions

❌ Bad

```
# add 1 to counter
counter = counter + 1
```

✅ Good

```
counter += 1
```

Good comment example:

```
# Retry logic is required because the external API may timeout.
```

---

# Vertical Alignment

Avoid unnecessary vertical alignment.

❌ Bad

```
name     = "John"
email    = "john@email.com"
age      = 25
```

✅ Good

```
name = "John"
email = "john@email.com"
age = 25
```

Alignment often breaks when code changes.

---

# Trailing Commas

Prefer trailing commas in multi-line structures.

❌ Bad

```
items = [
  "a",
  "b"
]
```

✅ Good

```
items = [
  "a",
  "b",
]
```

Benefits:

* cleaner diffs
* easier additions

---

# Consistent Braces

Use a consistent brace style across the project.

Recommended:

```
if (condition) {
  doSomething()
}
```

Avoid mixing styles.

❌ Bad

```
if (condition)
{
  doSomething()
}
```

---

# File Structure

Typical file layout:

```
imports

constants

types / interfaces

main logic

helpers
```

Maintain consistent ordering.

---

# Checklist Before Committing

Verify the following:

```
consistent indentation
line length within limit
blank lines between logical steps
guard clauses visually separated
no dense one-line logic
long conditions formatted clearly
functions separated by blank lines
```

If code feels difficult to scan quickly, improve formatting.

---

# Philosophy

Good formatting helps developers:

* read code faster
* understand logic quickly
* reduce mental overhead

Code should look **structured and calm**, not dense or chaotic.

Whitespace is not wasted space — it improves clarity.
