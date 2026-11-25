#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "$0")/.." && pwd)"
checkout="${HOME}/meros-testing/wordpress-develop"
reference="${MEROS_WP_TEST_REF:-7.1}"

if [ ! -d "$checkout" ]; then
    mkdir -p "${HOME}/meros-testing"
    git clone --depth 1 --branch "$reference" https://github.com/WordPress/wordpress-develop.git "$checkout"
fi
if [ ! -f "$checkout/tests/phpunit/includes/bootstrap.php" ] || [ ! -f "$checkout/src/wp-settings.php" ]; then
    echo "The WordPress test checkout is incomplete: $checkout" >&2
    exit 1
fi

composer --working-dir="$workspace/tools/testing" install --no-interaction
echo "Test dependencies are ready. Start the testing-profile test-db service, then run bash .devcontainer/test.sh integration."
