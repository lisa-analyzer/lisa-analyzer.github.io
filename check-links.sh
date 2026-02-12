#!/bin/bash
#
# check-links.sh - Find stale HTTPS/local links
#
# Usage: check-links.sh [--verbose] [--timeout SECONDS] [--parallel N] [PATH...]
#
# Options:
#   --verbose      Print verbose output
#   --timeout N    Timeout for HTTP requests in seconds (default: 60)
#   --parallel N   Number of parallel URL checks (default: 10, use 1 to disable)
#   --help         Show this help message
#
# If no PATH is provided, searches the current directory.
# Always excludes .git/ directory.
#
# Timeouts (HTTP 000) are reported separately and do not cause failure.
# Only actual HTTP errors (404, 500, etc.) are counted as stale links.
#
# This script is an adaptdation of https://github.com/antlr/grammars-v4/blob/37b7ce211e9817c7ffa53fff4d915cee0706b174/_scripts/find-stale-links.sh

set -euo pipefail

# Default values
VERBOSE=false
TIMEOUT=60
PARALLEL=10
PATHS=()

# Color output (if terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

usage() {
    sed -n '3,19p' "$0" | sed 's/^# \?//'
    exit 0
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $*" >&2
    fi
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --verbose)
        VERBOSE=true
        shift
        ;;
    --timeout)
        TIMEOUT="$2"
        shift 2
        ;;
    --parallel)
        PARALLEL="$2"
        shift 2
        ;;
    --help | -h)
        usage
        ;;
    -*)
        log_error "Unknown option: $1"
        usage
        ;;
    *)
        PATHS+=("$1")
        shift
        ;;
    esac
done

# Default to current directory if no paths specified
if [[ ${#PATHS[@]} -eq 0 ]]; then
    PATHS=(".")
fi

# Temporary files for tracking results
STALE_LINKS_FILE=$(mktemp)
TIMEOUT_LINKS_FILE=$(mktemp)
INVALID_LINKS_FILE=$(mktemp)
CHECKED_URLS_FILE=$(mktemp)
URLS_TO_CHECK_FILE=$(mktemp)
LIQUID_TO_CHECK_FILE=$(mktemp)
URL_RESULTS_FILE=$(mktemp)
LIQUID_RESULTS_FILE=$(mktemp)
URL_OCCURRENCES_FILE=$(mktemp)
LIQUID_OCCURRENCES_FILE=$(mktemp)
trap 'rm -f "$STALE_LINKS_FILE" "$TIMEOUT_LINKS_FILE" "$INVALID_LINKS_FILE" "$CHECKED_URLS_FILE" "$URLS_TO_CHECK_FILE" "$URL_RESULTS_FILE" "$URL_OCCURRENCES_FILE" "$LIQUID_TO_CHECK_FILE" "$LIQUID_RESULTS_FILE" "$LIQUID_OCCURRENCES_FILE"' EXIT

# URL cache to avoid checking the same URL multiple times (used after parallel check)
# Format: URL_CACHE[url]="status:http_code" where status is OK, TIMEOUT, or STALE
declare -A URL_CACHE

# Check a single URL and output result (for parallel execution)
# Output format: OK|TIMEOUT|STALE<tab>HTTP_CODE<tab>URL
check_url_standalone() {
    local url="$1"
    local timeout="$2"

    # Use curl to check the URL
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout "$timeout" \
        --max-time "$((timeout * 3))" \
        -L \
        -A "Mozilla/5.0 (compatible; StaleLinksChecker/1.0)" \
        "$url" 2>/dev/null || echo "000")

    # Consider various status codes
    # 401/403 mean the URL exists but requires authentication - not stale
    case "$http_code" in
    200 | 201 | 202 | 203 | 204 | 301 | 302 | 303 | 307 | 308 | 401 | 403)
        echo -e "OK\t$http_code\t$url"
        ;;
    000)
        # 000 means timeout or connection failure
        echo -e "TIMEOUT\t$http_code\t$url"
        ;;
    *)
        # Actual HTTP error (404, 500, etc.)
        echo -e "STALE\t$http_code\t$url"
        ;;
    esac
}
export -f check_url_standalone

