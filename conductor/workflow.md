# Development Workflow

## Test Coverage

**Required: ≥95% code coverage.** Every feature must include unit tests achieving ≥95% line coverage for ALL CODE IN THE PROJECT. Integration tests cover cross-component workflows. UI tests cover critical user paths (panel open, search, paste).

### Coverage Enforcement
- XCTest coverage reports generated on every build
- Coverage gates checked before task completion
- Uncovered branches must be justified with `// COVERAGE: <reason>` comments

## Commit Strategy

**Per-Task Commits.** After every completed task in the implementation plan, commit with a structured message.

### Commit Message Format
```
<type>(<scope>): <summary>

<body>

Closes: #<task>
Coverage: <percentage>%
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `security`, `chore`
Scopes: `storage`, `clipboard`, `ui`, `security`, `handoff`, `build`

Example:
```
feat(storage): Add encrypted SQLite persistence layer

Implements GRDB.swift database with AES-GCM encryption via CryptoKit.
Full-text search index on clipboard content. WAL mode for concurrent access.

Coverage: 97%
```

## Security Review

**Per-Phase Security Review.** At the end of each implementation phase, a dedicated security review must be performed before the phase is considered complete.

### Security Review Checklist
1. **Sandbox Compliance**: Verify all entitlements are minimal and justified
2. **Data at Rest**: Confirm encryption is applied to all persisted clipboard data
3. **Memory Hygiene**: Audit that clipboard content is cleared from memory after dismissal
4. **Input Validation**: Review all pasteboard content parsing for injection risks
5. **Keychain Hygiene**: Verify encryption keys use appropriate accessibility levels
6. **Network Surface**: Confirm zero unauthorized network access
7. **Third-Party Audit**: Review any dependency for supply-chain risks
8. **Content Filtering**: Validate sensitive content detection rules

### Review Artifact
Each security review produces a `SECURITY_REVIEW.md` in the track directory with pass/fail for each checklist item.

## Task Structure

### Feature Tasks
Every feature task follows Test-Driven Development:

```
- [ ] Task: <Feature description>
    - [ ] Write unit tests for <feature>
    - [ ] Write integration tests for <feature> (if cross-component)
    - [ ] Implement <feature>
    - [ ] Run test suite, verify ≥95% coverage
    - [ ] Run security review checklist (if applicable)
```

### Bug Fix Tasks
```
- [ ] Task: Fix <bug description>
    - [ ] Write regression test reproducing the bug
    - [ ] Implement fix
    - [ ] Verify regression test passes
    - [ ] Verify no existing tests break
```

## Phase Completion Verification and Checkpointing Protocol

At the end of each phase, the following verification steps must be completed:

1. **Build Verification**: `xcodebuild -scheme ClipVault -destination 'platform=macOS' clean build`
2. **Test Suite**: `xcodebuild test -scheme ClipVault -destination 'platform=macOS'` — all tests pass
3. **Coverage Report**: Generate and verify ≥95% coverage for new code
4. **Security Review**: Complete the per-phase security review checklist (see above)
5. **Documentation Update**: Update any affected documentation in `conductor/`
6. **Checkpoint Commit**: Commit with message `checkpoint(phase): <Phase Name> complete`

### Checkpoint Commit Format
```
checkpoint(phase): <Phase Name> complete

Build: ✅
Tests: ✅ (<N> passed, 0 failed)
Coverage: <X>%
Security Review: ✅ (<link>)

Co-authored-by: Conductor <conductor@local>
```

## Track Completion and Local Release Protocol

After all phases in a track implementation plan are completed, and before the track is marked as `[x]` in `tracks.md`, the following local release procedure MUST be followed:

1. **Final Release Build**: Perform a clean Release build to ensure maximum performance and stripped debug symbols.
   `xcodebuild -scheme ClipVault -destination 'platform=macOS' clean build -configuration Release`
2. **Local Deployment**: Copy the built `.app` bundle to the local `/Applications` folder, replacing any previous version.
   `rm -rf /Applications/ClipVault.app && cp -R <BUILT_PRODUCTS_DIR>/ClipVault.app /Applications/`
3. **Smoke Test**: Launch the application from `/Applications` to verify successful deployment and basic functionality.

## Release Process (Versioning & Tagging)

When a track implementation is complete and verified, the following release steps MUST be performed:

1. **Up Version**: Increment the version number in `ClipVault/Views/SettingsView.swift` (About view).
2. **Update Metadata**: Update `README.md` with the new version and release notes.
3. **Commit**: Make a final commit for the release with message `feat: Release vX.Y.Z - <Summary>`.
4. **Tag**: Create an annotated git tag for the release.
   `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
5. **Push**: Push changes and tags to the remote repository.
   `git push origin main --tags`
6. **Local Release**: Follow the "Track Completion and Local Release Protocol" to deploy the final version locally.

## Development Cadence

1. **Select Task**: Pick the next `[ ]` task from `plan.md`
2. **Write Tests**: Write failing tests first
3. **Implement**: Write minimal code to pass tests
4. **Verify**: Run test suite, check coverage
5. **Commit**: Per-task commit with structured message
6. **Repeat**: Move to next task
7. **Phase Complete**: After all tasks in a phase, run Phase Completion Verification
