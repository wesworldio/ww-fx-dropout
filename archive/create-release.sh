#!/bin/bash

# Script to create a new release version and trigger build

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}WesWorld FX Desktop - Release Tool${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    git status -s
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get current version from package.json
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo -e "${GREEN}Current version: ${CURRENT_VERSION}${NC}"
echo ""

# Ask for new version
echo "Enter new version (e.g., 1.0.1, 1.1.0, 2.0.0):"
read NEW_VERSION

# Validate version format
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 1.0.1)${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}You are about to:${NC}"
echo "  1. Update package.json to version ${NEW_VERSION}"
echo "  2. Commit the version change"
echo "  3. Create and push git tag v${NEW_VERSION}"
echo "  4. Trigger GitHub Actions to build and create release"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Update version in package.json
echo ""
echo -e "${BLUE}Updating package.json...${NC}"
npm version $NEW_VERSION --no-git-tag-version

# Commit version change
echo -e "${BLUE}Committing version change...${NC}"
git add package.json package-lock.json 2>/dev/null || true
git commit -m "Release v${NEW_VERSION}"

# Create and push tag
echo -e "${BLUE}Creating git tag v${NEW_VERSION}...${NC}"
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"

echo -e "${BLUE}Pushing to GitHub...${NC}"
git push origin main
git push origin "v${NEW_VERSION}"

echo ""
echo -e "${GREEN}✅ Release initiated!${NC}"
echo ""
echo "GitHub Actions will now:"
echo "  • Build for macOS (Intel + ARM64)"
echo "  • Build for Windows (x64 + x86)"
echo "  • Build for Linux (AppImage + DEB)"
echo "  • Create GitHub Release with all installers"
echo ""
echo -e "${BLUE}Check build progress at:${NC}"
echo "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\).git/\1/')/actions"
echo ""
echo -e "${BLUE}Release will be available at:${NC}"
echo "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\).git/\1/')/releases/tag/v${NEW_VERSION}"
echo ""
echo -e "${GREEN}Done!${NC}"
