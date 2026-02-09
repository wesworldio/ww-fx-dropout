# Crash Logging Integration

This document describes the WesWorld crash logging integration in the macos-native project.

## Overview

The app now automatically reports crashes and errors to the WesWorld logging system, with local caching when offline.

## Features

✅ **Automatic Crash Reporting** - Unhandled exceptions are caught and logged  
✅ **Error Logging** - Errors logged via DiagnosticLogger are auto-submitted  
✅ **Offline Caching** - Logs saved locally when network unavailable  
✅ **Device Information** - System info collected automatically  
✅ **Local Configuration** - Uses `logging-config.json` for easy testing

## Configuration

### Local Development (Default)

The app uses `WesWorldFX/Resources/logging-config.json`:

```json
{
  "serverURL": "http://localhost:8787/api/logs",
  "apiKey": "ww-fx-dropout-prod-2026-01-01",
  "productName": "ww-fx-dropout"
}
```

**Note:** This file is configured for local development. Change the `serverURL` for production.

### Environment Variables (Optional)

Override config by setting:

```bash
export WW_LOGS_URL="https://your-server.workers.dev/api/logs"
export WW_LOGS_API_KEY="ww-fx-dropout-prod-2026-01-01"
```

### Priority Order

1. Explicit parameters (not used in this project)
2. `logging-config.json` in Resources
3. Environment variables
4. Hardcoded defaults

## Integration Points

### AppDelegate.swift

Crash handlers are initialized on app launch:

```swift
func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Initialize crash reporting FIRST
    WesWorldReporter.shared.setupCrashHandlers()
    
    // ... rest of initialization
}

func applicationWillTerminate(_ aNotification: Notification) {
    // Flush any pending logs
    Task {
        await WesWorldReporter.shared.flushPendingLogs()
    }
    
    // ... rest of cleanup
}
```

### DiagnosticLogger.swift

Errors and critical issues are automatically reported:

```swift
func error(_ message: String, error: Error? = nil, category: String = "ERROR") {
    // ... local logging
    
    // Submit to WesWorld
    if let error = error {
        Task {
            await WesWorldReporter.shared.logError(message, error, additionalInfo: ["category": category])
        }
    }
}

func critical(_ message: String, error: Error? = nil, stackTrace: [String]? = nil) {
    // ... local logging
    
    // Submit critical errors immediately
    if let error = error {
        Task {
            await WesWorldReporter.shared.logError(message, error, additionalInfo: ["level": "critical"])
        }
    }
}
```

## Testing

### 1. Start WesWorld Server

```bash
# From ww-logs-1 directory
make dev
```

Server will run at: `http://localhost:8787`

### 2. Run the App

```bash
make run
```

The app will connect to the local server automatically.

### 3. View Dashboard

Open `http://localhost:8787` in your browser  
Password: `WesWorld2026`

### 4. Trigger Test Errors

Errors logged through DiagnosticLogger will appear in the dashboard:

```swift
DiagnosticLogger.shared.error("Test error", error: someError, category: "TEST")
DiagnosticLogger.shared.critical("Critical test", error: someError)
```

## Log Storage

### Local Cache

Logs that fail to submit are cached at:

```
~/Library/Application Support/ww-fx-dropout/logs/
```

### Submission Behavior

- **Errors & Crashes**: Submitted immediately (with offline fallback)
- **Warnings**: Submitted immediately
- **Info**: Queued and batched (50 logs per batch)
- **Pending**: Submitted on next app launch

## Production Deployment

### 1. Update Configuration

Edit `WesWorldFX/Resources/logging-config.json`:

```json
{
  "serverURL": "https://ww-logs.your-domain.workers.dev/api/logs",
  "apiKey": "ww-fx-dropout-prod-2026-01-01",
  "productName": "ww-fx-dropout"
}
```

### 2. Rebuild and Test

```bash
make clean
make build
make run
```

Verify logs appear in production dashboard.

### 3. Security

**IMPORTANT**: Add to `.gitignore` if using production credentials:

```gitignore
macos-native/WesWorldFX/Resources/logging-config.json
```

Use environment variables for CI/CD pipelines.

## Manual Logging

You can log directly to WesWorld anywhere in the app:

```swift
// Log an error
Task {
    await WesWorldReporter.shared.logError(
        "Failed to process frame",
        error,
        additionalInfo: ["filter": "dropout", "frameCount": "\(count)"]
    )
}

// Log a warning
Task {
    await WesWorldReporter.shared.logWarning(
        "High memory usage detected",
        additionalInfo: ["usagePercent": "\(usage)"]
    )
}

// Log info
Task {
    await WesWorldReporter.shared.logInfo(
        "Filter changed",
        additionalInfo: ["newFilter": "dropout"]
    )
}
```

## Dashboard Features

- **Filter by Product**: See only `ww-fx-dropout` logs
- **Search**: Find specific error messages
- **Date Range**: View logs from specific timeframes
- **Device Info**: See which devices are affected
- **Stack Traces**: Full crash information
- **Export**: Download logs for analysis

## Troubleshooting

### Logs Not Appearing?

1. Check server is running: `curl http://localhost:8787`
2. Verify app console for connection errors
3. Check local cache: `~/Library/Application Support/ww-fx-dropout/logs/`

### Connection Refused?

- Ensure WesWorld server is running: `make dev` in ww-logs-1
- Verify port 8787 is not in use
- Check firewall settings

### API Key Errors?

- Verify key in `logging-config.json` matches server
- Check `X-API-Key` header is being sent
- Review server logs for authentication errors

## Files Modified

- `WesWorldFX/Sources/WesWorldReporter.swift` - **NEW** - Reporter implementation
- `WesWorldFX/Sources/AppDelegate.swift` - Added crash handler setup
- `WesWorldFX/Sources/DiagnosticLogger.swift` - Integrated WesWorld reporting
- `WesWorldFX/Resources/logging-config.json` - **NEW** - Configuration

## Related Documentation

- [WW_FX_DROPOUT_QUICKSTART.md](../macos-client/WW_FX_DROPOUT_QUICKSTART.md) - Quick start guide
- [WW_FX_DROPOUT_COMPLETE.md](../macos-client/WW_FX_DROPOUT_COMPLETE.md) - Complete reference
- [README.md](../macos-client/README.md) - macOS client examples

---

**Last Updated**: February 6, 2026  
**Version**: 2.1.3  
**Integration**: Complete ✅
