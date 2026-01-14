# Specification: [FEATURE_NAME]

## Feature: [Feature Title]

### Overview
[Brief description of the feature]

### User Stories
- As a [user type], I want to [action] so that [benefit]

### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

### Functional Requirements

#### FR-1: [Requirement Name]
[Description]

#### FR-2: [Requirement Name]
[Description]

### Dependencies
- [Dependency 1]
- [Dependency 2]

### Assumptions
- [Assumption 1]
- [Assumption 2]

---

## Completion Signal

### Implementation Checklist
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]
- [ ] [Deliverable 3]

### Testing Requirements

The agent MUST complete ALL before marking done:

#### Unit & Integration Tests
- [ ] All existing unit tests pass
- [ ] All existing E2E tests pass
- [ ] New tests added for new functionality

#### Browser Verification
- [ ] Navigate to relevant pages
- [ ] Take screenshots
- [ ] Verify visual appearance
- [ ] Test interactive elements
- [ ] Check console for errors

#### Visual Verification
- [ ] Desktop view looks correct
- [ ] Tablet view looks correct
- [ ] Mobile view looks correct

#### Console/Network Check
- [ ] No JavaScript console errors
- [ ] No failed network requests
- [ ] No 4xx or 5xx errors

### Iteration Instructions

If ANY check fails:
1. Identify the specific issue
2. Fix the code
3. Commit and push
4. Re-test
5. Iterate until everything passes

**Output when ALL checks pass**: `<promise>DONE</promise>`
