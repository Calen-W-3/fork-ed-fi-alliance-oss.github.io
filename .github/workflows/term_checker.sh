#!/bin/bash

# Path to the policy file (Assumes root of repo)
POLICY_FILE=".github/workflows/term_policy.json"
ERROR_FOUND=false

echo "--- Running Global Terminology Scan ---"

# Define excluded file types
EXCLUDES="--exclude=*.png --exclude=*.jpg --exclude=*.jpeg --exclude=*.webp --exclude=*.woff --exclude=*.woff2 --exclude=*.ttf --exclude=*.eot --exclude=*.pdf --exclude=*.exe"

# FIX: Use a Process Substitution '< <()' instead of a Pipe '|'
# This ensures variables like ERROR_FOUND are updated in the main shell.
while read -r TERM_OBJECT; do
    # -r ensures raw output (removes quotes), preventing 'null' or '"quoted"' issues
    EXCLUDED_TERM=$(echo "$TERM_OBJECT" | jq -r '.excluded_term')
    SUGGESTED_ALT=$(echo "$TERM_OBJECT" | jq -r '.suggested_alternative')

    # Skip if the term is null or empty
    if [ "$EXCLUDED_TERM" == "null" ] || [ -z "$EXCLUDED_TERM" ]; then continue; fi

    echo "Scanning for: '$EXCLUDED_TERM'..."

    # Scan the whole repository
    MATCHING_FILES=$(grep -rilF $EXCLUDES --exclude-dir=.git --exclude="$POLICY_FILE" --exclude-dir=".github" -I "$EXCLUDED_TERM" .)

    if [ -not -z "$MATCHING_FILES" ]; then
        # IMPORTANT: This now persists outside the loop
        ERROR_FOUND=true
        
        echo "::error::Forbidden Term Found: '$EXCLUDED_TERM'"
        echo "Found in: $MATCHING_FILES"
        echo "Suggested replacement: '$SUGGESTED_ALT'"
        echo "--------------------------------------------------------"
    fi

done < <(jq -c '.[]' "$POLICY_FILE")

# Final check to fail the build
if [ "$ERROR_FOUND" = true ]; then
    echo "--- BUILD FAILED: One or more forbidden terms exist in the repository. ---"
    exit 1
else
    echo "--- Global Terminology Check Passed! ---"
    exit 0
fi