# Check a single liquid link and output result (for parallel execution)
# Output format: OK|STALE|INVALID|SECTION<tab>URL
check_liquid_standalone() {
    local input="$1"

    local fpath section
    if [[ "$input" == *#* ]]; then
        fpath="${input%#*}"
        section="${input#*#}"
        section="${section:-MISSING}"
    else
        fpath="$input"
        section=""
    fi

    if [[ "$fpath" == *.md ]]; then
        echo -e "INVALID\t$input"
        return
    fi

    if [[ "$fpath" == *.html ]]; then
        fpath="${fpath%.html}.md"
    fi

    if [[ -e "$fpath" ]]; then
        if [[ -z "$section" ]]; then
            echo -e "OK\t$input"
            return
        fi

        # open the file and search for the section header
        section="${section//-/ }" # replace dashes with spaces for matching
        if grep -qiE "^#+[[:space:]]*$section[[:space:]]*$" "$fpath"; then
            echo -e "OK\t$input"
        else
            echo -e "SECTION\t$input"
        fi
    else
        echo -e "STALE\t$input"
    fi
}
export -f check_liquid_standalone

# Extract URLs from a file (collection phase - no checking)
# Outputs: file<tab>line_num<tab>url to URL_OCCURRENCES_FILE
# Also outputs unique URLs to stdout for collection
collect_urls_from_file() {
    local file="$1"

    log_verbose "Collecting URLs from: $file"

    # Extract HTTP/HTTPS URLs from the file with line numbers
    local url_matches
    url_matches=$(grep -noP 'https?://[^\s<>"\]`'\'']+' "$file" 2>/dev/null || true)

    if [[ -z "$url_matches" ]]; then
        return
    fi

    while IFS= read -r match_line; do
        line_num="${match_line%%:*}"
        url="${match_line#*:}"

        # Clean up the URL
        url=$(echo "$url" | sed 's/[,;.!?>}:]*$//' | sed "s/'$//" | sed 's/\]$//')
        # if the url is escaped inside a liquid string, it will end with \"
        # but the line above will keep the backslash
        url=${url%\\}

        [[ "$url" == "https://www.googletagmanager.com/"* ]] && continue

        # Balance parentheses
        while [[ "$url" == *")" ]]; do
            local open_count close_count
            open_count=$(echo "$url" | tr -cd '(' | wc -c)
            close_count=$(echo "$url" | tr -cd ')' | wc -c)
            if [[ "$close_count" -gt "$open_count" ]]; then
                url="${url%)}"
            else
                break
            fi
        done

        [[ -z "$url" ]] && continue

        # Record this occurrence
        printf '%s\t%s\t%s\n' "$file" "$line_num" "$url" >>"$URL_OCCURRENCES_FILE"
        # Output URL for unique collection
        echo "$url"
    done <<<"$url_matches"
}

# Extract liquid links from a file (collection phase - no checking)
# Outputs: file<tab>line_num<tab>url to LIQUID_OCCURRENCES_FILE
# Also outputs links to stdout for collection
collect_liquid_links_from_file() {
    local file="$1"

    log_verbose "Collecting liquid links from: $file"

    # Extract liquid root links from the file with line numbers
    local liquid_matches
    liquid_matches=$(grep -noP '{{ site.baseurl }}/[^"\)]+' "$file" 2>/dev/null || true)

    if [[ -z "$liquid_matches" ]]; then
        return
    fi

    while IFS= read -r match_line; do
        line_num="${match_line%%:*}"
        url="${match_line#*:}"

        url="${url#"{{ site.baseurl }}/"}"

        [[ -z "$url" ]] && continue

        # Record this occurrence
        printf '%s\t%s\t%s\n' "$file" "$line_num" "$url" >>"$LIQUID_OCCURRENCES_FILE"
        # Output URL for unique collection
        echo "$url"
    done <<<"$liquid_matches"
}

is_absolute_url() {
    local url="$1"
    [[ -z "$url" || "$url" == https://* || "$url" == http://* || "$url" == "{{"* || "$url" == mailto:* ]]
}

# Extract invalid (i.e., relative) links from a file
# Outputs: file<tab>line_num<tab>url to INVALID_LINKS_FILE
collect_invalid_links_from_file() {
    local file="$1"

    log_verbose "Collecting relative links from: $file"

    # Extract href, src, and markdown links from the file with line numbers
    local href_matches=$(grep -noP 'href="[^"]+' "$file" 2>/dev/null || true)
    local src_matches=$(grep -noP 'src="[^"]+' "$file" 2>/dev/null || true)
    local markdown_matches=$(grep -noP '\[[^\]]+\]\([^\)]+\)' "$file" 2>/dev/null || true)

    if [[ -n "$href_matches" ]]; then
        while IFS= read -r match_line; do
            line_num="${match_line%%:*}"
            url="${match_line#*:}"

            url="${url#"href=\""}"

            is_absolute_url $url && continue
            # hack: there is one link in the toc that is hard to check automatically
            [[ "$file" == *"/toc.html" && "$url" == *"{{ baseURL }}"* ]] && continue

            # Record this occurrence
            printf 'HREF\t%s\t%s\t%s\n' "$file" "$line_num" "$url" >>"$INVALID_LINKS_FILE"
        done <<<"$href_matches"
    fi
    if [[ -n "$src_matches" ]]; then
        while IFS= read -r match_line; do
            line_num="${match_line%%:*}"
            url="${match_line#*:}"

            url="${url#"src=\""}"

            is_absolute_url $url && continue

            # Record this occurrence
            printf 'SRC\t%s\t%s\t%s\n' "$file" "$line_num" "$url" >>"$INVALID_LINKS_FILE"
        done <<<"$src_matches"
    fi
    if [[ -n "$markdown_matches" ]]; then
        while IFS= read -r match_line; do
            line_num="${match_line%%:*}"
            url="${match_line#*:}"

            if [[ "$url" =~ \(([^\)]+)\) ]]; then
                url="${BASH_REMATCH[1]}"
            fi

            is_absolute_url $url && continue
            [[ "$url" == \#* ]] && continue

            # Record this occurrence
            printf 'MARKDOWN\t%s\t%s\t%s\n' "$file" "$line_num" "$url" >>"$INVALID_LINKS_FILE"
        done <<<"$markdown_matches"
    fi
}

# Process URL check results and handle stale links
process_results() {
    log_verbose "Processing URL check results..."

    # Load URL results into cache
    # Format: status<tab>http_code<tab>url
    while IFS=$'\t' read -r status http_code url; do
        URL_CACHE["$url"]="$status:$http_code"
    done <"$URL_RESULTS_FILE"
    while IFS=$'\t' read -r status url; do
        URL_CACHE["$url"]="$status"
    done <"$LIQUID_RESULTS_FILE"

    # Process each URL occurrence using cached results
    while IFS=$'\t' read -r file line_num url; do
        echo "$url" >>"$CHECKED_URLS_FILE"

        local cached="${URL_CACHE[$url]:-STALE:000}"
        local status="${cached%%:*}"
        local http_code="${cached#*:}"

        case "$status" in
        OK)
            log_verbose "URL is accessible: $url"
            ;;
        TIMEOUT)
            log_warn "Timeout (HTTP $http_code): $file:$line_num - $url"
            printf '%s\t%s\t%s\t%s\n' "$file" "$line_num" "$url" "$http_code" >>"$TIMEOUT_LINKS_FILE"
            ;;
        STALE)
            log_warn "Stale link (HTTP $http_code): $file:$line_num - $url"
            printf 'HTTP%s\t%s\t%s\t%s\n' "$file" "$line_num" "$url" "$http_code" >>"$STALE_LINKS_FILE"
            ;;
        esac
    done <"$URL_OCCURRENCES_FILE"

    while IFS=$'\t' read -r file line_num url; do
        echo "$url" >>"$CHECKED_URLS_FILE"

        local status="${URL_CACHE[$url]:-STALE}"

        case "$status" in
        OK)
            log_verbose "LIQUID link is accessible: $url"
            ;;
        STALE)
            log_warn "Stale LIQUID link: $file:$line_num - $url"
            printf 'LIQUID\t%s\t%s\t%s\t%s\n' "$file" "$line_num" "$url" "STALE" >>"$STALE_LINKS_FILE"
            ;;
        INVALID)
            log_warn "Invalid LIQUID link: $file:$line_num - $url"
            printf 'LIQUID\t%s\t%s\t%s\t%s\n' "$file" "$line_num" "$url" "INVALID_LINK" >>"$STALE_LINKS_FILE"
            ;;
        SECTION)
            log_warn "Invalid section LIQUID link: $file:$line_num - $url"
            printf 'LIQUID\t%s\t%s\t%s\t%s\n' "$file" "$line_num" "$url" "INVALID_SECTION" >>"$STALE_LINKS_FILE"
            ;;
        esac
    done <"$LIQUID_OCCURRENCES_FILE"
}

