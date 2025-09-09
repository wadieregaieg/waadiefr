#!/bin/bash

# iOS Production Build Script for Freshk
# This script builds the iOS app for production release

set -e

echo "🚀 Starting iOS Production Build for Freshk..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the Flutter project root directory"
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Build for iOS in release mode
print_status "Building iOS app in release mode..."
flutter build ios --release --no-codesign

print_status "✅ iOS build completed successfully!"

# Instructions for next steps
echo ""
print_status "Next steps for App Store submission:"
echo "1. Open the project in Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Configure signing and capabilities:"
echo "   - Select your team in Signing & Capabilities"
echo "   - Ensure Bundle Identifier is unique"
echo "   - Configure App Groups if needed"
echo ""
echo "3. Archive and upload:"
echo "   - Product > Archive"
echo "   - Distribute App"
echo "   - App Store Connect"
echo ""
echo "4. Test on real devices before submission"
echo ""

print_status "Build artifacts are in: ios/build/ios/iphoneos/" 