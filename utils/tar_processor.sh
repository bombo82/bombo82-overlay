#!/bin/bash

show_help() {
    echo "Usage: $0 COMMAND [OPTIONS] <archive.tar.gz>"
    echo "Process JetBrains IDE tar.gz archives for Gentoo ebuilds."
    echo ""
    echo "Commands:"
    echo "  find-exec    Search for executable files"
    echo "  find-arch    Search for architecture-specific directories"
    echo ""
    echo "Run '$0 COMMAND --help' for more information on a command."
}

show_help_exec() {
    echo "Usage: $0 find-exec [OPTIONS] <archive.tar.gz>"
    echo "Search for executable files inside a tar.gz archive."
    echo ""
    echo "Options:"
    echo "  -e, --exclude PATTERN  Exclude files matching PATTERN (can be used multiple times)"
    echo "  --exclude-arch         Exclude architecture-specific files (non-x64)"
    echo "  --ebuild               Output in Gentoo ebuild fperms format"
    echo "  -h, --help             Show this help message and exit"
}

show_help_arch() {
    echo "Usage: $0 find-arch [OPTIONS] <archive.tar.gz>"
    echo "List architecture-specific directories, excluding linux-x64 and linux-musl-x64."
    echo ""
    echo "Options:"
    echo "  --ebuild               Output in Gentoo ebuild rm format"
    echo "  -h, --help             Show this help message and exit"
}

find_exec() {
    local ARCHIVE=""
    local FORMAT="list"
    local EXCLUDE_ARCH=false
    local EXCLUDES=()
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) show_help_exec; return 0 ;;
            --ebuild) FORMAT="ebuild" ;;
            --exclude-arch) EXCLUDE_ARCH=true ;;
            -e|--exclude)
                if [[ -n "$2" ]]; then
                    EXCLUDES+=("$2")
                    shift
                else
                    echo "Error: Argument for $1 is missing" >&2
                    return 1
                fi
                ;;
            *)
                if [[ -z "$ARCHIVE" ]]; then
                    ARCHIVE="$1"
                else
                    echo "Error: Unexpected argument $1" >&2
                    return 1
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$ARCHIVE" ]]; then
        show_help_exec
        return 0
    fi

    if [[ ! -f "$ARCHIVE" ]]; then
        echo "Error: File '$ARCHIVE' does not exist." >&2
        return 1
    fi

    local GREP_CMD="grep '^-..x' | grep -v '\.py$' | grep -v '\.js$' | grep -v '\.dll$' | grep -v '\.so\(\.[0-9]\+\)\{0,3\}$'"
    
    if [[ "$EXCLUDE_ARCH" == true ]]; then
        # Exclude foreign architectures, but keep linux-x64 and linux-musl-x64.
        # This pattern matches any architecture-specific directory that is NOT x64.
        local FOREIGN_ARCH_PATTERN="/\(linux-arm[^/]*\|linux-musl-\(arm\|aarch\|ppc\|s390\|mips\|riscv\)[^/]*\|macos-[^/]*\|windows-[^/]*\|aarch[^/]*\)/"
        GREP_CMD="$GREP_CMD | grep -v '$FOREIGN_ARCH_PATTERN'"
    fi

    for pattern in "${EXCLUDES[@]}"; do
        GREP_CMD="$GREP_CMD | grep -v -e '$pattern'"
    done

    local FILES=$(eval "tar -tvf \"\$ARCHIVE\" | $GREP_CMD | tr -s ' ' | cut -d' ' -f6-")

    if [[ "$FORMAT" == "ebuild" ]]; then
        echo "$FILES" | while read -r file; do
            [[ -z "$file" ]] && continue
            echo "$(dirname "${file#*/}")|$(basename "$file")"
        done | sort | (
            local current_dir=""
            local files=""
            while IFS='|' read -r dir_name base_name; do
                if [[ "$dir_name" == "$current_dir" ]]; then
                    files="$files,$base_name"
                else
                    if [[ -n "$current_dir" ]]; then
                        local target_path=""
                        [[ "$current_dir" != "." ]] && target_path="/$current_dir"
                        if [[ "$files" == *","* ]]; then
                            echo "fperms 755 \"\${dir}\"${target_path}/{${files}}"
                        else
                            echo "fperms 755 \"\${dir}\"${target_path}/${files}"
                        fi
                    fi
                    current_dir="$dir_name"
                    files="$base_name"
                fi
            done
            if [[ -n "$current_dir" ]]; then
                local target_path=""
                [[ "$current_dir" != "." ]] && target_path="/$current_dir"
                if [[ "$files" == *","* ]]; then
                    echo "fperms 755 \"\${dir}\"${target_path}/{${files}}"
                else
                    echo "fperms 755 \"\${dir}\"${target_path}/${files}"
                fi
            fi
        )
    else
        echo "$FILES"
    fi
}

