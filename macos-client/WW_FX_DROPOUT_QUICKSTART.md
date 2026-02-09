# ww-fx-dropout: Quick Integration Guide

Get crash logging and error reporting working in 5 minutes.

---

## 1. Copy the Reporter

Copy `WesWorldReporter.swift` to your Xcode project:

```bash
# From your ww-fx-dropout project
cp path/to/ww-logs-1/examples/macos-client/WesWorldReporter.swift ./Sources/
```

---

## 2. Initialize in AppDelegate

```swift
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize crash reporting (do this first!)
        WesWorldReporter.shared.setupCrashHandlers()
        
        // ... rest of your setup
    }
}
```

---

## 3. Log Crashes (Automatic)

Crashes are now caught and reported automatically. The system:

- ✅ Catches unhandled exceptions
- ✅ Collects device info (model, OS, memory, processor)
- ✅ Saves crashes locally if network unavailable
- ✅ Submits to WesWorld on next successful connection

---

## 4. Log Errors Manually

Wrap error-prone code:

```swift
func loadConfig() async {
    do {
        let data = try Data(contentsOf: configURL)
        // Process...
    } catch {
        Task {
            await WesWorldReporter.shared.logError(
                "Failed to load configuration",
                error,
                additionalInfo: ["configPath": configURL.path]
            )
        }
    }
}
```

---

## 5. Test Locally

Start the server and test:

```bash
# Terminal 1: Start WesWorld Logs server
cd ww-logs-1
make dev

# Terminal 2: Run your app and trigger an error
# Then check: http://localhost:8787 (password: WesWorld2026)
```

Update your app to use local endpoint for testing:

```swift
// In WesWorldReporter initialization
serverURL: "http://localhost:8787/api/logs"
```


---

## 6. Deploy & Configure

Once ready for production:

1. **Deploy WesWorld** server to Cloudflare:
   ```bash
   cd ww-logs-1
   make deploy
   ```

2. **Update API key** in your app (use environment variable or config file):
   ```swift
   let reporter = WesWorldReporter(
       serverURL: "https://your-domain.workers.dev/api/logs",
       apiKey: "ww-fx-dropout-prod-2026-01-01"
   )
   ```

3. **Never hardcode** the API key in source:
   - Use a `logging-config.json` not tracked in git
   - Or set environment variables
   - Or use Xcode configuration files

---

## Usage Examples

### Log an error

```swift
do {
    try operation()
} catch {
    Task {
        await WesWorldReporter.shared.logError("Operation failed", error)
    }
}
```

### Log a warning

```swift
if memoryUsageHigh {
    Task {
        await WesWorldReporter.shared.logWarning(
            "High memory usage detected",
            additionalInfo: ["usagePercent": "\(usage)"]
        )
    }
}
```

### Log info```swift
Task {
    await WesWorldReporter.shared.logInfo(
        "Feature X enabled for user",
        additionalInfo: ["userId": "user-123"]
    )
}
```

### Flush pending logs

```swift
func applicationWillTerminate(_ notification: Notification) {
    Task {
        await WesWorldReporter.shared.flushPendingLogs()
    }
}
```

---

## Configuration

### Environment Variables

Set these before running your app:

```bash
export WW_LOGS_URL="https://ww-logs.your-domain.workers.dev/api/logs"
export WW_LOGS_API_KEY="ww-fx-dropout-prod-2026-01-01"
```

### Config File (Recommended for Production)

Create `logging-config.json` in your app bundle:

```json
{
  "serverURL": "https://ww-logs.your-domain.workers.dev/api/logs",
  "apiKey": "ww-fx-dropout-prod-2026-01-01",
  "productName": "ww-fx-dropout"
}
```

Load it:

```swift
struct LoggingConfig: Codable {
    let serverURL: String
    let apiKey: String
}

func loadLoggingConfig() -> LoggingConfig? {
    guard let url = Bundle.main.url(forResource: "logging-config", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let config = try? JSONDecoder().decode(LoggingConfig.self, from: data) else {
        return nil
    }
    return config
}
```

Add to `.gitignore`:

```text
logging-config.json
```

---

## Dashboard

View all logs at: `https://ww-logs.your-domain.workers.dev`

**Password**: Set in `src/index.js` (default: `WesWorld2026`)

Features:

- 🔍 Filter by product, date, device
- 💾 View full stack traces
- 🤖 Copy logs for AI analysis
- 📊 See error trends

---

## Troubleshooting

### Logs not appearing?

1. Check the app is actually running and hitting code paths
2. Verify network connectivity
3. Confirm API key is correct
4. Check server is running/deployed:

   ```bash
   curl https://ww-logs.your-domain.workers.dev
   ```

### Getting 401 Unauthorized?

- Verify API key is correct
- Ensure `X-API-Key` header is being sent
- Check product name matches configuration

### Crashes happening but not reported?

- Verify `setupCrashHandlers()` is called early
- Check that the server URL is reachable
- Review logs in Xcode console

---

## For More Details

See the full [macOS Integration Guide](../docs/MACOS_INTEGRATION_GUIDE.md) for:

- Advanced features (batch submission, retry logic, caching)
- Custom crash formatting
- Thread-safe logging
- Performance optimization
