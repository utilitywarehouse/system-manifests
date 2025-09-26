#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Iterates through all backed up topics, looking at the message at the current offset of the backup consumer.
# It outputs the message together with the headers and stops if it contains the given search value.
# Processes the output of consumer group describe in reverse order, to catch latest topic subscription first.
# Usage: /search-msk-backup-topic-with-header-at-tip.sh HEADER_NAME

# Check if the search value is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <search_value>"
  exit 1
fi

SEARCH_VALUE="$1"
BACKUP_GROUP_NAME="pubsub.msk-backup-kafka-connect"

echo "SEED_BROKERS=${SEED_BROKERS}"
echo "KAFKA_CMD_CONFIG=${KAFKA_CMD_CONFIG}"

# Get consumer group information and save to a temporary file
TMP_FILE=$(mktemp)
echo "Getting consumer group info for ${BACKUP_GROUP_NAME}"
kafka-consumer-groups.sh --bootstrap-server ${SEED_BROKERS} --command-config ${KAFKA_CMD_CONFIG} --describe --group ${BACKUP_GROUP_NAME} | tac > "$TMP_FILE"

# Count the total number of valid entries to process
TOTAL_ENTRIES=$(grep -v "GROUP\|TOPIC\|PARTITION\|CURRENT-OFFSET" "$TMP_FILE" | grep -v "^[[:space:]]*$" | wc -l)
echo "Consumer group info file size: $(wc -l < "$TMP_FILE") lines"
echo "Total entries to process: $TOTAL_ENTRIES"
echo "First few lines of consumer group info (reversed):"
head -5 "$TMP_FILE"

# Process entries - Skip header and empty lines
TOTAL_PROCESSED=0

cat "$TMP_FILE" | while read -r line; do
  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  # Skip header lines (typically contain column names)
  if echo "$line" | grep -q "GROUP\|TOPIC\|PARTITION\|CURRENT-OFFSET"; then
    echo "Skipping header line: $line"
    continue
  fi

  # Extract topic, partition, current offset, end offset, and lag
  TOPIC=$(echo "$line" | awk '{print $2}')
  PARTITION=$(echo "$line" | awk '{print $3}')
  CURRENT_OFFSET=$(echo "$line" | awk '{print $4}')
  END_OFFSET=$(echo "$line" | awk '{print $5}')
  LAG=$(echo "$line" | awk '{print $6}')

  # Verify we extracted the values correctly
  echo "Extracted: Topic=$TOPIC, Partition=$PARTITION, Offset=$CURRENT_OFFSET, EndOffset=$END_OFFSET, Lag=$LAG"

  # Skip if any value is empty or not a number for partition/offset
  if [ -z "$TOPIC" ] || [ -z "$PARTITION" ] || [ -z "$CURRENT_OFFSET" ] || [ -z "$END_OFFSET" ] || [ -z "$LAG" ]; then
    echo "Failed to parse line properly: $line"
    continue
  fi

  # Check if numeric values are actually numbers
  if ! echo "$CURRENT_OFFSET" | grep -q '^[0-9][0-9]*$'; then
    echo "Invalid offset (not a number): $CURRENT_OFFSET"
    continue
  fi

  if ! echo "$PARTITION" | grep -q '^[0-9][0-9]*$'; then
    echo "Invalid partition (not a number): $PARTITION"
    continue
  fi

  if ! echo "$END_OFFSET" | grep -q '^[0-9][0-9]*$'; then
    echo "Invalid end offset (not a number): $END_OFFSET"
    continue
  fi

  if ! echo "$LAG" | grep -q '^[0-9][0-9]*$'; then
    echo "Invalid lag (not a number): $LAG"
    continue
  fi

  # Calculate the number of available messages
  AVAILABLE_MESSAGES=$((END_OFFSET - CURRENT_OFFSET))

  # Skip if no messages available (current offset = end offset) or LAG is 0
  if [ "$AVAILABLE_MESSAGES" -eq 0 ] || [ "$LAG" -eq 0 ]; then
    echo "Skipping Topic=$TOPIC, Partition=$PARTITION - No messages available (AvailableMessages=$AVAILABLE_MESSAGES, Lag=$LAG)"
    continue
  fi

  TOTAL_PROCESSED=$((TOTAL_PROCESSED + 1))
  echo "Processing entry $TOTAL_PROCESSED of $TOTAL_ENTRIES: $TOPIC partition $PARTITION offset $CURRENT_OFFSET"

  # Run kafka-console-consumer and capture the output
  echo "Running consumer for Topic=$TOPIC, Partition=$PARTITION"

  # Use a variable to capture the message content
  MESSAGE=$(kafka-console-consumer.sh --bootstrap-server ${SEED_BROKERS} --consumer.config ${KAFKA_CMD_CONFIG} \
    --topic "$TOPIC" \
    --offset "$CURRENT_OFFSET" \
    --partition "$PARTITION" \
    --timeout-ms 3000 \
    --max-messages 1 \
    --property print.headers=true 2>/dev/null)

  # Check if we got any output
  if [ -n "$MESSAGE" ]; then
    # Check if the output contains the search value
    if echo "$MESSAGE" | grep -q "$SEARCH_VALUE"; then
      echo "==============================================="
      echo "FOUND \"$SEARCH_VALUE\" IN $TOPIC ($PARTITION:$CURRENT_OFFSET)"
      echo "==============================================="
      echo "Message content:"
      echo "$MESSAGE"
      # Clean up and exit directly when match is found
      rm -f "$TMP_FILE"
      exit 0
    else
      echo "No match in this message"
    fi
  else
    echo "No message received or error occurred"
  fi
done

# Clean up temporary file
rm -f "$TMP_FILE"
