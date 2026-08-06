---
name: clean-code
description: Review, refactor, or implement maintainable Dart and Flutter code with clear responsibilities, dependency boundaries, intentional state ownership, useful naming, testability, and minimal duplication. Use for clean-code reviews, large-file decomposition, feature-first architecture work, Riverpod provider cleanup, dead-code removal, technical-debt reduction, or requests to improve readability without changing behavior.
---

# Clean Code

Improve code structure without trading correctness for aesthetics. Preserve observable
behavior unless the user explicitly requests a behavior change.

## Establish scope

1. Determine whether the user asked to review, diagnose, plan, or modify code.
2. Inspect repository instructions, architecture documents, current imports, consumers,
   tests, and working-tree state before proposing moves or deletions.
3. For this repository, read `doc/architecture/feature_first_architecture.md` before
   changing Flutter architecture or Riverpod state ownership.
4. Record a baseline with relevant analysis and tests before a broad refactor.
5. Preserve unrelated user changes and public APIs unless changing them is in scope.

For review-only requests, report evidence and recommendations without editing files.

## Review by responsibility

Evaluate each unit using these questions:

- Does it have one coherent reason to change?
- Does its name reveal domain intent rather than implementation mechanics?
- Is business state owned in exactly one place?
- Does it depend inward through an intentional contract?
- Can it be tested without rendering unrelated UI or constructing infrastructure?
- Is repeated logic genuinely the same concept, or merely similar-looking code?
- Does error handling preserve context and provide a recovery path?
- Do comments explain constraints or decisions instead of narrating syntax?
- Is dead code, compatibility scaffolding, or speculative abstraction still present?

Treat 200 lines as a review signal, not an automatic failure. Split a file when it mixes
responsibilities, changes for unrelated reasons, or prevents focused testing. Keep a
cohesive file intact even when an arbitrary line target would produce artificial fragments.

## Apply refactors safely

Use the smallest structural change that resolves the demonstrated problem:

1. Make ownership explicit before moving files.
2. Consolidate duplicate state before adding new providers or controllers.
3. Extract domain concepts and pure calculations before extracting cosmetic wrappers.
4. Prefer dependency injection and narrow interfaces at volatile boundaries.
5. Keep UI composition declarative; move state transitions and derived calculations to
   the application layer.
6. Delete dead code only after verifying routes, imports, references, tests, generated
   outputs, and framework registration points.
7. Avoid abstractions with one speculative consumer; follow YAGNI.
8. Separate pure file moves from behavior changes when commits are requested.

Do not hide complexity behind generic names such as `Manager`, `Helper`, `Utils`, or
`Common`. Name types after the business responsibility they own.

## Flutter and Riverpod boundaries

Follow the repository's feature-first structure:

```text
lib/features/<feature>/
├── domain/
├── data/
├── application/
└── presentation/
```

- Keep Flutter and Riverpod imports out of `domain/`.
- Keep repository implementations and external I/O in `data/`.
- Keep providers, controllers, orchestration, and derived state in `application/`.
- Keep screens and feature-specific widgets in `presentation/`.
- Prevent presentation from importing data implementations directly.
- Expose narrow application contracts when another feature needs state or commands.
- Put a widget in `core/widgets/` only when at least two features genuinely use it.
- Use `application/`, not a top-level `bloc/`, while Riverpod is the state solution.
- Never edit `.g.dart` or `.freezed.dart` manually; regenerate from source annotations.

## Validate

Validate in proportion to the change:

1. Format touched Dart files.
2. Search for stale imports, duplicate providers, forbidden layer dependencies, and
   references to removed symbols.
3. Run targeted unit/widget tests while iterating.
4. Run `dart analyze` and the full `flutter test` suite for architecture-wide changes.
5. Generate coverage when application or business logic changes materially.
6. Inspect the final diff for accidental behavior changes, generated noise, secrets,
   unrelated files, and whitespace errors.

Do not claim clean code solely because analysis passes or files are short. Report the
ownership decisions, responsibilities separated, tradeoffs retained, and verification
results.
