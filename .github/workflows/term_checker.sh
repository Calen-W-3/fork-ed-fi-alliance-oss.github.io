#!/bin/bash

# A script to check for forbidden terms in changed files of a PR.

# 1. Get a list of files changed in the PR
# This uses git to find files modified, added, or renamed between the base and head of the PR
CHANGED_FILES=$(git diff --name-only --diff-filter=AMR "origin/${{ github.base_ref }}" "origin/${{ github.head_ref }}")

# Check if any files were changed
if [ -z "$CHANGED_FILES" ]; then
  echo "No files changed in this PR. Skipping term check."
  exit 0
fi

# Load the policy
POLICY_FILE="term_policy.json"

# Initialize error flag
ERROR_FOUND=false

echo "--- Running Terminology Check on Changed Files ---"

# Loop through each term object in the policy file
jq -c '.[]' "$POLICY_FILE" | while read -r TERM_OBJECT; do
    # Extract the excluded term and suggested alternative using 'jq'
    EXCLUDED_TERM=$(echo "$TERM_OBJECT" | jq -r '.excluded_term')
    SUGGESTED_ALT=$(echo "$TERM_OBJECT" | jq -r '.suggested_alternative')

    # Use 'grep' to search for the excluded term in the changed files
    # -i: Ignore case
    # -l: Only output the filenames that contain the term
    # -F: Treat the pattern as a fixed string (safer for terms with special characters)
    # --null: Use a null byte separator for file names (safer for files with spaces)
    MATCHING_FILES=$(grep -ilF --null "$EXCLUDED_TERM" $CHANGED_FILES)

    # If any matching files were found
    if [ ! -z "$MATCHING_FILES" ]; then
        ERROR_FOUND=true
        
        # Convert null-separated list back to a newline-separated list for display
        DISPLAY_FILES=$(echo "$MATCHING_FILES" | tr '\0' '\n')

        # --- GitHub Actions Error Formatting ---
        # The '::error::' syntax generates a permanent failure that stops the workflow.
        echo "::error::Forbidden Term Found: '$EXCLUDED_TERM'"
        echo "Found the forbidden term in the following file(s):"
        echo "$DISPLAY_FILES"
        echo "Please replace all instances of '$EXCLUDED_TERM' with the suggested term: '$SUGGESTED_ALT'"
        echo "--------------------------------------------------------"
    fi
done

# Final check to fail the build if any error was found
if $ERROR_FOUND; then
    echo "--- BUILD FAILED: Terminology check failed. Please review the errors above. ---"
    exit 1
else
    echo "--- Terminology Check Passed! ---"
fi