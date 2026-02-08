#!/usr/bin/env bash
# assign-reviewer.sh — Round-robin reviewer assignment
# Usage: assign-reviewer.sh <PATH_TO_CONFIG>
#
# Reads the reviewer pool from juan-workflow-learned.local.json,
# picks the next reviewer via round-robin, updates the index, and
# prints the chosen GitHub login to stdout.
#
# Requires: jq

set -o pipefail

CONFIG_PATH="${1:?Usage: assign-reviewer.sh <PATH_TO_CONFIG>}"

# Verify jq is available
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found. Install with: brew install jq"
  exit 1
fi

# Verify config exists
if [ ! -f "$CONFIG_PATH" ]; then
  echo "ERROR: Config not found at ${CONFIG_PATH}"
  exit 1
fi

# Read the reviewer pool and last index
POOL_SIZE=$(jq -r '.reviewers.pool | length' "$CONFIG_PATH" 2>/dev/null)
LAST_INDEX=$(jq -r '.reviewers.lastAssignedIndex' "$CONFIG_PATH" 2>/dev/null)

if [ -z "$POOL_SIZE" ] || [ "$POOL_SIZE" -eq 0 ]; then
  echo "ERROR: No reviewers in pool. Run pattern-learner to populate."
  exit 1
fi

if [ -z "$LAST_INDEX" ] || [ "$LAST_INDEX" = "null" ]; then
  LAST_INDEX=-1
fi

# Calculate next index (round-robin)
NEXT_INDEX=$(( (LAST_INDEX + 1) % POOL_SIZE ))

# Get the reviewer at that index
REVIEWER=$(jq -r ".reviewers.pool[${NEXT_INDEX}]" "$CONFIG_PATH" 2>/dev/null)

if [ -z "$REVIEWER" ] || [ "$REVIEWER" = "null" ]; then
  echo "ERROR: Could not read reviewer at index ${NEXT_INDEX}"
  exit 1
fi

# Update the config with the new index
TEMP_FILE=$(mktemp)
jq ".reviewers.lastAssignedIndex = ${NEXT_INDEX}" "$CONFIG_PATH" > "$TEMP_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
  mv "$TEMP_FILE" "$CONFIG_PATH"
else
  rm -f "$TEMP_FILE"
  echo "ERROR: Failed to update config. Reviewer is ${REVIEWER} but index was not saved."
  # Still output the reviewer — the assignment should work even if persistence fails
fi

# Output the chosen reviewer
echo "$REVIEWER"
exit 0
