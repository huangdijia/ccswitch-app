# Build Requirements

## Xcode vs Command Line Tools

This project requires **full Xcode installation** for certain operations:

- ✅ **Fast builds**: `make fast-build` - Works with command line tools only
- ✅ **Running**: `make run` - Works with command line tools
- ✅ **Manual testing**: `make test-app` - Works with command line tools
- ❌ **Full builds**: `make build` - Requires Xcode
- ❌ **Unit tests**: `make test` - Requires Xcode

## Installing Xcode

If you need to run unit tests or build with full Xcode features:

1. Install Xcode from the App Store
2. Run the following command to set the active developer directory:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

## Alternative Build Methods

If you don't want to install Xcode, you can use:

- `make fast-build` - Compiles using swiftc directly
- `make run` - Builds and runs the app using fast-build
- `make test-app` - Runs manual tests without unit test framework

## Troubleshooting

If you see the error:
```
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
```

This means you have command line tools installed but not full Xcode. Use the alternative build methods above or install Xcode.