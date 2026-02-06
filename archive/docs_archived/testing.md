# Testing Documentation

This document describes the testing setup and procedures for WesWorld FX.

## Overview

WesWorld FX includes end-to-end (E2E) tests using Playwright to validate the web-based interface functionality. These tests ensure that:

- The web server starts correctly
- The web interface loads and displays properly
- Camera selection works
- Filter selection and application works
- WebSocket communication functions correctly
- API endpoints return expected data

## Test Dependencies

The tests require additional dependencies beyond the main application:

- `pytest` - Test framework
- `pytest-playwright` - Playwright integration for pytest
- `playwright` - Browser automation library

## Installation

### Install Test Dependencies

**macOS/Linux:**
```bash
make test-install
```

**Windows:**
```bash
pip install -r requirements-test.txt
python -m playwright install chromium
```

Or manually:
```bash
pip install -r requirements-test.txt
playwright install chromium
```

## Running Tests

### Run All E2E Tests

**macOS/Linux:**
```bash
make test-e2e
```

**Windows:**
```bash
pytest tests/test_web_e2e.py -v
```

### Validate Filter Processing

To validate that filters are working correctly with the web application:

**macOS/Linux:**
```bash
# Terminal 1: Start the web server
make web

# Terminal 2: Run validation
make validate-filters
```

**Windows:**
```bash
# Terminal 1: Start server
python web_server.py

# Terminal 2: Validate
python scripts/validate_filters.py
```

The validation script will:
- Test the `/api/filters` endpoint
- Verify filters can be applied to test frames
- Test filters from different categories (distortion, color, effects, etc.)
- Report which filters pass or fail

### Run Tests in Headed Mode (Visible Browser)

For debugging, you can run tests with a visible browser:

**macOS/Linux:**
```bash
make test-e2e-headed
```

**Windows:**
```bash
set PLAYWRIGHT_HEADLESS=false && pytest tests/test_web_e2e.py -v -s
```

### Run Specific Tests

Run a specific test file:
```bash
pytest tests/test_web_e2e.py::test_server_starts_and_serves_page -v
```

Run tests matching a pattern:
```bash
pytest tests/test_web_e2e.py -k "filter" -v
```

## Test Structure

### Test Files

- `tests/test_web_e2e.py` - Main E2E test suite
- `tests/conftest.py` - Pytest configuration and fixtures

### Test Categories

The test suite includes:

1. **Server Tests**
   - Server startup and shutdown
   - Page serving
   - Static file delivery

2. **UI Tests**
   - Page structure and elements
   - Control visibility and toggling
   - Responsive layout

3. **API Tests**
   - `/api/filters` endpoint
   - Filter list retrieval
   - Data format validation

4. **WebSocket Tests**
   - Connection establishment
   - Message handling
   - Connection status

5. **Functionality Tests**
   - Camera selection
   - Filter selection
   - Button interactions

## Test Fixtures

### `web_server` Fixture

Automatically starts the web server before tests and stops it after all tests complete. The server runs on `http://localhost:9000`.

### `browser` Fixture

Creates a Chromium browser instance for all tests. Runs in headless mode by default, but can be configured via `PLAYWRIGHT_HEADLESS` environment variable.

### `page` Fixture

Creates a new browser page for each test, ensuring test isolation.

## Writing New Tests

### Example Test

```python
def test_my_feature(page: Page):
    """Test description."""
    page.goto("http://localhost:9000")
    
    # Interact with page
    page.click("#myButton")
    
    # Assert expected behavior
    expect(page.locator("#result")).to_contain_text("Expected")
```

### Best Practices

1. **Use descriptive test names**: Test names should clearly describe what they test
2. **Keep tests isolated**: Each test should be independent
3. **Use fixtures**: Leverage pytest fixtures for setup/teardown
4. **Wait for elements**: Use Playwright's auto-waiting features
5. **Clean assertions**: Use `expect()` for readable assertions

## Continuous Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-test.txt
          playwright install chromium
      - name: Run tests
        run: pytest tests/test_web_e2e.py -v
```

## Troubleshooting

### Tests Fail to Start Server

- Ensure port 9000 is not already in use
- Check that `web_server.py` is in the project root
- Verify Python dependencies are installed

### Browser Not Found

- Run `playwright install chromium` to install browsers
- Check that Playwright is properly installed: `python -m playwright --version`

### Tests Timeout

- Increase timeout in test fixtures if needed
- Check that server starts within expected time
- Verify network connectivity

### Headless Mode Issues

- Run tests in headed mode to see what's happening: `PLAYWRIGHT_HEADLESS=false pytest ...`
- Check browser console for errors
- Verify page elements are loading correctly

## Test Coverage

Current test coverage includes:

- ✅ Server startup and serving
- ✅ Page structure and UI elements
- ✅ Control visibility toggling
- ✅ Camera list loading
- ✅ Filter list loading and selection
- ✅ API endpoint functionality
- ✅ WebSocket connection
- ✅ Responsive layout

Future improvements:

- Camera activation and frame capture
- Real-time filter application
- Multiple concurrent connections
- Error handling and edge cases
- Performance testing

## Additional Resources

- [Playwright Documentation](https://playwright.dev/python/)
- [Pytest Documentation](https://docs.pytest.org/)
- [FastAPI Testing Guide](https://fastapi.tiangolo.com/tutorial/testing/)

