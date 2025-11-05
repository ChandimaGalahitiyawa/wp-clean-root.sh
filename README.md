# WP Clean Root Script

A Bash script to clean a WordPress site root by removing files that are **not** standard WordPress core files, `wp-config.php`, or the `wp-content` directory.

---

## Description

This script runs for each subdirectory under `/var/www/wordpress` that contains a `wp-config.php` file.  

It is useful for cleaning up stray files or directories in a WordPress installation while keeping essential core files intact.

---

## Usage

```bash
# Actually delete unwanted files
./wp-clean-root.sh

# Show what would be deleted without actually deleting
./wp-clean-root.sh --dry-run

# Delete files and then reinstall WordPress core + verify
./wp-clean-root.sh --reinstall

# Dry run (reinstall ignored when dry-run)
./wp-clean-root.sh --dry-run --reinstall
