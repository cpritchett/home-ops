#!/bin/bash

echo "🔧 RENOVATE PERMISSION DIAGNOSTICS & FIX TOOL"
echo "============================================="
echo
echo "This script helps diagnose and fix common Renovate permission issues:"
echo "• Cannot access vulnerability alerts"
echo "• Package lookup failures"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    echo
}

# Check repository security settings
check_repository_security() {
    log_info "Checking repository security settings..."
    
    # This requires the GitHub API to check security settings
    # We'll provide instructions for manual verification
    echo
    log_warning "Please manually verify these repository settings:"
    echo "1. Go to: https://github.com/cpritchett/home-ops/settings/security_analysis"
    echo "2. Ensure the following are ENABLED:"
    echo "   ✓ Dependency graph"
    echo "   ✓ Dependabot alerts"
    echo "   ✓ Dependabot security updates (recommended)"
    echo
    read -p "Have you verified these settings are enabled? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Please enable the required security settings before continuing."
        exit 1
    fi
    log_success "Repository security settings verified"
    echo
}

# Check GitHub App permissions
check_github_app_permissions() {
    log_info "Checking GitHub App permissions..."
    echo
    log_warning "Please manually verify these GitHub App permissions:"
    echo "1. Go to your GitHub App settings (where you created the Renovate app)"
    echo "2. Edit the app permissions to ensure these are set to 'Read':"
    echo "   ✓ Vulnerability alerts: Read"
    echo "   ✓ Repository security events: Read"  
    echo "   ✓ Packages: Read"
    echo "   ✓ Contents: Read"
    echo "   ✓ Metadata: Read"
    echo "   ✓ Pull requests: Write"
    echo "3. Save the permissions"
    echo "4. Re-install or update the app installation on this repository"
    echo
    read -p "Have you verified and updated these permissions? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Please update the GitHub App permissions before continuing."
        exit 1
    fi
    log_success "GitHub App permissions verified"
    echo
}

# Check repository secrets
check_repository_secrets() {
    log_info "Checking repository secrets..."
    
    # Get list of repository secrets
    secrets=$(gh secret list --repo cpritchett/home-ops 2>/dev/null || echo "")
    
    if echo "$secrets" | grep -q "BOT_APP_ID"; then
        log_success "BOT_APP_ID secret exists"
    else
        log_error "BOT_APP_ID secret is missing"
        echo "Please run: ./scripts/setup-github-bot.sh"
        return 1
    fi
    
    if echo "$secrets" | grep -q "BOT_APP_PRIVATE_KEY"; then
        log_success "BOT_APP_PRIVATE_KEY secret exists"
    else
        log_error "BOT_APP_PRIVATE_KEY secret is missing"
        echo "Please run: ./scripts/setup-github-bot.sh"
        return 1
    fi
    
    log_success "Repository secrets are configured"
    echo
}

# Check Renovate configuration
check_renovate_config() {
    log_info "Checking Renovate configuration..."
    
    if [[ -f .renovaterc.json5 ]]; then
        log_success "Found .renovaterc.json5 configuration file"
        
        # Check if vulnerabilityAlerts is configured
        if grep -q "vulnerabilityAlerts" .renovaterc.json5; then
            log_success "Vulnerability alerts configuration found"
        else
            log_warning "Vulnerability alerts not explicitly configured"
            echo "Consider adding this to your .renovaterc.json5:"
            echo '  "vulnerabilityAlerts": {'
            echo '    "enabled": true'
            echo '  },'
        fi
    else
        log_error "No .renovaterc.json5 configuration file found"
        return 1
    fi
    echo
}

# Test Renovate workflow
test_renovate_workflow() {
    log_info "Testing Renovate workflow..."
    echo
    log_warning "To test the Renovate workflow manually:"
    echo "1. Go to: https://github.com/cpritchett/home-ops/actions/workflows/renovate.yaml"
    echo "2. Click 'Run workflow'"
    echo "3. Set 'Log Level' to 'debug' for detailed output"
    echo "4. Monitor the logs for any remaining permission errors"
    echo
    read -p "Would you like to trigger a manual Renovate run now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Triggering Renovate workflow..."
        gh workflow run renovate.yaml --repo cpritchett/home-ops --field logLevel=debug
        log_success "Workflow triggered. Check the Actions tab for results."
    fi
    echo
}

# Main execution
main() {
    check_prerequisites
    check_repository_security
    check_github_app_permissions
    
    if check_repository_secrets && check_renovate_config; then
        test_renovate_workflow
        echo
        log_success "Diagnostic complete! Monitor the next Renovate run for resolved issues."
        echo
        echo "📋 Summary of actions taken:"
        echo "• Verified repository security settings"
        echo "• Confirmed GitHub App permissions"
        echo "• Validated repository secrets configuration"
        echo "• Checked Renovate configuration"
        echo
        echo "🔍 If issues persist, check:"
        echo "• Review the workflow logs for specific error messages"
        echo "• Verify the GitHub App installation is active on this repository"
        echo "• Ensure the private key in 1Password matches the GitHub App"
        echo
        echo "📖 For detailed troubleshooting, see: docs/RENOVATE-TROUBLESHOOTING.md"
    else
        log_error "Configuration issues detected. Please resolve them and run this script again."
        exit 1
    fi
}

# Run main function
main