# Main execution
main() {
    log_info "Starting stale link check..."
    log_info "Timeout: ${TIMEOUT}s"
    log_info "Parallel jobs: $PARALLEL"
    log_info "Paths: ${PATHS[*]}"

    # Find all text files, excluding .git directory
    local find_args=()
    for path in "${PATHS[@]}"; do
        find_args+=("$path")
    done
    find_args+=(-type f)
    find_args+=(-not -name 'Gemfile*')
    find_args+=(-not -name '.gitignore')
    find_args+=(-not -name '*.ico')
    find_args+=(-not -name 'LICENSE')
    find_args+=(-not -name 'README.md')
    find_args+=(-not -name '*.log')
    find_args+=(-not -name '*.png')
    find_args+=(-not -name 'schemes.*')
    find_args+=(-not -name '*.sh')
    find_args+=(-not -name '*.txt')
    find_args+=(-not -name '*.yml')
    find_args+=(-not -path '*/custom-assets/*')
    find_args+=(-not -path '*/.git/*')
    find_args+=(-not -path '*/.github/*')
    find_args+=(-not -path '*/_sass/*')
    find_args+=(-not -path '*/_site/*')

    # Phase 1: Collect all URLs from all files
    log_info "Phase 1: Collecting URLs from files..."
    local file_count=0
    while IFS= read -r file; do
        collect_urls_from_file "$file" >>"$URLS_TO_CHECK_FILE"
        collect_liquid_links_from_file "$file" >>"$LIQUID_TO_CHECK_FILE"
        collect_invalid_links_from_file "$file"
        file_count=$((file_count + 1))
    done < <(find "${find_args[@]}" 2>/dev/null || true)

    log_info "Processed $file_count files"

    local links_count
    links_count=$(wc -l <"$URLS_TO_CHECK_FILE" | tr -d ' ')
    local liquid_count
    liquid_count=$(wc -l <"$LIQUID_TO_CHECK_FILE" | tr -d ' ')
    local invalid_count
    invalid_count=$(wc -l <"$INVALID_LINKS_FILE" | tr -d ' ')

    if [[ "$links_count" -eq 0 && "$liquid_count" -eq 0 && "$invalid_count" -gt 0 ]]; then
        log_info "No links found to check"
        exit 0
    fi

    log_info "Found $links_count URLs to check"
    log_info "Found $liquid_count LIQUID links to check"

    # Phase 2: Check URLs in parallel
    log_info "Phase 2: Checking URLs and LIQUID links (parallel=$PARALLEL)..."

    # Use xargs for parallel execution
    cat "$URLS_TO_CHECK_FILE" | xargs -P "$PARALLEL" -I {} bash -c 'check_url_standalone "$@"' _ {} "$TIMEOUT" >>"$URL_RESULTS_FILE"
    cat "$LIQUID_TO_CHECK_FILE" | xargs -P "$PARALLEL" -I {} bash -c 'check_liquid_standalone "$@"' _ {} >>"$LIQUID_RESULTS_FILE"

    # Phase 3: Process results
    log_info "Phase 3: Processing results..."
    process_results

    # Report results
    local stale_count
    stale_count=$(wc -l <"$STALE_LINKS_FILE" | tr -d ' ')
    local timeout_count
    timeout_count=$(wc -l <"$TIMEOUT_LINKS_FILE" | tr -d ' ')
    local checked_count
    checked_count=$(wc -l <"$CHECKED_URLS_FILE" | tr -d ' ')
    local final_unique_count
    final_unique_count=$(sort -u "$CHECKED_URLS_FILE" | wc -l | tr -d ' ')

    log_info "Checked $final_unique_count unique URLs ($checked_count total occurrences)"

    # Report timeouts (warnings only, don't fail)
    if [[ "$timeout_count" -gt 0 ]]; then
        log_warn "Found $timeout_count URL(s) that timed out (not counted as stale):"
        while IFS=$'\t' read -r report_file report_line_num report_url report_code; do
            echo "$report_file:$report_line_num (HTTP $report_code): $report_url"
        done <"$TIMEOUT_LINKS_FILE"
        echo "======================"
    else
        log_info "No timeouts found!"
    fi

    # Report stale links (actual errors)
    if [[ "$stale_count" -gt 0 ]]; then
        log_error "Found $stale_count stale link(s):"
        while IFS=$'\t' read -r kind report_file report_line_num report_url report_code; do
            echo "$report_file:$report_line_num ($kind $report_code): $report_url"
        done <"$STALE_LINKS_FILE"
        echo "=========================="
    else
        log_info "No stale links found!"
    fi

    # Report invalid links (actual errors)
    if [[ "$invalid_count" -gt 0 ]]; then
        log_error "Found $invalid_count relative link(s):"
        while IFS=$'\t' read -r kind report_file report_line_num report_url; do
            echo "$report_file:$report_line_num ($kind link): $report_url"
        done <"$INVALID_LINKS_FILE"
        echo "=========================="
    else
        log_info "No relative links found!"
    fi

    if [[ "$stale_count" -gt 0 || "$invalid_count" -gt 0 ]]; then
        log_error "Stale or invalid links detected! Please review the report above and fix or remove these links."
        exit 1
    else
        log_info "All links are valid!"
        exit 0
    fi
}

main
