# Agent Principles

Behavioral principles the AI agent must follow during development work.

---
## [Philosophy] Code Principles

- **Single Source of Truth (SSOT)** — Specs, types, constants, and schemas must be defined only in the project-designated authoritative files. Do not redefine them elsewhere or replace them with inline literals.
- **DRY (knowledge, not shape)** — Every fact or rule (domain values, taxonomy, schemas, calculation rules, copy, design tokens, routes) lives in exactly one place from its first use. Identical logic that must change together is extracted at the second occurrence. Merely similar code whose differences would need flags or mode parameters stays duplicated until a third case shows what actually varies; when an extracted helper grows caller-specific branches, inline it back. Test: if one copy changes, must the other change too?
- **Simplicity First (KISS)** — Choose the simplest solution that meets requirements. Avoid premature abstraction and over-engineering. Add complexity only when justified.
- **YAGNI (You Aren't Gonna Need It)** — Do not implement features, options, configurations, abstractions, or infrastructure that are not required by the current task. Future requirements are added when they actually arise. YAGNI never removes anything on the Safety Floor below.
- **Safety Floor (Never Cut)** — Simplicity, YAGNI, and Minimal Change never justify omitting: input validation at trust boundaries, error handling that prevents data loss, security checks, accessibility, or anything the user explicitly asked for.
- **Reuse-First Ladder** — Before writing new code, take the first option that fully works: (1) Is it needed at all? Skip unrequested features and options, and name what you skipped in one line. (2) An existing helper, component, or pattern in this codebase — search the placement levels listed in the project convention's Shared Placement slot, nearest level first, and use it the way the surrounding code does. (3) The standard library or a platform feature. (4) An already-installed dependency — never add a dependency for a few lines. (5) Otherwise, the minimum code that works. Be lazy about the solution, never about the change: finish every caller, test, and fixture the change breaks. For a bug fix, find every caller of the function first and fix the root cause once in the shared code.
- **Fail Fast (Core Flows)** — In correctness-critical paths, surface errors immediately and stop execution. Prevent large costs at later stages.
- **Explicit Handling (No Implicit Fallback)** — All failures and edge cases must be handled explicitly; silent or implicit fallback is prohibited.
- **Graceful Degradation for Non-Critical Paths** — Failures in non-critical features (analytics, notifications, telemetry) must not block core flows (auth, checkout, payment). Isolate failure scope; core flows always apply Fail Fast.

## [Structure] Module Structure & Shared Placement

These criteria are stack- and layout-agnostic. The concrete directories, segment names, public-API locations, and thresholds are the project's choice, recorded in the structure slots (S1–S8) of the project convention's Project Decisions. If a slot is unresolved (`미확정` or still a `[...]` placeholder), apply only these criteria, do not invent a layout, and name the unresolved slot in the completion report.

- **File = what changes together** — Put functions that share a data source, a business rule, or a reason to change into one file per module segment. A single-function file is justified only for a framework unit (component, hook, screen/route, a class the framework requires), a utility used by several modules, a runtime boundary that forces a split (client/server directive, platform-specific file), or a versioned variant.
- **Subdirectories by cohesion** — Keep a module flat until a segment needs several private files that change together, or the module passes the threshold set in S2. Never create a directory per function.
- **Placement = nearest common ancestor of the users** — Scope levels, nearest first: file → module → app-wide generic → app-wide domain → workspace-shared (multi-package repos only, for code two or more apps consume). Place code no higher than its current users need.
- **Generic shared code knows no business** — App-wide generic code never imports feature modules or uses domain terms. Shared code with domain meaning goes to the domain level and takes per-feature differences as parameters, props, or slots. Dependencies flow one way: shared → features → app/routes.
- **One public surface per module boundary** — Expose a module only through the boundary defined in S4. Do not import another module's internals, do not import your own module's public entry from inside the module, and keep import cycles at zero.
- **Promotion is a contract** — Code moved to a shared level gets a usage comment, tests, and explicit exports, and changing it means checking every caller. Demote it (inline back) when only one caller remains or callers need their own branches.

## [Pre-Work] Checklist Before Starting

1. **Read Before Touch** — Never suggest modifications without first reading the relevant code. Always read before acting.
2. **Spec First** — Check the relevant PRD/TRD sections before implementation or design-affecting work.
3. **Scope Declaration** — Explicitly state the change scope (which files, which features). If the user explicitly asks to implement, fix, or update a specific scope, treat that request as approval for that scope.
4. **Ask Before Expanding Scope** — Ask before generating code when the request is ambiguous, context is insufficient, more than 3 files may be affected, architecture/API contracts may change, or work outside the requested scope is needed.

## [Done] Definition of Done

5. **Zero Lint/Type Errors** — Work is complete only when there are no lint or TypeScript errors.
6. **Tests Pass** — Relevant tests must pass. New non-trivial logic (a branch, a loop, a parser, a state transition, money or security logic, a bug fix, or a whole new script) leaves at least one test that fails when that logic breaks; trivial changes (types, constants, copy, config values) need none. If no test infrastructure exists, explicitly flag the need for it.
7. **Spec Compliance** — Directly verify that the implementation matches PRD/TRD specs.
8. **No Silent TODOs or Gaps** — All unresolved TODOs and temporary code must be explicitly flagged before marking work complete. End the completion report with one or two lines naming what was not verified (e.g. screens not rendered, callers not checked, edge cases not tested) and any residual risk the user must know. Write "none" only when everything was actually verified.

## [Prohibited] Hard Rules

9. **No Unauthorized Code** — Do not generate code outside the approved or user-requested scope. If scope is unclear, ask first.
10. **No Dev Server Start** — Do not run the dev server (e.g. `pnpm dev`). Assume it is always already running. For mobile UI verification, use feasible lint/type/test/static checks; if simulator or device validation is required, ask the user to verify it.
11. **No Unauthorized Git** — Do not run `git commit` or `git push` without an explicit request.
12. **No Safety Bypass** — Do not bypass safety mechanisms such as `--no-verify`, `--force`, or `--hard`.
13. **No Scope Creep** — Do not refactor, improve, or add features outside the requested scope.
14. **No Destructive Action** — Do not delete files, branches, or other resources without explicit confirmation.

## [Scope Control] Minimal Change Principle

15. **Minimal Change** — Change only what was requested. Do not clean up unrelated code or add comments.
16. **One Task, One Unit** — Keep a single task to a single PR unit. Do not bundle multiple concerns together.
17. **No Premature Abstraction** — Do not create abstractions for future requirements not in the current scope.

## [State & Context] Maintain Consistency

18. **Explicit Progress** — Share decisions and progress status explicitly during work.
19. **Persist Decisions** — Record working preferences, feedback, and context that must persist across sessions in memory. Team engineering decisions belong in repository docs (rule 20), not in memory.
20. **Record Engineering Decisions** — When a decision binds how future code is written (library or architecture choice, module/directory structure, API conventions, auth, storage/caching, test strategy) and it is costly to reverse, spreads across modules, was chosen over real alternatives, or will later raise "why?", propose an ADR in the same message as the decision and write `docs/decisions/ADR-NNN-<slug>.md` only after the user confirms. Product/domain policy (PRD/FRD), bug fixes, and changes that follow existing patterns are not ADRs. Never edit an accepted ADR's body — supersede it with a new one. Follow the format of existing ADRs (devoks-sdlc defines it in its `adr-guide.md`).
21. **Apply Past Feedback** — Always apply feedback received in previous conversations to subsequent work.
