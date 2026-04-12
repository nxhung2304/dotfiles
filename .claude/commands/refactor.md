---
allowed-tools: Bash(git add:*), Bash(git status:*), Grep
argument-hint: [scope]
description: Refactoring code to improve readability and maintainability
---

Refactor code in the specified scope (or current directory if no scope provided) following these guiding principles:

## Guiding Principles

### 1. Self-Documenting Code
- **Goal**: Write code that explains itself without comments
- **Method**: Use descriptive variable and method names that clearly express intent
- **Example**: Instead of `if (x > 0)`, use `if (hasValidItems)`

### 2. Early Returns
- **Goal**: Reduce nesting and improve readability
- **Method**: Return early from functions when conditions are not met
- **Pattern**: Check invalid conditions first, return null/default

### 3. Single Responsibility
- **Goal**: Each method should have one clear purpose
- **Method**: Break down complex methods into smaller, focused functions
- **Pattern**: Extract logic into helper methods with descriptive names

### Variable Naming Patterns

**Navigation Logic:**
```javascript
// Good - Describes what we're looking for
const upcomingGenreSection = genresData?.[nextGenreIndex];
const upcomingGenreHasPrograms = upcomingGenreSection?.programs?.length > 0;

// Bad - Generic names
const targetGenre = genresData?.[nextGenreIndex];
const hasPrograms = targetGenre?.programs?.length > 0;
```

**Section Navigation:**
```javascript
// Good - Clear direction and context
const sectionAfterGenres = sectionOrder[genresSectionIndex + 1];
const sectionBeforeGenres = sectionOrder[genresSectionIndex - 1];
const sectionAfterGenresHasContent = sectionAfterGenres && this.programLists[sectionAfterGenres]?.length > 0;

// Bad - Ambiguous names
const nextSection = allSectionKeys[currentListIndex + 1];
const prevSection = allSectionKeys[currentListIndex - 1];
const nextHasContent = nextSection && this.programLists[nextSection]?.length > 0;
```

**Position Management:**
```javascript
// Good - Describes the state and purpose
const previouslySavedPosition = this.listKeyPositions[genreKey];
const fallbackGenrePosition = `${genreKey}-${fallbackProgramIndex}`;
const savedPositionInSectionAfter = this.listKeyPositions[sectionAfterGenres];
const firstPositionInSectionAfter = `${sectionAfterGenres}-0`;

// Bad - Generic names
const savedPos = this.listKey[genreKey];
const defaultPos = `${genreKey}-${index}`;
const saved = this.listKey[nextSection];
const def = `${nextSection}-0`;
```

### Method Naming Patterns

**Navigation Methods:**
```javascript
// Good - Clear action and target
navigateGenresDown(currentGenreIndex, genresData)
navigateGenresUp(currentGenreIndex, genresData)
navigateToGenresFromRegularSection(direction)

// Bad - Generic names
goDown(index, data)
goUp(index, data)
handleGenres(direction)
```

**Helper Methods:**
```javascript
// Good - Describes what it returns
getGenrePosition(genreKey, fallbackProgramIndex)
hasGenrePrograms(genreSection)
getSectionAfter(sectionName)

// Bad - Generic names
getPosition(key, index)
checkData(data)
getNext(section)
```

### Code Structure Patterns

**Early Returns:**
```javascript
// Good - Check invalid conditions first
const hasGenres = allGenres?.length > 0;
if (!hasGenres) return null;

const targetGenreHasPrograms = targetedGenreSection?.programs?.length > 0;
if (!targetGenreHasPrograms) return null;

// Then handle valid case
const targetGenreKey = `genres-${targetGenreIndex}`;
return this.getGenrePosition(targetGenreKey, targetProgramIndex);
```

**Variable Declarations:**
```javascript
// Good - Group related variables, use descriptive names
const isNavigatingUpwards = direction === 'up';
const targetGenreIndex = isNavigatingUpwards ? allGenres.length - 1 : 0;
const targetedGenreSection = allGenres[targetGenreIndex];
const targetGenreHasPrograms = targetedGenreSection?.programs?.length > 0;

// Bad - Mixed variables, unclear purpose
const up = direction === 'up';
const idx = up ? allGenres.length - 1 : 0;
const genre = allGenres[idx];
const has = genre?.programs?.length > 0;
```

**Ternary Operators:**
```javascript
// Good - Use descriptive variables instead of inline ternary
const isNavigatingUpwards = direction === 'up';
const targetGenreIndex = isNavigatingUpwards ? allGenres.length - 1 : 0;
const targetProgramIndex = isNavigatingUpwards ? targetedGenreSection.programs.length - 1 : 0;

// Bad - Complex inline ternary
return `${key}-${direction === 'up' ? 'last' : 'first'}`;
```

### Refactoring Process

**Step 1: Extract Complex Logic**
- Identify methods that are doing too many things
- Extract related logic into focused helper methods
- Give each method a clear, descriptive name

**Step 2: Improve Variable Names**
- Replace generic names with descriptive ones
- Use prefixes like `has`, `is`, `can` for boolean variables
- Use full words instead of abbreviations

**Step 3: Reduce Nesting**
- Use early returns to exit early from invalid conditions
- Flatten nested if-else structures
- Keep the "happy path" as the main flow

**Step 4: Eliminate Comments**
- Replace comments with descriptive variable names
- Ensure method names explain what they do
- Let the code speak for itself

### Before and After Examples

**Before (Hard to read):**
```javascript
navigateGenresDown(idx, data) {
  const next = idx + 1;
  const target = data?.[next];
  if (target?.programs?.length > 0) {
    return this.getPosition(`genres-${next}`, 0);
  }
  const keys = Object.keys(this.programLists);
  const current = keys.indexOf('genres');
  const nextSection = keys[current + 1];
  if (!nextSection || !this.programLists[nextSection]?.length) return null;
  return this.listKey[nextSection] || `${nextSection}-0`;
}
```

**After (Self-documenting):**
```javascript
navigateGenresDown(currentGenreIndex, genresData) {
  const nextGenreIndex = currentGenreIndex + 1;
  const upcomingGenreSection = genresData?.[nextGenreIndex];
  const upcomingGenreHasPrograms = upcomingGenreSection?.programs?.length > 0;

  if (upcomingGenreHasPrograms) {
    return this.getGenrePosition(`genres-${nextGenreIndex}`, 0);
  }

  const sectionOrder = Object.keys(this.programLists);
  const genresSectionIndex = sectionOrder.indexOf('genres');
  const sectionAfterGenres = sectionOrder[genresSectionIndex + 1];
  const sectionAfterGenresHasContent = sectionAfterGenres && this.programLists[sectionAfterGenres]?.length > 0;

  if (!sectionAfterGenresHasContent) return null;

  const savedPositionInSectionAfter = this.listKeyPositions[sectionAfterGenres];
  const firstPositionInSectionAfter = `${sectionAfterGenres}-0`;

  return savedPositionInSectionAfter || firstPositionInSectionAfter;
}
```

### Checklist for Refactoring

- [ ] All variables have descriptive names
- [ ] No abbreviations unless widely understood
- [ ] Boolean variables start with `is`, `has`, `can`, etc.
- [ ] Methods have clear, action-oriented names
- [ ] Early returns used to reduce nesting
- [ ] Complex ternary operators replaced with variables
- [ ] Comments replaced with self-documenting code
- [ ] Each method has a single responsibility
- [ ] Related variables are grouped together
- [ ] Code reads like plain English

Remember: **The goal is to write code that your future self (and others) can understand without needing comments or explanations.**

