#!/bin/bash
# =============================================================================
# BIOS Checker Mock Test Script
# =============================================================================
# This script tests the configurator_bios_checker_dialog function by creating
# a mock environment with fake BIOS files and a test bios.json.
#
# Usage: bash developer_toolbox/bios_checker_test.sh
#        bash developer_toolbox/bios_checker_test.sh --debug  (verbose output)
#        bash developer_toolbox/bios_checker_test.sh --show-output  (show zenity output)
# =============================================================================


# set -euo pipefail
# Temporarily disable strict modes for debugging
set -u
set -o pipefail


# --- Command line options ---
DEBUG_MODE=false
SHOW_ZENITY_OUTPUT=false
for arg in "$@"; do
  case "$arg" in
    --debug) DEBUG_MODE=true ;;
    --show-output) SHOW_ZENITY_OUTPUT=true ;;
  esac
done

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRODECK_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Test Results Tracking ---
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
  echo ""
  echo "================================================================="
  echo -e "${YELLOW}$1${NC}"
  echo "================================================================="
}

print_test() {
  echo -e "  [TEST] $1"
}

print_debug() {
  if [[ "$DEBUG_MODE" == "true" ]]; then
    echo -e "  ${YELLOW}[DEBUG]${NC} $1"
  fi
}

print_pass() {
  echo -e "  ${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

print_fail() {
  echo -e "  ${RED}[FAIL]${NC} $1"
  ((TESTS_FAILED++))
}

# Creates a file with specific content to produce a known MD5 hash
# Usage: setup_mock_file <filepath> <content>
setup_mock_file() {
  local filepath="$1"
  local content="$2"
  mkdir -p "$(dirname "$filepath")"
  echo -n "$content" > "$filepath"
}

# Gets the MD5 of a string (for test case setup)
# Usage: get_md5 <content>
get_md5() {
  echo -n "$1" | md5sum | awk '{print $1}'
}

# Asserts that a value in the captured zenity output matches expected
# Usage: assert_zenity_contains <expected_value> <description>
assert_zenity_contains() {
  local expected="$1"
  local description="$2"
  ((TESTS_RUN++))
  if grep -q "$expected" "$MOCK_ZENITY_OUTPUT"; then
    print_pass "$description"
  else
    print_fail "$description (expected to find: '$expected')"
  fi
}

# Asserts that a BIOS entry has the expected "Found" and "Hash Matches" values
# Usage: assert_bios_result <filename> <expected_found> <expected_hash_match> <description>
assert_bios_result() {
  local filename="$1"
  local expected_found="$2"
  local expected_hash="$3"
  local description="$4"
  ((TESTS_RUN++))
  
  # The zenity output contains all arguments, one per line
  # Format from the dialog: filename, systems, found, hash_matched, required, paths, desc, md5
  # We need to find the filename and extract the values that follow it
  
  if ! grep -qxF "$filename" "$MOCK_ZENITY_OUTPUT"; then
    print_fail "$description (filename '$filename' not found in output)"
    print_debug "Searched for exact line match of: $filename"
    return
  fi
  
  # Extract values using awk - find exact filename match and get subsequent lines
  # Column order: filename(0), systems(1), found(2), hash_matched(3), required(4), paths(5), desc(6), md5(7)
  local found_value hash_value
  
  # Use awk to find the line number of the filename, then extract relative positions
  found_value=$(awk -v fn="$filename" '
    $0 == fn { target_line = NR; next }
    target_line && NR == target_line + 2 { print; exit }
  ' "$MOCK_ZENITY_OUTPUT")
  
  hash_value=$(awk -v fn="$filename" '
    $0 == fn { target_line = NR; next }
    target_line && NR == target_line + 3 { print; exit }
  ' "$MOCK_ZENITY_OUTPUT")
  
  print_debug "For '$filename': Found='$found_value', Hash='$hash_value'"
  
  if [[ "$found_value" == "$expected_found" && "$hash_value" == "$expected_hash" ]]; then
    print_pass "$description"
  else
    print_fail "$description (got Found='$found_value' Hash='$hash_value', expected Found='$expected_found' Hash='$expected_hash')"
  fi
}

# =============================================================================
# Mock Environment Setup
# =============================================================================

setup_mock_environment() {
  print_header "Setting up mock environment"
  
  # Create temporary workspace
  MOCK_WORKSPACE=$(mktemp -d)
  echo "  Mock workspace: $MOCK_WORKSPACE"
  
  # Create directory structure
  mkdir -p "$MOCK_WORKSPACE/bios"
  mkdir -p "$MOCK_WORKSPACE/bios/switch/keys"
  mkdir -p "$MOCK_WORKSPACE/roms/neogeo"
  mkdir -p "$MOCK_WORKSPACE/roms/fbneo"
  mkdir -p "$MOCK_WORKSPACE/saves"
  mkdir -p "$MOCK_WORKSPACE/logs"
  
  # Set environment variables that the BIOS checker uses
  export bios_path="$MOCK_WORKSPACE/bios"
  export roms_path="$MOCK_WORKSPACE/roms"
  export saves_path="$MOCK_WORKSPACE/saves"
  export rd_home_roms_path="$MOCK_WORKSPACE/roms"
  export rd_xdg_config_logs_path="$MOCK_WORKSPACE/logs"
  export rd_logging_level="info"
  
  # Create mock bios.json
  export bios_checklist="$MOCK_WORKSPACE/bios.json"
  
  # File to capture zenity output
  MOCK_ZENITY_OUTPUT="$MOCK_WORKSPACE/zenity_output.txt"
  
  # --- Define test content and their MD5 hashes ---
  TEST_CONTENT_A="test_content_a"
  TEST_MD5_A=$(get_md5 "$TEST_CONTENT_A")
  
  TEST_CONTENT_B="test_content_b"
  TEST_MD5_B=$(get_md5 "$TEST_CONTENT_B")
  
  TEST_CONTENT_C="test_content_c"
  TEST_MD5_C=$(get_md5 "$TEST_CONTENT_C")
  
  echo "  Test MD5 A: $TEST_MD5_A"
  echo "  Test MD5 B: $TEST_MD5_B"
  echo "  Test MD5 C: $TEST_MD5_C"
  
  # --- Create test bios.json with various scenarios ---
  cat > "$bios_checklist" << EOF
{
  "bios": [
    {
      "filename": "test_single_path_found.bin",
      "md5": "$TEST_MD5_A",
      "system": "test_system_1",
      "description": "Test: Single path, file found, hash matches"
    },
    {
      "filename": "test_single_path_missing.bin",
      "md5": "$TEST_MD5_A",
      "system": "test_system_2",
      "description": "Test: Single path, file missing"
    },
    {
      "filename": "test_single_path_wrong_hash.bin",
      "md5": "$TEST_MD5_A",
      "system": "test_system_3",
      "description": "Test: Single path, file found, hash mismatch"
    },
    {
      "filename": "test_multi_path_first.bin",
      "md5": "$TEST_MD5_B",
      "system": "test_system_4",
      "description": "Test: Multiple paths, found in first path",
      "paths": [
        "\$bios_path",
        "\$saves_path"
      ]
    },
    {
      "filename": "test_multi_path_second.bin",
      "md5": "$TEST_MD5_B",
      "system": "test_system_5",
      "description": "Test: Multiple paths, found in second path",
      "paths": [
        "\$bios_path",
        "\$saves_path"
      ]
    },
    {
      "filename": "test_multi_md5_first.bin",
      "md5": ["$TEST_MD5_A", "$TEST_MD5_B", "$TEST_MD5_C"],
      "system": "test_system_6",
      "description": "Test: Multiple MD5s, matches first"
    },
    {
      "filename": "test_multi_md5_second.bin",
      "md5": ["$TEST_MD5_A", "$TEST_MD5_B", "$TEST_MD5_C"],
      "system": "test_system_7",
      "description": "Test: Multiple MD5s, matches second"
    },
    {
      "filename": "test_multi_md5_none.bin",
      "md5": ["$TEST_MD5_A", "$TEST_MD5_B"],
      "system": "test_system_8",
      "description": "Test: Multiple MD5s, matches none"
    },
    {
      "filename": "test_envvar_expansion.bin",
      "md5": "$TEST_MD5_C",
      "system": "test_system_9",
      "description": "Test: Path uses env var expansion",
      "paths": "\$saves_path"
    },
    {
      "filename": "neogeo.zip",
      "md5": "$TEST_MD5_A",
      "system": "fbneo",
      "description": "Test: ROM path array expansion",
      "paths": [
        "\$rd_home_roms_path/neogeo",
        "\$rd_home_roms_path/fbneo"
      ]
    }
  ]
}
EOF

  # --- Create mock BIOS files ---
  
  # Test 1: Single path, found, hash matches
  setup_mock_file "$bios_path/test_single_path_found.bin" "$TEST_CONTENT_A"
  
  # Test 2: Single path, missing - don't create file
  
  # Test 3: Single path, wrong hash
  setup_mock_file "$bios_path/test_single_path_wrong_hash.bin" "wrong_content"
  
  # Test 4: Multiple paths, found in first
  setup_mock_file "$bios_path/test_multi_path_first.bin" "$TEST_CONTENT_B"
  
  # Test 5: Multiple paths, found in second (not first)
  setup_mock_file "$saves_path/test_multi_path_second.bin" "$TEST_CONTENT_B"
  
  # Test 6: Multiple MD5s, matches first
  setup_mock_file "$bios_path/test_multi_md5_first.bin" "$TEST_CONTENT_A"
  
  # Test 7: Multiple MD5s, matches second
  setup_mock_file "$bios_path/test_multi_md5_second.bin" "$TEST_CONTENT_B"
  
  # Test 8: Multiple MD5s, matches none
  setup_mock_file "$bios_path/test_multi_md5_none.bin" "completely_different"
  
  # Test 9: Env var expansion
  setup_mock_file "$saves_path/test_envvar_expansion.bin" "$TEST_CONTENT_C"
  
  # Test 10: ROM path array - put in neogeo folder
  setup_mock_file "$roms_path/neogeo/neogeo.zip" "$TEST_CONTENT_A"
  
  echo "  Mock files created successfully"
}

# =============================================================================
# Mock Functions (override real implementations)
# =============================================================================

setup_mocks() {
  print_header "Setting up mock functions"
  
  # Mock rd_zenity to capture arguments instead of showing dialog
  # We use a function definition that will override the one sourced from zenity_processing.sh
  rd_zenity() {
    # If the first argument is --progress, consume stdin so the pipe doesn't break
    if [[ "$*" == *"--progress"* ]]; then
      # Optional: log progress updates if we care about them
      # cat > /dev/null
      while read -r line; do
        echo "[PROGRESS] $line" >> "$MOCK_ZENITY_OUTPUT"
      done
    fi

    # Write all arguments to a file, one per line
    echo "---ZENITY_CALL---" >> "$MOCK_ZENITY_OUTPUT"
    for arg in "$@"; do
      echo "$arg" >> "$MOCK_ZENITY_OUTPUT"
    done
    echo "---END_ZENITY_CALL---" >> "$MOCK_ZENITY_OUTPUT"
    return 0
  }
  # Note: No export -f rd_zenity here because we want it to stay in this shell
  
  # Mock configurator_tools_dialog to prevent recursion
  configurator_tools_dialog() {
    echo "DEBUG: Mock configurator_tools_dialog called"
    return 0
  }
  
  echo "  Mocks configured"
}

# =============================================================================
# Check Dependencies
# =============================================================================

check_dependencies() {
  print_header "Checking dependencies"
  
  local missing_deps=()
  
  # Check for required commands
  for cmd in jq md5sum envsubst awk grep; do
    if command -v "$cmd" &> /dev/null; then
      echo "  ✓ $cmd found"
    else
      echo "  ✗ $cmd NOT FOUND"
      missing_deps+=("$cmd")
    fi
  done
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo -e "${RED}ERROR: Missing required commands: ${missing_deps[*]}${NC}"
    exit 1
  fi
}

# =============================================================================
# Source Required Functions
# =============================================================================

source_dependencies() {
  print_header "Sourcing dependencies"
  
  # Source the logger first to get 'log' function
  source "$RETRODECK_ROOT/functions/logger.sh"
  echo "  Sourced: logger.sh"
  
  # Source zenity processing (contains the real rd_zenity)
  source "$RETRODECK_ROOT/functions/zenity_processing.sh"
  echo "  Sourced: zenity_processing.sh"
  
  # Source dialogs (contains the function under test)
  source "$RETRODECK_ROOT/functions/dialogs.sh"
  echo "  Sourced: dialogs.sh"
}

# =============================================================================
# Run Tests
# =============================================================================

run_tests() {
  print_header "Running BIOS Checker"
  
  # Clear previous output
  > "$MOCK_ZENITY_OUTPUT"
  
  # Run the function under test
  echo "  Running configurator_bios_checker_dialog..."
  configurator_bios_checker_dialog
  echo "  Function completed."
  
  # Optionally show the captured zenity output for debugging
  if [[ "$SHOW_ZENITY_OUTPUT" == "true" ]]; then
    print_header "Captured Zenity Output"
    echo "--- BEGIN ZENITY OUTPUT ---"
    cat "$MOCK_ZENITY_OUTPUT"
    echo "--- END ZENITY OUTPUT ---"
  fi
  
  print_header "Verifying Results"
  
  # Verify test cases
  echo "  Testing single-path scenarios..."
  
  # Ensure we have output to check
  if [[ ! -s "$MOCK_ZENITY_OUTPUT" ]]; then
    echo -e "  ${RED}[ERROR]${NC} Mock zenity output is empty!"
    # Print the file content anyway just in case
    cat "$MOCK_ZENITY_OUTPUT"
  elif grep -q -e "---ZENITY_CALL---" "$MOCK_ZENITY_OUTPUT"; then
     echo "  Verified: Zenity output contains captured calls."
  else
     echo -e "  ${RED}[ERROR]${NC} Zenity output does not contain expected marker."
     cat "$MOCK_ZENITY_OUTPUT"
  fi

  assert_bios_result "test_single_path_found.bin" "Yes" "Yes" "Single path: file found with matching hash"
  assert_bios_result "test_single_path_missing.bin" "No" "No" "Single path: file missing"
  assert_bios_result "test_single_path_wrong_hash.bin" "Yes" "No" "Single path: file found with wrong hash"
  
  echo ""
  echo "  Testing multi-path scenarios..."
  assert_bios_result "test_multi_path_first.bin" "Yes" "Yes" "Multiple paths: found in first path"
  assert_bios_result "test_multi_path_second.bin" "Yes" "Yes" "Multiple paths: found in second path"
  
  echo ""
  echo "  Testing multi-MD5 scenarios..."
  assert_bios_result "test_multi_md5_first.bin" "Yes" "Yes" "Multiple MD5s: matches first hash"
  assert_bios_result "test_multi_md5_second.bin" "Yes" "Yes" "Multiple MD5s: matches second hash"
  assert_bios_result "test_multi_md5_none.bin" "Yes" "No" "Multiple MD5s: matches no hash"
  assert_bios_result "test_envvar_expansion.bin" "Yes" "Yes" "Environment variable path expansion"
  assert_bios_result "neogeo.zip" "Yes" "Yes" "ROM path array expansion"
}

# =============================================================================
# Cleanup
# =============================================================================

cleanup() {
  print_header "Cleanup"
  if [[ -n "${MOCK_WORKSPACE:-}" && -d "$MOCK_WORKSPACE" ]]; then
    echo "  Removing mock workspace: $MOCK_WORKSPACE"
    rm -rf "$MOCK_WORKSPACE"
  fi
}

# =============================================================================
# Main
# =============================================================================

main() {
  print_header "BIOS Checker Mock Test Suite"
  echo "  RetroDECK Root: $RETRODECK_ROOT"
  
  # Set up trap for cleanup on exit
  trap cleanup EXIT
  
  # Run test phases
  check_dependencies
  setup_mock_environment
  source_dependencies
  setup_mocks          # Must be AFTER sourcing dependencies to overwrite real functions
  run_tests
  
  # Print summary
  print_header "Test Summary"
  echo "  Tests Run:    $TESTS_RUN"
  echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC}"
  
  if [[ $TESTS_FAILED -eq 0 && $TESTS_RUN -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
  else
    echo ""
    echo -e "${RED}TESTS FAILED OR NONE RUN${NC}"
    exit 1
  fi
}

main "$@"
