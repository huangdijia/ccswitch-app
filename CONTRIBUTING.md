# Contributing to CCSwitch

Thank you for considering contributing to CCSwitch! This document provides guidelines and information to help you contribute effectively.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Description**: Clear description of the bug
- **Steps to Reproduce**: Step-by-step instructions
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: macOS version, CCSwitch version
- **Logs**: Relevant log files from `~/.ccswitch/ccswitch.log`

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use Case**: Why this enhancement would be useful
- **Proposed Solution**: How you envision the feature
- **Alternatives**: Alternative solutions you've considered
- **Examples**: Examples from other tools, if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the architecture** described in `ARCHITECTURE.md`
3. **Write tests** for your changes
4. **Update documentation** as needed
5. **Follow the code style** (see below)
6. **Create a pull request** with a clear description

## Development Setup

### Prerequisites

- macOS 14.6 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Setting Up the Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ccswitch-app.git
cd ccswitch-app

# Open in Xcode
open CCSwitch/CCSwitch.xcodeproj

# Or use command line tools
./run_dev.sh
```

### Project Structure

```
CCSwitch/
├── CCSwitch/
│   ├── App/           # Application entry point
│   ├── Models/        # Data models
│   ├── Protocols/     # Protocol definitions
│   ├── Services/      # Business logic
│   ├── Views/         # UI components
│   └── Resources/     # Assets and localization
└── CCSwitchTests/     # Unit tests
    └── Mocks/         # Mock implementations
```

## Coding Guidelines

### Architecture Principles

CCSwitch follows a **protocol-oriented architecture** with **dependency injection**. Please read `ARCHITECTURE.md` before making changes.

Key principles:
- Use protocols for abstraction
- Inject dependencies through initializers
- Keep components focused (Single Responsibility)
- Write tests for new functionality

### Swift Style Guide

#### Naming Conventions

```swift
// Classes, Structs, Enums, Protocols: UpperCamelCase
class VendorManager { }
protocol ConfigurationRepository { }

// Functions, Variables, Parameters: lowerCamelCase
func switchToVendor(with vendorId: String) { }
let currentVendor: Vendor

// Constants: lowerCamelCase
let maxBackups = 10

// Enums: UpperCamelCase for type, lowerCamelCase for cases
enum SettingsKey {
    case autoBackup
    case showNotification
}
```

#### Code Organization

```swift
// MARK: - Type Definition
class MyClass {
    // MARK: - Properties
    private let dependency: Dependency
    
    // MARK: - Initialization
    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    // MARK: - Public Methods
    func publicMethod() { }
    
    // MARK: - Private Methods
    private func privateMethod() { }
}

// MARK: - Protocol Conformance
extension MyClass: MyProtocol {
    func protocolMethod() { }
}
```

#### Comments and Documentation

```swift
/// Brief description of the function
///
/// Detailed explanation if needed. Describe edge cases,
/// performance considerations, or important behavior.
///
/// - Parameters:
///   - vendorId: The unique identifier of the vendor
///   - force: Whether to force the switch even if validation fails
/// - Returns: The newly active vendor
/// - Throws: `VendorError.notFound` if vendor doesn't exist
func switchToVendor(with vendorId: String, force: Bool = false) throws -> Vendor {
    // Implementation
}
```

### Testing Guidelines

#### Test Structure

```swift
class MyFeatureTests: XCTestCase {
    // MARK: - Properties
    var sut: SystemUnderTest!
    var mockDependency: MockDependency!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        sut = SystemUnderTest(dependency: mockDependency)
    }
    
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testFeature_whenCondition_thenExpectedBehavior() {
        // Given
        let input = "test"
        mockDependency.shouldSucceed = true
        
        // When
        let result = sut.doSomething(with: input)
        
        // Then
        XCTAssertEqual(result, "expected")
        XCTAssertEqual(mockDependency.callCount, 1)
    }
}
```

#### Test Coverage

- **Unit tests**: Test individual components in isolation
- **Integration tests**: Test component interactions
- **Edge cases**: Test error conditions, empty inputs, boundary values
- **Performance tests**: Test performance-critical code

#### Mock Objects

Create mocks in `CCSwitchTests/Mocks/`:

```swift
class MockMyProtocol: MyProtocol {
    var callCount = 0
    var shouldThrowError = false
    var returnValue: String?
    
