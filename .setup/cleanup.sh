#!/usr/bin/env bash
set -e

# Repository location
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Cleaning up repository${NC}"

# Remove cache directories
find "$REPO_DIR" -type d -path "*/cache" -exec rm -rf {} \; 2>/dev/null || true
find "$REPO_DIR" -type d -path "*/__pycache__" -exec rm -rf {} \; 2>/dev/null || true

# Remove binaries and temporary files
find "$REPO_DIR" -type f \( -name "*.o" -o -name "*.so" -o -name "*.pyc" -o -name "*.class" -o -name "*.bin" -o -name "*.log" -o -name "*.tmp" \) -delete

# Large media files
find "$REPO_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.mp4" -o -name "*.webm" -o -name "*.gif" \) -size +500k -delete

echo -e "${GREEN}Cleanup complete!${NC}"
echo -e "${BLUE}Current repository size:${NC}"
du -sh "$REPO_DIR"
