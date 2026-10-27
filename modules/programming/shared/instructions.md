# Shared Coding Instructions

## Project conventions come first

Read applicable repository instructions and inspect nearby code, documentation, tooling configuration, and recent commits. Follow established styles, architecture, dependencies, commands, and workflows. Project conventions take precedence over conflicting preferences below. Apply these defaults in new projects or wherever conventions leave a choice open, including personal projects.

## Readable code

- Prefer clear, straightforward code over cleverness, terseness, or minimizing the number of variables. Use descriptive intermediate variables to explain intent and simplify expressions. Avoid meaningless aliases and redundant state.
- Give domain values, thresholds, tolerances, conversion factors, and other unexplained literals meaningful names. Use appropriately scoped constants or variables. Ordinary structural values such as zero, one, or empty collections need names only when their meaning warrants one.
- Name variables, functions, and types for their meaning and responsibility, following language idioms and project vocabulary. Boolean names should make conditions read naturally.
- When a condition becomes difficult to read, extract it into a clearly named boolean variable or predicate. Preserve evaluation order, short-circuiting, and lazy behavior when doing so.
- Prefer guard clauses and early returns when they simplify control flow. When nesting, indentation, or mixed responsibilities obscure intent, extract a coherent operation into a well-named function. Avoid arbitrary line-count limits and helpers that merely relocate complexity.
- Keep functions focused and interfaces straightforward. Avoid duplication when a shared concept is clear, but do not introduce speculative abstractions, generic frameworks, or configuration for hypothetical future needs.

## Comments and documentation

- Make code understandable through naming, structure, and small coherent operations. Keep comments minimal; do not narrate obvious code or use explanatory comments to compensate for confusing implementation.
- Retain useful comments explaining reasoning, constraints, assumptions, tradeoffs, workarounds, or surprising behavior that the code alone cannot convey. Update them when the behavior changes.
- Docstrings are important interface documentation. Document public API functions, classes, and modules according to project conventions. Explain relevant parameters, return values, units, shapes, assumptions, side effects, and errors without restating signatures or adding boilerplate.
- Update relevant documentation and examples when changing public behavior or setup requirements.

## Scientific and numerical work

- Where the language and tooling support it, prefer Unicode identifiers when they clarify the connection to mathematical notation. Match the equations and surrounding code; use descriptive names where symbols obscure meaning.
- Make units, coordinate conventions, array shapes, numerical assumptions, and tolerances explicit where relevant. Avoid ambiguous conversions and unexplained numerical approximations.
- Make randomized calculations reproducible when appropriate, using explicit seeds or random generators. Consider numerical stability, precision, and meaningful boundary cases when changing calculations.

## Changes and error handling

- Make focused, complete changes that address the requested behavior. Preserve unrelated work and avoid incidental refactors, dependency upgrades, and formatting churn. Address nearby issues necessary for correctness; mention other material findings separately.
- Follow existing error-handling patterns. Handle expected failures explicitly and provide useful context. Do not silently swallow errors, disguise failure as success, or return plausible placeholder results. Validate inputs at boundaries; avoid redundant internal checks.
- Avoid destructive commands unless explicitly requested or clearly authorized. Do not overwrite or discard existing work to make a task easier.

## Formatting and verification

- Discover and use the project's configured formatters, linters, build commands, and test runners. After writing code, run the applicable formatting and lint checks with the repository's configuration. Inspect the final diff for accidental changes.
- Run checks appropriate to the change. Test meaningful behavior, edge cases, and regressions. Prefer observable behavior over implementation details; avoid unnecessary tests for trivial, reversible edits.
- Fix issues introduced by your changes. Distinguish pre-existing failures from new failures. Report which checks ran, their results, and any material limitations or unverified behavior. Never claim a check passed without running it.

## Commits and communication

Inspect recent commit messages and follow the repository's convention. When no convention exists, use `type(scope): concise description`, with one primary type and scope per commit. Add short, factual detail lines when useful. Keep cohesive changes together and split independent changes into separate commits. For example:

```text
feat(ai): add t3code and centralize agent configuration

- add Codex, OpenCode, and Claude tooling
- migrate OpenCode to v2
- share skills and instructions across agents
```

Keep responses concise, direct, and actionable. Explain the resulting behavior, important decisions, verification, and remaining limitations. State assumptions and uncertainty honestly.