    func myMethod() throws -> String {
        callCount += 1
        if shouldThrowError {
            throw MyError.failed
        }
        return returnValue ?? "default"
    }
}
```

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:

```
feat(vendor): add support for Azure OpenAI

Implement Azure OpenAI vendor template with required
environment variables and default values.

Closes #123
```

```
fix(backup): handle permission errors gracefully

Add proper error handling when backup directory is not writable.
Display user-friendly error message instead of crashing.

Fixes #456
```

## Adding New Features

### 1. Adding a New Vendor Template

See `EXTENSION_GUIDE.md` for detailed instructions. Quick example:

```swift
// In VendorTemplate.swift
extension VendorTemplate {
    static let myVendor = VendorTemplate(
        id: "my-vendor",
        name: "My Vendor",
        baseURL: "https://api.myvendor.com",
        requiredEnvVars: ["API_KEY"],
        optionalEnvVars: ["MODEL"],
        defaultValues: ["BASE_URL": "https://api.myvendor.com"],
        description: "My Vendor AI Service"
    )
}

// Add to templates array
static let templates: [VendorTemplate] = [
    // ... existing templates
    .myVendor,
]
```

### 2. Adding a New Protocol Implementation

```swift
// Define the implementation
class MyCustomRepository: ConfigurationRepository {
    // Implement all protocol methods
}

// Add tests
class MyCustomRepositoryTests: XCTestCase {
    func testGetAllVendors() throws {
        let repo = MyCustomRepository()
        let vendors = try repo.getAllVendors()
        XCTAssertFalse(vendors.isEmpty)
    }
}

// Document in EXTENSION_GUIDE.md
```

### 3. Adding UI Components

```swift
struct MyNewView: View {
    var body: some View {
        VStack {
            // Use DesignSystem for consistent styling
            ModernSection(title: "My Section") {
                ModernRow(
                    icon: "star.fill",
                    iconColor: .blue,
                    title: "My Feature"
                )
            }
        }
    }
}
```

## Localization

CCSwitch supports multiple languages. When adding user-facing strings:

```swift
// In code
Text(LocalizedStringKey("my_new_string"))

// In en.lproj/Localizable.strings
"my_new_string" = "My New String";

// In zh-Hans.lproj/Localizable.strings
"my_new_string" = "我的新字符串";

// In zh-Hant.lproj/Localizable.strings
"my_new_string" = "我的新字串";
```

## Documentation

Update documentation when:
- Adding new features
- Changing architecture
- Updating APIs
- Fixing bugs (if user-visible)

Documentation files:
- `README.md`: User-facing documentation
- `ARCHITECTURE.md`: Architecture details
- `EXTENSION_GUIDE.md`: Extension instructions
- `CONTRIBUTING.md`: This file

## Review Process

1. **Self-review**: Review your own changes before submitting
2. **Automated checks**: Ensure tests pass
3. **Code review**: Address reviewer feedback
4. **Approval**: Get approval from maintainers
5. **Merge**: Changes will be merged to main branch

## Release Process

Maintainers will:
1. Update version numbers
2. Update CHANGELOG
3. Create release notes
4. Build and sign the app
5. Create GitHub release
6. Update Homebrew formula (if applicable)

## Getting Help

- **Documentation**: Check `ARCHITECTURE.md` and `EXTENSION_GUIDE.md`
- **Issues**: Search existing issues or create a new one
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact maintainers directly for sensitive issues

## Recognition

Contributors will be:
- Listed in the README
- Mentioned in release notes
- Given credit in commit messages (Co-authored-by)

Thank you for contributing to CCSwitch! 🎉
