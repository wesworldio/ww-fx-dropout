# Daemon Mode & Logging System

## Daemon Mode

Run the interactive filters in daemon mode with automatic reload on file changes.

### Quick Start

```bash
# Start daemon
make interactive-daemon

# Check status
make interactive-daemon-status

# View logs
make interactive-daemon-logs

# View JSON logs
make interactive-daemon-logs-json

# Stop daemon
make interactive-daemon-stop

# Restart daemon
make interactive-daemon-restart
```

### Features

- **Auto-reload**: Automatically reloads when Python files or config files change
- **Background process**: Runs in the background, doesn't block terminal
- **File watching**: Uses watchdog to monitor file changes
- **Process management**: Handles process lifecycle and restarts
- **JSON logging**: All events logged to JSON files in `logs/` directory

### How It Works

1. Daemon starts the interactive filters process
2. File watcher monitors `.py` and `.json` files
3. On file change, process is gracefully stopped and restarted
4. All events are logged to JSON files

### Configuration

Daemon settings can be adjusted in `daemon_interactive.py`:
- `reload_cooldown`: Minimum time between reloads (default: 2 seconds)
- `watch_patterns`: File patterns to watch
- `ignore_patterns`: Files/directories to ignore

## JSON Logging System

All components log to JSON files in the `logs/` directory.

### Log Files

- `logs/interactive.jsonl` - Interactive filter viewer logs
- `logs/daemon.jsonl` - Daemon process logs
- `logs/update_checker.jsonl` - Update checker logs

### Log Format

Each log entry is a JSON object on a single line (JSONL format):

```json
{
  "timestamp": "2025-01-27T12:34:56.789012",
  "session_id": "20250127_123456",
  "component": "interactive",
  "level": "INFO",
  "message": "Camera initialized successfully",
  "camera_index": 1,
  "resolution": "1280x720"
}
```

### Log Levels

- `DEBUG`: Detailed debugging information
- `INFO`: General informational messages
- `WARNING`: Warning messages
- `ERROR`: Error messages
- `EVENT`: Structured events (e.g., filter changes, recordings)
- `PERFORMANCE`: Performance metrics

### Viewing Logs

```bash
# View all JSON logs
make interactive-daemon-logs-json

# View specific log file
tail -f logs/interactive.jsonl | python3 -m json.tool

# Search logs
grep "recording" logs/*.jsonl | python3 -m json.tool

# Count events
grep "event_type" logs/interactive.jsonl | wc -l
```

### Log Events

Common events logged:

- `viewer_start` - Viewer initialization
- `viewer_stopped` - Viewer shutdown
- `camera_initialized` - Camera setup
- `filter_changed` - Filter selection change
- `favorite_added` - Filter added to favorites
- `favorite_removed` - Filter removed from favorites
- `recording_started` - Recording began
- `recording_stopped` - Recording ended
- `update_available` - Update detected
- `update_pulled` - Update downloaded
- `daemon_start` - Daemon started
- `daemon_stopped` - Daemon stopped
- `process_reload` - Process reloaded

### Performance Logging

Performance metrics are automatically logged:
- Filter application duration
- Frame processing time
- Update check duration

## Troubleshooting

### Daemon won't start

1. Check if already running: `make interactive-daemon-status`
2. Check PID file: `/tmp/ww_fx_interactive.pid`
3. Check logs: `make interactive-daemon-logs`

### Auto-reload not working

1. Install watchdog: `pip install watchdog`
2. Check file permissions
3. Verify files aren't in ignore list

### Logs not appearing

1. Check `logs/` directory exists
2. Verify write permissions
3. Check disk space

### Process keeps restarting

1. Check logs for errors
2. Verify camera is available
3. Check for syntax errors in code

## Advanced Usage

### Custom Log Directory

```python
from logger import get_logger
logger = get_logger("my_component", "custom_logs")
```

### Manual Daemon Control

```bash
# Start with custom settings
python3 daemon_interactive.py start --width 1920 --height 1080 --fps 60

# Run in foreground (for debugging)
python3 daemon_interactive.py run

# Check status programmatically
python3 daemon_interactive.py status
```

### Log Analysis

```python
import json

# Read and parse logs
with open('logs/interactive.jsonl') as f:
    for line in f:
        log = json.loads(line)
        if log['level'] == 'ERROR':
            print(log)
```

