# Contributing Guide

Thank you for contributing to LunarV.

## Development Requirements

- macOS
- Xcode (latest stable recommended)
- Swift toolchain included with Xcode

## Local Build

```bash
xcodebuild -project LunarV.xcodeproj -scheme LunarV -configuration Debug -sdk macosx build
```

## Branching

- `main`: stable branch.
- Use feature branches for changes, for example:
  - `feat/menu-ui-improvements`
  - `fix/lunar-conversion-edge-case`

## Commit Messages

Use clear, scoped messages. Conventional Commits are recommended:

- `feat: ...`
- `fix: ...`
- `refactor: ...`
- `docs: ...`
- `chore: ...`

## Pull Requests

Before opening a PR:

1. Build successfully.
2. Keep changes focused.
3. Update documentation if behavior changes.
4. Add tests where applicable.

## Code Style

- Follow existing Swift style and naming.
- Prefer semantic colors/materials for macOS UI.
- Keep business logic in `ViewModel`/`Core`, keep Views declarative.

## Reporting Issues

Use GitHub Issues and select the relevant issue template.
