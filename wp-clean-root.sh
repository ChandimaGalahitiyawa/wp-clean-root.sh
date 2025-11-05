#!/bin/bash
# Remove anything in site root that is NOT a standard WordPress core file or wp-config.php or wp-content
# Runs for each subdirectory under /var/www/wordpress that contains a wp-config.php
# Usage:
#   ./wp-clean-root.sh          # actually delete
#   ./wp-clean-root.sh --dry-run  # show what would be deleted, do not delete
#   ./wp-clean-root.sh --reinstall  # delete and then reinstall core + verify
#   ./wp-clean-root.sh --dry-run --reinstall  # dry run (reinstall ignored when dry-run)
#
# WARNING: not reversible. Use --dry-run first if you're uncertain.

BASE_PATH="/var/www/wordpress"
LOG_FILE="/root/wp-clean-root.log"
DRY_RUN=0
REINSTALL=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --reinstall) REINSTALL=1 ;;
    *) ;;
  esac
done

echo "=== wp-clean-root.sh started: $(date) ===" | tee -a "$LOG_FILE"

# list of names to keep in site root (core files & wp-config.php & wp-content)
KEEP_NAMES=(
  "."
  "index.php"
  "license.txt"
  "readme.html"
  "wp-activate.php"
  "wp-admin"
  "wp-blog-header.php"
  "wp-comments-post.php"
  "wp-config.php"
  "wp-config-sample.php"
  "wp-content"
  "wp-cron.php"
  "wp-includes"
  "wp-links-opml.php"
  "wp-load.php"
  "wp-login.php"
  "wp-mail.php"
  "wp-settings.php"
  "wp-signup.php"
  "wp-trackback.php"
  "xmlrpc.php"
)

# build -not -name filters for find
FILTER_EXPR=""
for name in "${KEEP_NAMES[@]}"; do
  # skip first entry '.' because find will always start from '.'
  FILTER_EXPR+=" -not -name '$name'"
done

# Loop sites
for SITE in "$BASE_PATH"/*/; do
  # ensure trailing slash expanded is a directory
  [ -d "$SITE" ] || continue

  # skip if not WordPress (no wp-config.php)
  if [ ! -f "$SITE/wp-config.php" ]; then
    echo "Skip (no wp-config.php): $SITE" | tee -a "$LOG_FILE"
    continue
  fi

  echo "--------------------------------------------------------" | tee -a "$LOG_FILE"
  echo "Site: $SITE" | tee -a "$LOG_FILE"
  cd "$SITE" || { echo "Cannot cd to $SITE" | tee -a "$LOG_FILE"; continue; }

  # Dry run: show items that would be removed
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN: files/directories that would be removed from $SITE (root only):" | tee -a "$LOG_FILE"
    # Use eval to expand the FILTER_EXPR correctly inside find
    eval "find . -maxdepth 1 ${FILTER_EXPR} -print" | sed 's|^\./||' | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    continue
  fi

  # Actual removal: remove everything in root except the keep list
  echo "Removing unexpected files/directories from $SITE (root only)..." | tee -a "$LOG_FILE"
  # Use eval so the -not -name pieces are parsed as intended
  eval "find . -maxdepth 1 ${FILTER_EXPR} -exec rm -rf {} \; -print" 2>>"$LOG_FILE" | sed 's|^\./||' | tee -a "$LOG_FILE"

  # Optional: reinstall core and verify
  if [ "$REINSTALL" -eq 1 ]; then
    echo "Reinstalling WordPress core for $SITE" | tee -a "$LOG_FILE"
    wp core download --force --allow-root --path="$SITE" >>"$LOG_FILE" 2>&1
    echo "Verifying checksums for $SITE" | tee -a "$LOG_FILE"
    wp core verify-checksums --allow-root --path="$SITE" | tee -a "$LOG_FILE"
  fi

  echo "Finished site: $SITE" | tee -a "$LOG_FILE"
done

echo "=== wp-clean-root.sh finished: $(date) ===" | tee -a "$LOG_FILE"