find_arch() {
    local ARCHIVE=""
    local FORMAT="list"
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) show_help_arch; return 0 ;;
            --ebuild) FORMAT="ebuild" ;;
            *)
                if [[ -z "$ARCHIVE" ]]; then
                    ARCHIVE="$1"
                else
                    echo "Error: Unexpected argument $1" >&2
                    return 1
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$ARCHIVE" ]]; then
        show_help_arch
        return 0
    fi

    if [[ ! -f "$ARCHIVE" ]]; then
        echo "Error: File '$ARCHIVE' does not exist." >&2
        return 1
    fi

    local INCLUDE_PATTERN="/\(linux-arm[^/]*\|linux-musl-[^/]*\|macos-[^/]*\|windows-[^/]*\|aarch[^/]*\)/"
    local EXCLUDE_PATTERN="/\(linux-x64\|linux-musl-x64\)/"

    local DIRS=$(tar -tvf "$ARCHIVE" | grep '^d' | tr -s ' ' | cut -d' ' -f6- | \
        grep "$INCLUDE_PATTERN" | \
        grep -v "$EXCLUDE_PATTERN" | \
        grep -o ".*$INCLUDE_PATTERN" | \
        sort -u)

    if [[ "$FORMAT" == "ebuild" ]]; then
        echo "$DIRS" | while read -r dir_path; do
            [[ -z "$dir_path" ]] && continue
            local stripped_dir="${dir_path#*/}"
            stripped_dir="${stripped_dir%/}"
            if [[ -n "$stripped_dir" ]]; then
                echo "$(dirname "$stripped_dir")|$(basename "$stripped_dir")"
            fi
        done | sort | (
            local current_parent=""
            local children=""
            while IFS='|' read -r parent child; do
                if [[ "$parent" == "$current_parent" ]]; then
                    children="$children,$child"
                else
                    if [[ -n "$current_parent" ]]; then
                        local target_path="./$current_parent"
                        [[ "$current_parent" == "." ]] && target_path="."
                        if [[ "$children" == *","* ]]; then
                            echo "rm -rv $target_path/{$children} || die"
                        else
                            echo "rm -rv $target_path/$children || die"
                        fi
                    fi
                    current_parent="$parent"
                    children="$child"
                fi
            done
            if [[ -n "$current_parent" ]]; then
                local target_path="./$current_parent"
                [[ "$current_parent" == "." ]] && target_path="."
                if [[ "$children" == *","* ]]; then
                    echo "rm -rv $target_path/{$children} || die"
                else
                    echo "rm -rv $target_path/$children || die"
                fi
            fi
        )
    else
        echo "$DIRS"
    fi
}

COMMAND=$1
shift

case "$COMMAND" in
    find-exec) find_exec "$@" ;;
    find-arch) find_arch "$@" ;;
    -h|--help|"") show_help ;;
    *)
        echo "Error: Unknown command '$COMMAND'" >&2
        show_help
        exit 1
        ;;
esac
