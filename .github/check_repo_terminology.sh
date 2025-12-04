#!/bin/bash

# Configuration file path
TERMINOLOGY_FILE=".github/terminology_list.txt"
found_violations=0

echo "🔍 Running comprehensive terminology check on entire repository..."

# Check if the terminology file exists
if [ ! -f "$TERMINOLOGY_FILE" ]; then
  echo "::error file=$TERMINOLOGY_FILE::Terminology list file not found. Aborting check."
  exit 1
fi

# Read the terminology file line-by-line
mapfile -t TERMINOLOGY_LIST < "$TERMINOLOGY_FILE"

# Iterate over each line (term pair) from the file
for TERM_PAIR in "${TERMINOLOGY_LIST[@]}"; do
    # Use '|' as the delimiter for reading the pair
    IFS='|' read -r FORBIDDEN_TERM SUGGESTED_REPLACEMENT <<< "$TERM_PAIR"

    # Skip empty lines or comments starting with '#'
    if [[ -z "$FORBIDDEN_TERM" || "$FORBIDDEN_TERM" =~ ^# ]]; then
        continue
    fi

    echo "---"
    echo "Checking for: '$FORBIDDEN_TERM'..."

    # Use grep to search all non-binary files for the forbidden term
    # -i: case-insensitive
    # -r: recursive search
    # -l: print only the file names that contain the match
    # -H: print the filename for each match
    # -n: print the line number
    # -w: match the whole word (optional, remove if partial matches are needed)
    VIOLATIONS=$(grep -i -r -n -H -F -e "$FORBIDDEN_TERM" --exclude-dir={.git,.github/workflows,node_modules} --exclude=\*.{png,jpg,gif,svg} .)

    if [ -n "$VIOLATIONS" ]; then
        found_violations=1
        echo "🚨 **Repository Violation Found: '$FORBIDDEN_TERM'**"
        echo "💡 **Suggestion:** Please replace with: '$SUGGESTED_REPLACEMENT'"
        echo ""
        echo "Context of Violations (File:Line:Match):"
        echo "$VIOLATIONS"
    else
        echo "✅ Term '$FORBIDDEN_TERM' not found."
    fi
done

echo "---"
if [ "$found_violations" -eq 1 ]; then
    # Issue a failure to make the check visible and block PRs until corrected
    echo "::error title=Terminology Compliance Failure::One or more forbidden terms were found in the repository. Please review the output above and correct the files."
    exit 1 
else
    echo "✅ Comprehensive Terminology Check Passed. No violations found."
fi