"""
Pytest configuration and fixtures for Playwright tests.
"""

import os
import pytest
from playwright.sync_api import sync_playwright, Browser, BrowserContext


@pytest.fixture(scope="session")
def browser():
    """Create a browser instance for all tests."""
    with sync_playwright() as p:
        # Launch browser in headed mode for debugging, or headless for CI
        headless = os.getenv("PLAYWRIGHT_HEADLESS", "true").lower() == "true"
        browser = p.chromium.launch(headless=headless)
        yield browser
        browser.close()


@pytest.fixture(scope="session")
def browser_context(browser: Browser):
    """Create a browser context with default settings."""
    context = browser.new_context(
        viewport={"width": 1280, "height": 720},
        # Grant camera permissions for testing
        permissions=["camera"],
    )
    yield context
    context.close()

