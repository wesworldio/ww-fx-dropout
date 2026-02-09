# Complete macOS Integration Guide for ww-fx-dropout

This document provides everything needed to integrate WesWorld Logs crash reporting into the ww-fx-dropout macOS application.

---

## 📋 What You Get

✅ **Automatic Crash Reporting** - Catches unhandled exceptions and logs them  
✅ **Error Logging** - Submit errors from anywhere in your app  
✅ **Device Information** - Automatically collects system info (model, OS, memory, processor)  
✅ **Offline Caching** - Saves logs locally if network is unavailable  
✅ **Web Dashboard** - View, search, and analyze all submitted logs  
✅ **API Key Authentication** - Secure log submission with API keys  

---

## 🚀 Quick Start (5 Minutes)

### 1. Copy the Reporter Class

```bash
cp examples/macos-client/WesWorldReporter.swift /path/to/your/ww-fx-dropout/project
```

### 2. Initialize in AppDelegate

```swift
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        WesWorldReporter.shared.setupCrashHandlers()
        // ... rest of setup
    }
}
```

### 3. Start Local Testing

```bash
# Terminal 1: Start WesWorld server
cd ww-logs-1
make dev

# Terminal 2: Run your app
# Logs will appear at: http://localhost:8787
# Password: WesWorld2026
```

That's it! Your app now reports crashes automatically.

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [WW_FX_DROPOUT_QUICKSTART.md](WW_FX_DROPOUT_QUICKSTART.md) | 5-minute integration guide |
| [../docs/MACOS_INTEGRATION_GUIDE.md](../docs/MACOS_INTEGRATION_GUIDE.md) | Complete integration reference |
| [ExampleApp.swift](ExampleApp.swift) | Full working example app |
| [WesWorldReporter.swift](WesWorldReporter.swift) | Reporter implementation |

---

## 🔑 API Configuration for ww-fx-dropout

### API Key Details

- **Key**: `ww-fx-dropout-prod-2026-01-01`
- **Product**: `ww-fx-dropout`
- **Rate Limit**: 100 logs/hour

### Server Endpoints

| Environment | URL |
|-------------|-----|
| Local Development | `http://localhost:8787/api/logs` |
| Production | `https://ww-logs.your-domain.workers.dev/api/logs` |

### Configuration Methods

#### Option 1: Environment Variables (Recommended)

```bash
export WW_LOGS_URL="https://ww-logs.your-domain.workers.dev/api/logs"
export WW_LOGS_API_KEY="ww-fx-dropout-prod-2026-01-01"
```

#### Option 2: Configuration File

Create `logging-config.json` in your app bundle:

```json
{
  "serverURL": "https://ww-logs.your-domain.workers.dev/api/logs",
  "apiKey": "ww-fx-dropout-prod-2026-01-01",
  "productName": "ww-fx-dropout"
}
```

Add to `.gitignore`:
```
logging-config.json
*.swiftpm/
```

---

## 💻 Usage Examples

### Automatic Crash Reporting

```swift
// Crashes are caught automatically
NSSetUncaughtExceptionHandler { exception in
    // WesWorldReporter handles this automatically
}
```

### Manual Error Logging

```swift
do {
    try operation()
} catch {
    Task {
        await WesWorldReporter.shared.logError(
            "Operation failed",
            error,
            additionalInfo: ["operationType": "dataSync"]
        )
    }
}
```

### Info & Warning Logs

```swift
// Log informational messages
Task {
    await WesWorldReporter.shared.logInfo("User logged in")
}

// Log warnings
Task {
    await WesWorldReporter.shared.logWarning("Memory usage high")
}
```

### Batch Operations

```swift
// Automatically batches logs and submits when queue reaches 50
Task {
    await WesWorldReporter.shared.logInfo("Processing item 1")
    await WesWorldReporter.shared.logInfo("Processing item 2")
    await WesWorldReporter.shared.logInfo("Processing item 3")
    
    // When done, flush to server
    await WesWorldReporter.shared.flushPendingLogs()
}
```

---

## 🧪 Testing

### Test with Local Server

1. **Start the server**:
   ```bash
   make dev
   ```

2. **Run test client**:
   ```bash
   make client-example
   ```

3. **View dashboard**:
   Visit `http://localhost:8787` and log in with password `WesWorld2026`

### Manual Testing with cURL

```bash
curl -X POST http://localhost:8787/api/logs \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ww-fx-dropout-prod-2026-01-01" \
  -d '{
    "product": "ww-fx-dropout",
    "version": "1.0.0",
    "platform": "macOS",
    "deviceId": "test-device",
    "deviceInfo": {
      "model": "MacBookPro",
      "os": "macOS 14.0",
      "memory": "16GB",
      "processor": "Apple M2"
    },
    "logs": "Test crash log",
    "metadata": {
      "crashTime": "2026-02-06T10:00:00Z"
    }
  }'
```

---

## 🚀 Deployment

### Step 1: Deploy WesWorld Server

