#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "$0")/.." && pwd)"
suite="${1:-unit}"
if [ "$#" -gt 0 ]; then
    shift
fi

case "$suite" in
    unit) command="test" ;;
    integration) command="test:integration" ;;
    *) echo "Usage: bash .devcontainer/test.sh [unit|integration] [PHPUnit options]" >&2; exit 1 ;;
esac

export WP_TESTS_DIR="${WP_TESTS_DIR:-${HOME}/meros-testing/wordpress-develop/tests/phpunit}"
export WP_TESTS_ROOT="${WP_TESTS_ROOT:-${HOME}/meros-testing/wordpress-develop/src}"
export MEROS_TEST_DB_NAME="${MEROS_TEST_DB_NAME:-meros_tests}"
export MEROS_TEST_DB_HOST="${MEROS_TEST_DB_HOST:-test-db}"
export MEROS_TEST_DB_USER="${MEROS_TEST_DB_USER:-root}"
export MEROS_TEST_DB_PASSWORD="${MEROS_TEST_DB_PASSWORD:-}"

composer --working-dir="$workspace/tools/testing" "$command" -- "$@"
