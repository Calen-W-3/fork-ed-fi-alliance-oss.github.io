#!/bin/bash

# A script to scan the ENTIRE repository for forbidden terms, excluding binaries.

# Path to the policy file (Assumes it's in the root of the repo)
# Since the script runs from the root in GitHub Actions, we look for it there.
POLICY_FILE=".github/workflows/term_policy.json"

# Initialize error flag
ERROR_FOUND=false

echo "--- Running Global Terminology Scan ---"

# 1. Define excluded file types (images, fonts, binaries)
# This keeps the scan fast and prevents grep from reading binary data.
EXCLUDES="--exclude=*.png --exclude=*.jpg --exclude=*.jpeg --exclude=*.webp --exclude=*.woff --exclude=*.woff2 --exclude=*.ttf --exclude=*.eot --exclude=*.pdf --exclude=*.exe"

# 2. Loop through each term in the policy
jq -c '.[]' "$POLICY_FILE" | while read -r TERM_OBJECT; do
    EXCLUDED_TERM=$(echo "$TERM_OBJECT" | jq -r '.excluded_term')
    SUGGESTED_ALT=$(echo "$TERM_OBJECT" | jq -r '.suggested_alternative')

    echo "Scanning for: '$EXCLUDED_TERM'..."

    # Scan the whole repository (.)
    # -I: Process a binary file as if it did not contain matching data (essential!)
    # --exclude-dir=.git: Skip git history
    MATCHING_FILES=$(grep -rilF $EXCLUDES --exclude-dir=.git --exclude="$POLICY_FILE" --exclude-dir=".github" -I "$EXCLUDED_TERM" .)

    if [ ! -z "$MATCHING_FILES" ]; then
        ERROR_FOUND=true
        
        echo "::error::Forbidden Term Found: '$EXCLUDED_TERM'"
        echo "Found in the following files:"
        echo "$MATCHING_FILES" | tr '\0' '\n'
        echo "Suggested replacement: '$SUGGESTED_ALT'"
        echo "--------------------------------------------------------"
    fi
done

# Fail the build if any forbidden terms exist
if [ "$ERROR_FOUND" = true ]; then
    echo "--- BUILD FAILED: One or more forbidden terms exist in the repository. ---"
    exit 1
else
    echo "--- Global Terminology Check Passed! ---"
fi