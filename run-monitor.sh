#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

env_file="$script_dir/monitor.env"
properties_file="$script_dir/monitor.properties"
jar_file="$script_dir/target/example-security-monitor.jar"

if [[ ! -f "$env_file" ]]; then
    printf '%s\n' \
        'ERROR: Copy monitor.env.example to monitor.env and set the secrets first.' >&2
    exit 1
fi

# Load KEY=VALUE entries without executing monitor.env as a shell script.
# This keeps characters such as +, / and = intact in generated secrets.
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"

    # Ignore blank lines and comments, including those with leading whitespace.
    trimmed="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue

    if [[ "$line" != *=* ]]; then
        printf 'ERROR: Invalid monitor.env line (expected NAME=VALUE): %s\n' "$line" >&2
        exit 1
    fi

    name="${line%%=*}"
    value="${line#*=}"
    name="${name#"${name%%[![:space:]]*}"}"
    name="${name%"${name##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        printf 'ERROR: Invalid environment variable name: %s\n' "$name" >&2
        exit 1
    fi

    export "$name=$value"
done < "$env_file"

if [[ ! -f "$properties_file" ]]; then
    printf '%s\n' \
        'ERROR: Copy monitor.properties.example to monitor.properties and review the URLs first.' >&2
    exit 1
fi

if [[ ! -f "$jar_file" ]]; then
    printf '%s\n' \
        'ERROR: target/example-security-monitor.jar does not exist. Run ./build.sh first.' >&2
    exit 1
fi

if ! command -v java >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: Java is not installed or is not available on PATH.' >&2
    exit 1
fi

exec java -jar "$jar_file" "$properties_file"
