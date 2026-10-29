---
name: rust-development
description: Implement, debug, or review Rust applications and libraries, including ownership, errors, Cargo configuration, tests, and performance.
---

# Rust development

Inspect the crate's edition, dependencies, API, and existing error and test conventions first. Model invariants with types when that makes invalid states meaningfully harder to represent; ordinary strings and booleans are appropriate when additional types would add ceremony without clarity. Borrow where it expresses the ownership contract, and clone when it is simpler and the cost is acceptable.

Preserve useful error context and handle expected failures at boundaries. Choose typed errors, existing application error utilities, or standard library types to suit callers and project conventions; do not introduce a dependency solely to follow a general rule. Treat unsafe code as a last resort and document its invariants.

Use the project's configured formatting and lint commands and run targeted tests for changed behavior. Consider empty input, boundaries, and failure paths where relevant. For performance changes, measure a representative workload before claiming improvement, and preserve numerical behavior and reproducibility where applicable.
