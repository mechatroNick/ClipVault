# Swift Code Style Guide

## Foundation

This guide extends [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with project-specific conventions for the clipboard manager app.

## Naming

### Types
- `UpperCamelCase` for types, protocols, and enums
- Prefix protocols with describing capability: `ClipboardStoring`, `Searchable`, `Encryptable`
- No Hungarian notation or type prefixes (no `I`, `T`, `k` prefixes)

### Variables & Functions
- `lowerCamelCase` for variables, functions, and methods
- Boolean variables use `is`/`has`/`should` prefixes: `isPinned`, `hasLargeFile`, `shouldEncrypt`
- Factory methods begin with `make`: `makeClipboardEntry(from:)`

### Abbreviations
- Treat abbreviations as words: `urlHandler` not `URLHandler`; `htmlRenderer` not `HTMLRenderer`
- Exception: `ID` is always uppercase: `entryID`, `pasteboardID`

## Structure & Organization

### File Layout (top to bottom)
1. File header comment (copyright, project)
2. Import statements (alphabetical, system frameworks first)
3. Type declaration
4. Nested types
5. Static/class properties
6. Instance properties (`let` first, then `var`)
7. Initializers
8. Public methods
9. Private methods
10. Protocol conformances (in extensions, one per extension)

### Extensions
- One protocol conformance per extension
- Mark with `// MARK: - ProtocolName`
- Group related functionality in extensions with descriptive comments

### Access Control
- Default to `private`; promote only when needed
- `private(set)` for properties that should be read externally but only mutated internally
- `internal` is the default — use explicitly only when intent needs clarity

## Formatting

### Indentation & Spacing
- 4 spaces per indentation level (no tabs)
- Opening brace on same line as declaration
- Closing brace on its own line, aligned with declaration start
- One blank line between type-level declarations
- No blank line between related property declarations

### Line Length
- Target 120 characters; hard limit 160
- Break long parameter lists with one parameter per line
- Break long function chains after the dot

### Colons & Commas
- No space before colon; one space after: `let name: String`
- In dictionaries: `[key: value]` (space after colon)
- Trailing commas allowed in multi-line arrays/dictionaries for cleaner diffs

### Parentheses
- Omit parentheses around conditional expressions: `if isReady { }` not `if (isReady) { }`
- Use parentheses for clarity in complex boolean expressions

## Swift Features

### Optionals
- Prefer `guard let` for early exit over `if let` nesting
- Use optional chaining over forced unwrapping — never use `!` without a preceding nil check
- Use nil-coalescing `??` for default values
- `if let shorthand` (Swift 5.7+): `if let name { }` instead of `if let name = name { }`

### Closures
- Trailing closure syntax for the last parameter of a function
- Use shorthand argument names (`$0`, `$1`) only in simple closures (≤1 line)
- Capture lists explicit when needed for clarity

### Concurrency
- Use `async/await` over completion handlers for all new code
- `@MainActor` for UI-bound observable objects
- `Task { }` and `Task.detached { }` clearly annotated with cancellation handling
- Use `AsyncSequence` for clipboard change monitoring

### Generics
- Descriptive generic parameter names: `<Entry>` over `<T>` where context is clear
- Use `where` clauses for protocol constraints

## Project-Specific Conventions

### Observable Objects
```swift
@Observable
final class ClipboardViewModel {
    private(set) var entries: [ClipboardEntry] = []
    private let storage: ClipboardStoring
    
    func fetchEntries() async { ... }
}
```

### GRDB Models
```swift
struct ClipboardEntry: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var content: Data
    var contentType: String
    var timestamp: Date
    var sourceApp: String?
    var isPinned: Bool
}
```

### CryptoKit Usage
```swift
import CryptoKit

struct EncryptionService {
    private let key: SymmetricKey
    
    func encrypt(_ data: Data) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        return sealed.combined!
    }
    
    func decrypt(_ data: Data) throws -> Data {
        let sealed = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealed, using: key)
    }
}
```

### Error Handling
- Define domain-specific error enums conforming to `LocalizedError`
- Use `throw` for recoverable errors; `preconditionFailure` for programmer errors
- Log errors through a centralized `Logger` (OSLog)

### Comments
- `///` for documentation comments (rendered in Xcode Quick Help)
- `// MARK: -` for section separators
- `// TODO:` for known future work
- `// FIXME:` for known bugs
- No redundant comments that restate the code

## SwiftLint Configuration

Recommended `.swiftlint.yml` rules:
- `force_unwrapping: error`
- `closure_body_length: warning: 50`
- `function_body_length: warning: 100`
- `type_body_length: warning: 400`
- `file_length: warning: 600`
- Enable all default opt-in rules
