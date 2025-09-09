# GitHub Actions for iOS Builds

This directory contains GitHub Actions workflows for building and testing the Freshk iOS app.

## Available Workflows

### 1. `ios-build.yml` - Basic iOS Build
- Builds iOS app in debug and release modes
- Runs tests and code analysis
- Uploads build artifacts
- No code signing (for development/testing)

### 2. `ios-build-with-signing.yml` - Production Build with Code Signing
- Full production build with code signing
- Creates GitHub releases
- Requires Apple Developer certificates and provisioning profiles
- Only runs on main branch for security

## Setup Instructions

### Basic Setup (No Code Signing)

1. **Enable GitHub Actions**
   - Go to your repository settings
   - Navigate to "Actions" > "General"
   - Enable "Allow all actions and reusable workflows"

2. **Push the workflows**
   ```bash
   git add .github/workflows/
   git commit -m "Add iOS build workflows"
   git push
   ```

3. **Monitor builds**
   - Go to "Actions" tab in your repository
   - Workflows will run automatically on push/PR

### Advanced Setup (With Code Signing)

To enable code signing for production builds, you need to add secrets to your repository:

1. **Generate Apple Developer Certificate**
   ```bash
   # Export your certificate from Keychain Access
   security export -k login.keychain -t identities -p "your-password" "Apple Development: Your Name (TEAM_ID)" -o certificate.p12
   ```

2. **Convert to Base64**
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```

3. **Export Provisioning Profile**
   - Download from Apple Developer Console
   - Convert to Base64: `base64 -i profile.mobileprovision | pbcopy`

4. **Add Repository Secrets**
   Go to your repository settings > Secrets and variables > Actions, and add:

   | Secret Name | Description | Example |
   |-------------|-------------|---------|
   | `BUILD_CERTIFICATE_BASE64` | Your certificate in Base64 | `MIIF...` |
   | `P12_PASSWORD` | Certificate password | `your-password` |
   | `BUILD_PROVISION_PROFILE_BASE64` | Provisioning profile in Base64 | `MIIF...` |
   | `KEYCHAIN_PASSWORD` | Temporary keychain password | `build-keychain-pass` |
   | `TEAM_ID` | Your Apple Developer Team ID | `ABC123DEF` |
   | `BUNDLE_ID` | Your app's bundle identifier | `com.freshk.app` |

## Usage

### Manual Trigger
1. Go to "Actions" tab
2. Select "iOS Build with Code Signing"
3. Click "Run workflow"
4. Choose build type (debug/release)
5. Click "Run workflow"

### Automatic Triggers
- **Push to main/develop**: Triggers build and tests
- **Pull Request**: Triggers build and tests
- **Manual**: Can be triggered manually with build type selection

## Build Artifacts

### Debug Build
- Location: `mobile/build/ios/`
- Retention: 7 days
- No code signing

### Release Build
- Location: `mobile/build/ios/`
- Retention: 30 days
- No code signing (basic workflow)

### Signed Release Build
- Location: `mobile/build/ios/`
- Retention: 30 days
- Code signed and ready for App Store
- Creates GitHub release

## Troubleshooting

### Common Issues

1. **Flutter version mismatch**
   - Update `flutter-version` in workflow files
   - Check your local Flutter version: `flutter --version`

2. **Pod install fails**
   - Check iOS dependencies in `ios/Podfile`
   - Ensure Ruby version is compatible

3. **Code signing fails**
   - Verify certificate and provisioning profile are valid
   - Check Team ID and Bundle ID match
   - Ensure secrets are properly encoded in Base64

4. **Build fails**
   - Check Flutter dependencies: `flutter pub get`
   - Verify iOS dependencies: `cd ios && pod install`
   - Run locally first: `flutter build ios --release`

### Debug Steps

1. **Check workflow logs**
   - Go to Actions tab
   - Click on failed workflow
   - Review step-by-step logs

2. **Test locally**
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   cd ios && pod install
   flutter build ios --release --no-codesign
   ```

3. **Verify secrets**
   - Check all required secrets are set
   - Verify Base64 encoding is correct
   - Test certificate validity locally

## Security Notes

- **Never commit certificates or provisioning profiles** to the repository
- **Use repository secrets** for sensitive data
- **Limit access** to repository settings
- **Regularly rotate** certificates and passwords
- **Monitor workflow access** and permissions

## Cost Considerations

- GitHub Actions on macOS runners costs money
- Consider using self-hosted runners for cost savings
- Monitor usage in repository settings

## Next Steps

1. **Set up code signing** for production builds
2. **Configure App Store Connect** for automated uploads
3. **Add integration tests** for comprehensive testing
4. **Set up notifications** for build status
5. **Configure branch protection** rules

---

For more information, see:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/ci)
- [Apple Developer Documentation](https://developer.apple.com/documentation/) 