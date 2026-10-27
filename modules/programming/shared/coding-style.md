---
name: coding-style
description: Review code against the user's personal coding rubric and report evidence-based ratings and actionable improvements. Use when asked for a coding-style review or rubric assessment.
---

Review only the requested code or diff. Do not edit files or create commits
unless requested.

Use the rubric below as review criteria, not a request to rewrite the code.
Assess these categories on a 0–5 scale:

- Project fit: conventions, tooling, scope, and consistency.
- Readability: naming, intermediate values, constants, conditions, and nesting.
- Design: focused responsibilities, interfaces, and appropriate abstraction.
- Documentation: useful docstrings and minimal, purposeful comments.
- Reliability: error handling and meaningful verification.
- Scientific clarity, when applicable: notation, units, shapes, tolerances,
  numerical stability, and reproducibility.

Rating anchors: 0 = fundamentally conflicting; 1 = major issues;
2 = substantial improvements needed; 3 = mostly aligned with some issues;
4 = well aligned with minor issues; 5 = fully aligned in the inspected scope.
Mark inapplicable or unassessable categories N/A and explain why. Do not infer
that tests or checks passed from their existence. Do not penalize code for
following project conventions or for lacking irrelevant abstractions.

Report the inspected scope, category scores with brief evidence, and an
overall score out of 100 using the mean of assessed categories divided by
five. Treat this as a subjective rubric assessment, not proof of correctness.
Prioritize actionable findings with file/line references and explain their
impact; distinguish correctness defects from style preferences. End with the
most useful improvements and verification limitations. Avoid inventing issues
merely to lower a score or recommending unrelated rewrites.

## Review rubric
