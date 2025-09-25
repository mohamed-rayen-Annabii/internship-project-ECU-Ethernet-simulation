#!/bin/bash
set -e

RESULT_FILE="test/results.md"

> "$RESULT_FILE"
echo "# Fault Injection Test Summary" > "$RESULT_FILE"
echo "" >> "$RESULT_FILE"
echo "_Last updated: **$(date)**_" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"
echo "| Fault Type  | Status  | Details                    |" >> "$RESULT_FILE"
echo "|-------------|---------|----------------------------|" >> "$RESULT_FILE"

for fault in block delay loss corrupt; do
  log="test/${fault}.log"
  flag="test/${fault}.flag"

  if [[ -f "$flag" ]]; then
    if [[ -f "$log" ]]; then
      if grep -q "PASSED" "$log"; then
        status="Passed"
        detail=$(grep "PASSED" "$log" | cut -d: -f2-)
      else
        status="Failed"
        detail="Check ${fault}.log for details"
      fi
    else
      status="No Log"
      detail="Log file not found"
    fi
    printf "| %-11s | %-7s | %s |\n" "$fault" "$status" "$detail" >> "$RESULT_FILE"
  fi
done

# Cleanup after reporting
rm -f test/*.flag