```bash
cd ww-logs-1
make deploy
```

This deploys to Cloudflare Workers. You'll get a URL like:
```
https://ww-logs-xxxxx.workers.dev
```

### Step 2: Update App Configuration

Update your app's server URL:

```swift
let reporter = WesWorldReporter(
    serverURL: "https://ww-logs-xxxxx.workers.dev/api/logs",
    apiKey: "ww-fx-dropout-prod-2026-01-01"
)
```

### Step 3: Distribute Securely

Never commit API keys to source control:

- ✅ Use environment variables
- ✅ Use config files in `.gitignore`
- ✅ Use Xcode build settings
- ❌ Don't hardcode in Swift files

### Step 4: Monitor Production

Access your production dashboard:

```
https://ww-logs-xxxxx.workers.dev
Password: WesWorld2026
```

Filter by product `ww-fx-dropout` to see all app logs.

---

## 📊 Dashboard Features

### View Logs

- Filter by product, date, device
- Search by error message
- View full stack traces
- See device information

### Analysis

- Copy logs for AI analysis
- View error trends
- Track crash frequency
- Monitor error types

### Export

- Download raw log data
- Share specific crash reports
- Archive historical logs

---

## 🔍 Troubleshooting

### Logs Not Appearing?

1. **Verify server is running**:
   ```bash
   curl http://localhost:8787/api/logs -X OPTIONS
   ```

2. **Check API key**:
   - Verify key is correct: `ww-fx-dropout-prod-2026-01-01`
   - Confirm header is set: `X-API-Key`

3. **Check network**:
   - Ensure server URL is reachable
   - Verify internet connection

4. **Check logs locally**:
   - Failed submissions are cached in:
   - `~/Library/Application Support/ww-fx-dropout/logs/`

### Getting 401 Unauthorized?

- API key is invalid or missing
- Check the `X-API-Key` header is present
- Verify product name matches configuration

### Crashes Not Being Reported?

- `setupCrashHandlers()` must be called early in `applicationDidFinishLaunching`
- Verify crash handler is not being overridden elsewhere
- Check that exceptions are actually being thrown (not handled)

### High Memory Usage?

- Reduce `maxQueueSize` in `LogQueue` initialization
- Flush pending logs more frequently
- Monitor file size of offline cache

---

## 📋 Implementation Checklist

### Initial Setup
- [ ] Copy `WesWorldReporter.swift` to project
- [ ] Create configuration (env vars or config file)
- [ ] Add call to `setupCrashHandlers()` in AppDelegate

### Testing
- [ ] Start local server (`make dev`)
- [ ] Run test client (`make client-example`)
- [ ] Verify logs appear in dashboard
- [ ] Test error logging
- [ ] Test offline caching (disconnect network)

### Integration
- [ ] Wrap error-prone code with `logError()`
- [ ] Add info logs at key points
- [ ] Test app in offline mode
- [ ] Call `flushPendingLogs()` at app termination

### Deployment
- [ ] Deploy WesWorld server (`make deploy`)
- [ ] Update server URL in app
- [ ] Secure API key (not in source code)
- [ ] Test on production
- [ ] Monitor dashboard for errors

---

## 📞 Support

### Files Included

```
examples/macos-client/
├── WesWorldReporter.swift          ← Main reporter class
├── ExampleApp.swift                ← Complete example app
├── WW_FX_DROPOUT_QUICKSTART.md    ← 5-minute guide
└── WW_FX_DROPOUT_COMPLETE.md      ← This file

docs/
├── MACOS_INTEGRATION_GUIDE.md      ← Detailed reference
├── api.md                          ← API documentation
└── architecture.md                 ← System architecture
```

### Next Steps

1. Read [WW_FX_DROPOUT_QUICKSTART.md](WW_FX_DROPOUT_QUICKSTART.md)
2. Copy `WesWorldReporter.swift` to your project
3. Integrate with AppDelegate
4. Test locally with `make dev`
5. Deploy when ready

---

## 🎯 Key Features

| Feature | Status | Notes |
|---------|--------|-------|
| Automatic crash reporting | ✅ | Enabled with setupCrashHandlers() |
| Manual error logging | ✅ | Call logError() anywhere |
| Device info collection | ✅ | Auto-collected from system |
| Offline caching | ✅ | Cached in app support directory |
| Batch submission | ✅ | Queues up to 50 logs |
| API authentication | ✅ | Uses X-API-Key header |
| Web dashboard | ✅ | View at deployed URL |
| Search & filter | ✅ | In dashboard |
| Stack traces | ✅ | Full call stacks included |
| Metadata | ✅ | Custom fields supported |

---

## 📖 Documentation Links

- [Full Integration Guide](../docs/MACOS_INTEGRATION_GUIDE.md)
- [API Documentation](../docs/api.md)
- [Architecture Overview](../docs/architecture.md)
- [Main README](../README.md)

---

**Last Updated**: February 6, 2026  
**Version**: 1.0.0  
**Product**: ww-fx-dropout
