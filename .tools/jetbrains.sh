#!/usr/bin/env bash
set -euo pipefail
LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EBUILD_DIR="${REPO_ROOT}/dev-util"
DISTDIR="${DISTDIR:-/var/cache/distfiles}"

FOREIGN_ARCH_PATTERN="[-/_](linux-(musl|arm)|macos|osx|darwin|mac|windows|win|aarch|arm)[^/]*"
NATIVE_ARCH_PATTERN="[-/_]linux-x64[^/]*"

show_help() {
    echo "Usage: $0 [GLOBAL_OPTIONS] COMMAND <package>"
    echo "Helper for maintaining JetBrains IDE ebuilds."
    echo ""
    echo "Commands:"
    echo "  licenses     Output a Gentoo LICENSE string from third-party libraries"
    echo "  find-exec    Output fperms lines for executable files"
    echo "  find-arch    Output rm lines for foreign architecture directories"
    echo ""
    echo "Global options:"
    echo "  --distdir PATH    Directory containing downloaded tarballs"
    echo "                    (default: \$DISTDIR or /var/cache/distfiles)"
    echo "  -h, --help        Show this help message and exit"
    echo ""
    echo "Run '$0 COMMAND --help' for more information on a command."
}

show_help_licenses() {
    echo "Usage: $0 [GLOBAL_OPTIONS] licenses <package>"
    echo "Output a Gentoo LICENSE string from JetBrains third-party libraries."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo ""
    echo "Dependencies: bash, curl, jq"
    echo "Note: generated strings should be reviewed before committing."
}

show_help_find_exec() {
    echo "Usage: $0 [GLOBAL_OPTIONS] find-exec [OPTIONS] <package>"
    echo "Output fperms lines for executable files inside a JetBrains IDE tarball."
    echo "Foreign architecture executables are excluded by default."
    echo ""
    echo "Options:"
    echo "  --all         Include executables for foreign architectures"
    echo "  -h, --help    Show this help message and exit"
}

show_help_find_arch() {
    echo "Usage: $0 [GLOBAL_OPTIONS] find-arch <package>"
    echo "Output rm lines for foreign architecture directories, excluding linux-x64 and linux-musl-x64."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
}

archive_expand_variables() {
    local value="$1"
    local pn="$2"
    local pv="$3"
    local pr="$4"
    local p="$5"
    local src_uri_path="$6"
    local src_uri_pn="$7"

    value="${value//\$\{P\}/$p}"
    value="${value//\$\{PN\}/$pn}"
    value="${value//\$\{PV\}/$pv}"
    value="${value//\$\{PR\}/$pr}"
    value="${value//\$\{SRC_URI_PATH\}/$src_uri_path}"
    value="${value//\$\{SRC_URI_PN\}/$src_uri_pn}"

    printf '%s' "$value"
}

ebuild_read_var() {
    local ebuild="$1"
    local variable="$2"

    grep -E "^${variable}=\"" "$ebuild" | head -1 | sed -E 's/^[^=]+="([^"]*)".*/\1/'
}

ebuild_parse_package_name() {
    local package_name="$1"
    local name_without_revision="$package_name"

    if [[ "$package_name" =~ -r[0-9]+$ ]]; then
        name_without_revision="${package_name%-r[0-9]*}"
    fi

    local revision="${package_name#"$name_without_revision"}"
    local version="${name_without_revision##*-}"
    local name="${name_without_revision%-${version}}"

    printf '%s\t%s\t%s\n' "$name" "$version" "$revision"
}

ebuild_resolve() {
    local package="$1"
    local pkg_dir="${EBUILD_DIR}/${package}"

    if [[ ! -d "$pkg_dir" ]]; then
        echo "Error: Package '${package}' not found in ${EBUILD_DIR}" >&2
        return 1
    fi

    local ebuild
    ebuild=$(ls -1 "${pkg_dir}"/*.ebuild 2>/dev/null | grep -v '9999' | sort -V | tail -1 || true)
    if [[ -z "$ebuild" ]] || [[ ! -f "$ebuild" ]]; then
        echo "Error: No ebuild found for package '${package}'" >&2
        return 1
    fi

    echo "$ebuild"
}

ebuild_parse_metadata() {
    local ebuild="$1"
    local basename_ebuild
    basename_ebuild=$(basename "$ebuild" .ebuild)

    local pn pv pr p
    IFS=$'\t' read -r pn pv pr < <(ebuild_parse_package_name "$basename_ebuild")
    p="${pn}-${pv}"

    local src_uri src_uri_path src_uri_pn
    src_uri=$(ebuild_read_var "$ebuild" "SRC_URI")
    src_uri_path=$(ebuild_read_var "$ebuild" "SRC_URI_PATH")
    src_uri_pn=$(ebuild_read_var "$ebuild" "SRC_URI_PN")

    src_uri=$(archive_expand_variables "$src_uri" "$pn" "$pv" "$pr" "$p" "$src_uri_path" "$src_uri_pn")

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$ebuild" "$pn" "$pv" "$src_uri" "$src_uri_path" "$src_uri_pn"
}

archive_resolve() {
    local package="$1"

    local ebuild
    ebuild=$(ebuild_resolve "$package") || return 1

    local metadata
    metadata=$(ebuild_parse_metadata "$ebuild") || return 1

    local src_uri distfile archive
    src_uri=$(printf '%s' "$metadata" | cut -f4)

    if [[ "$src_uri" == *" -> "* ]]; then
        distfile="${src_uri##* -> }"
    else
        distfile=$(basename "$src_uri")
    fi

    if [[ -z "$distfile" ]] || [[ "$distfile" == *[/\\]* ]] || [[ "$distfile" == *..* ]] || [[ "$distfile" == *[[:space:]]* ]]; then
        echo "Error: invalid distfile name '${distfile}'" >&2
        return 1
    fi

    archive="${DISTDIR}/${distfile}"
    if [[ ! -f "$archive" ]]; then
        echo "Error: Tarball not found in distfiles: ${archive}" >&2
        echo "Run: ebuild ${ebuild} fetch" >&2
        return 1
    fi

    echo "$archive"
}

declare -A LICENSE_JETBRAINS_MAP=(
    ['0BSD']='0BSD'
    ['Apache 2.0']='Apache-2.0'
    ['Apache License 2.0']='Apache-2.0'
    ['Apache-2.0']='Apache-2.0'
    ['Apache 1.1']='Apache-1.1'
    ['Apache 2.0 with LLVM Exceptions']='Apache-2.0-with-LLVM-exceptions'
    ['BlueOak-1.0.0']='BlueOak-1.0.0'
    ['BSD']='BSD'
    ['BSD 3-Clause']='BSD'
    ['BSD 3-clause']='BSD'
    ['BSD-3-Clause']='BSD'
    ['MIT / BSD 3-clause']='BSD'
    ['BSD 2-Clause']='BSD-2'
    ['BSD-2-Clause']='BSD-2'
    ['CC0-1.0']='CC0-1.0'
    ['Public Domain (CC0)']='CC0-1.0'
    ['CC-BY-2.5']='CC-BY-2.5'
    ['Creative Commons 2.5 Attribution']='CC-BY-2.5'
    ['CC-BY-3.0']='CC-BY-3.0'
    ['CC-BY-4.0']='CC-BY-4.0'
    ['Creative Commons 4.0 Attribution']='CC-BY-4.0'
    ['Custom: http://i.imgur.com/goJdO.png']='MIT'
    ['REDOCLY INC. Subscription Agreement']='redocly'
    ['Commercial, available on request']='yFiles'
    ['Commercial']='anthropic-claude-code'
    ['Unlicense']='Unlicense'
    ['The Unlicense']='Unlicense'
    ['Python-2.0']='PYTHON'
    ['Python 2.1.1 license']='PYTHON'
    ['MIT-0']='MIT-0'
    ['OpenSSL License']='openssl'
    ['Microsoft Public License']='Ms-PL'
    ['Microsoft Reciprocal License']='Ms-RL'
    ['Microsoft Software License Terms (Microsoft Expression Blend SDK for .NET Framework 4.0)']='microsoft_expression-blend-sdk-4.0'
    ['Microsoft Software License Terms (Microsoft .NET Library)']='microsoft_net-library'
    ['Microsoft Software License Terms (Microsoft Windows API Code Pack for Microsoft .NET Framework)']='microsoft_windows-api-code-pack'
    ['Microsoft Software License Terms (Microsoft Windows Software Development Kit (SDK) for Windows)']='microsoft_windows-sdk-10'
    ['Apache License 2.0, Microsoft Software License Terms (Microsoft .NET Library), MIT License (2021 Charlie Poole, Rob Prouse), MIT License (James Newton-King 2008)']='Apache-2.0 MIT'
    ['ANTLR Software Rights Notice']='ANTLR'
    ['Boost Software License 1.0']='Boost-1.0'
    ['Apache License 2.0 WITH LLVM Exception']='Apache-2.0-with-LLVM-exceptions'
    ['JDOM License']='JDOM'
    ['JSON License']='JSON'
    ['Unicode']='unicode'
    ['PSFL']='PSF-2'
    ['PSF-2']='PSF-2'
    ['UPL 1.0']='UPL-1.0'
    ['UPL-1.0']='UPL-1.0'
    ['Eclipse Distribution License 1.0']='EPL-2.0'
    ['CDDL']='CDDL'
    ['CDDL 1.0']='CDDL'
    ['CDDL 1.1']='CDDL-1.1'
    ['CDDL-1.1']='CDDL-1.1'
    ['CPL-1.0']='CPL-1.0'
    ['CPL 1.0']='CPL-1.0'
    ['EPL 1.0']='EPL-1.0'
    ['EPL-1.0']='EPL-1.0'
    ['EPL 2.0']='EPL-2.0'
    ['EPL-2.0']='EPL-2.0'
    ['GPL 2.0']='GPL-2'
    ['GPL-2']='GPL-2'
    ['GPL 2.0 + Classpath']='GPL-2-with-classpath-exception'
    ['GPL 2.0 with classpath exception']='GPL-2-with-classpath-exception'
    ['GPL-2 with classpath exception']='GPL-2-with-classpath-exception'
    ['GPL 3.0']='GPL-3'
    ['GPL-3']='GPL-3'
    ['GPL 3.0 + GCC Runtime Library Exception, version 3.1']='GPL-3 gcc-runtime-library-exception-3.1'
    ['ISC']='ISC'
    ['LGPL 2.0']='LGPL-2'
    ['LGPL-2']='LGPL-2'
    ['LGPL 2.0+']='LGPL-2'
    ['LGPL 2.1']='LGPL-2.1'
    ['LGPL-2.1']='LGPL-2.1'
    ['LGPL 2.1+']='LGPL-2.1'
    ['LGPL 3.0']='LGPL-3'
    ['LGPL-3']='LGPL-3'
    ['MIT']='MIT'
    ['MIT*']='MIT'
    ['MIT License']='MIT'
    ['MIT License with third party notices']='MIT'
    ['MPL 1.1']='MPL-1.1'
    ['MPL-1.1']='MPL-1.1'
    ['MPL 2.0']='MPL-2.0'
    ['MPL-2.0']='MPL-2.0'
    ['OFL']='OFL-1.1'
    ['OFL-1.1']='OFL-1.1'
    ['trilead-ssh']='trilead-ssh'
    ['UoI-NCSA']='UoI-NCSA'
    ['W3C']='W3C'
    ['yFiles']='yFiles'
    ['yourkit']='yourkit'
    ['ZLIB']='ZLIB'
    ['Zlib']='ZLIB'
    ['zlib-acknowledgement']='ZLIB'
    ['zlib/libpng']='ZLIB'
    ['codehaus']='codehaus'
)

license_map_single() {
    local license="$1"

    case "$license" in
    "Apache 2.0"*)
        printf 'Apache-2.0\n'
        return
        ;;
    "MIT License"*)
        printf 'MIT\n'
        return
        ;;
    "BSD 3-Clause \"New\""*)
        printf 'BSD\n'
        return
        ;;
    esac

    if [[ -n "${LICENSE_JETBRAINS_MAP[$license]+x}" ]]; then
        local token
        for token in ${LICENSE_JETBRAINS_MAP[$license]}; do
            printf '%s\n' "$token"
        done
    else
        printf '%s\n' "$license"
    fi
}

license_trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

license_split_expr() {
    local expression="$1"
    local separator="$2"

    expression="${expression#\(}"
    expression="${expression%\)}"

    local parts
    IFS="$separator" read -ra parts <<<"$expression"

    local part
    for part in "${parts[@]}"; do
        part=$(license_trim "$part")
        [[ -n "$part" ]] && printf '%s\n' "$part"
    done
}

license_normalize_expression() {
    local expression="$1"
    expression=$(license_trim "$expression")

    if [[ "$expression" == *" OR "* ]]; then
        echo "||"
        echo "("
        local part
        while IFS= read -r part; do
            [ -n "$part" ] || continue
            license_map_single "$part"
        done < <(license_split_expr "$expression" " OR ")
        echo ")"
        return
    fi

    if [[ "$expression" == *" AND "* ]]; then
        local part
        while IFS= read -r part; do
            [ -n "$part" ] || continue
            license_map_single "$part"
        done < <(license_split_expr "$expression" " AND ")
        return
    fi

    license_map_single "$expression"
}

license_simplify() {
    local standalone=()
    local or_groups=()
    local all=()
    local in_or=false
    local or_members=()
    local prev=""
    local item

    for item in "$@"; do
        if [[ "$item" == "||" ]]; then
            prev="||"
        elif [[ "$item" == "(" ]] && [[ "$prev" == "||" ]]; then
            in_or=true
            prev=""
            or_members=()
        elif [[ "$item" == ")" ]] && $in_or; then
            in_or=false
            or_groups+=("${or_members[*]}")
            prev=""
        elif $in_or; then
            or_members+=("$item")
            all+=("$item")
            prev="$item"
        else
            standalone+=("$item")
            all+=("$item")
            prev="$item"
        fi
    done

    local result=()
    result+=("${standalone[@]}")

    local group
    for group in "${or_groups[@]}"; do
        local members=($group)
        local covered=true
        local member
        for member in "${members[@]}"; do
            local found=false
            local s
            for s in "${all[@]}"; do
                if [[ "$s" == "$member" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" == "false" ]]; then
                covered=false
                break
            fi
        done

        if [[ "$covered" == "true" ]]; then
            result+=("${members[@]}")
        else
            result+=("|| ( ${members[*]} )")
        fi
    done

    printf '%s\n' "${result[@]}" | sort -u | tr '\n' ' ' | sed 's/ *$//'
}

license_build_json_url() {
    local pkg="$1"
    local pv="$2"
    local ebuild="$3"

    local src_uri_path=""
    local src_uri_pn=""
    local simple_name=""

    if [[ -f "$ebuild" ]]; then
        src_uri_path=$(ebuild_read_var "$ebuild" "SRC_URI_PATH")
        src_uri_pn=$(ebuild_read_var "$ebuild" "SRC_URI_PN")
        simple_name=$(ebuild_read_var "$ebuild" "SIMPLE_NAME")
        src_uri_path="${src_uri_path//\$\{PN\}/$pkg}"
        src_uri_path="${src_uri_path//\$\{SIMPLE_NAME\}/$simple_name}"
        src_uri_pn="${src_uri_pn//\$\{PN\}/$pkg}"
        src_uri_pn="${src_uri_pn//\$\{SIMPLE_NAME\}/$simple_name}"
    fi

    local path=""
    case "$pkg" in
    dataspell) path="dataspell" ;;
    gateway | jetbrains-gateway) path="idea/gateway" ;;
    rider) path="dotnet" ;;
    esac
    if [[ -z "$path" ]]; then
        if [[ -n "${src_uri_path:-}" ]] && [[ "$src_uri_path" != */* ]]; then
            path="$src_uri_path"
        else
            path="$pkg"
        fi
    fi

    local pn="${src_uri_pn:-$pkg}"
    case "$pkg" in
    intellij-idea) pn="idea" ;;
    pycharm) pn="pycharmPY" ;;
    esac

    echo "https://resources.jetbrains.com/storage/third-party-libraries/${path}/${pn}-${pv}-third-party-libraries.json"
}

cmd_licenses() {
    local package=""

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -h | --help)
            show_help_licenses
            return 0
            ;;
        *)
            if [[ -z "$package" ]]; then
                package="$1"
            else
                echo "Error: Unexpected argument $1" >&2
                show_help_licenses
                return 1
            fi
            ;;
        esac
        shift
    done

    if [[ -z "$package" ]]; then
        echo "Error: Package name is required" >&2
        show_help_licenses
        return 1
    fi

    local ebuild pv json_url licenses_json raw_licenses
    ebuild=$(ebuild_resolve "$package") || return 1

    local metadata
    metadata=$(ebuild_parse_metadata "$ebuild")
    pv=$(printf '%s' "$metadata" | cut -f3)

    echo "=== $package ($pv) ==="

    json_url=$(license_build_json_url "$package" "$pv" "$ebuild")

    if ! licenses_json=$(curl -fsSL "$json_url" 2>/dev/null); then
        echo "  Error: cannot download third-party license JSON from ${json_url}" >&2
        return 1
    fi

    raw_licenses=$(echo "$licenses_json" | jq -r '[.[].license // empty] | unique | .[]')

    local gentoo_tokens=()
    local unknown_licenses=""
    while IFS= read -r license; do
        [[ -n "$license" ]] || continue
        local normalized
        normalized=$(license_normalize_expression "$license")
        if [[ "$normalized" == *"all-rights-reserved"* ]]; then
            unknown_licenses+="  - $license (mapped to all-rights-reserved)"$'\n'
        fi
        local token
        while IFS= read -r token; do
            [[ -n "$token" ]] || continue
            gentoo_tokens+=("$token")
        done <<<"$normalized"
    done <<<"$raw_licenses"

    echo "  ebuild-ready LICENSE:"
    echo "    $(license_simplify "${gentoo_tokens[@]}")"

    if [[ -n "$unknown_licenses" ]]; then
        echo "  Unmapped (kept verbatim):"
        echo -n "$unknown_licenses"
    fi
    echo ""
}

cmd_find_exec() {
    local package=""
    local all_arch=false

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -h | --help)
            show_help_find_exec
            return 0
            ;;
        --all) all_arch=true ;;
        *)
            if [[ -z "$package" ]]; then
                package="$1"
            else
                echo "Error: Unexpected argument $1" >&2
                show_help_find_exec
                return 1
            fi
            ;;
        esac
        shift
    done

    if [[ -z "$package" ]]; then
        show_help_find_exec
        return 0
    fi

    local archive
    archive=$(archive_resolve "$package") || return 1

    local tar_list files
    if ! tar_list=$(tar -tvf "$archive"); then
        echo "Error: failed to list contents of ${archive}" >&2
        return 1
    fi

    files=$(printf '%s\n' "$tar_list" |
        grep '^-..x' |
        grep -v '\.py$' |
        grep -v '\.js$' |
        grep -v '\.dll$' |
        grep -v '\.so\(\.[0-9]\+\)\{0,3\}$' || true)

    if [[ "$all_arch" == false ]] && [[ -n "$files" ]]; then
        local foreign_files
        foreign_files=$(printf '%s\n' "$files" | grep -iE "$FOREIGN_ARCH_PATTERN" | grep -vE "$NATIVE_ARCH_PATTERN" | sort -u || true)
        if [[ -n "$foreign_files" ]]; then
            files=$(comm -23 <(printf '%s\n' "$files" | sort -u) <(printf '%s\n' "$foreign_files") || true)
        fi
    fi

    local file_list
    file_list=$(printf '%s\n' "$files" | tr -s ' ' | cut -d' ' -f6-)

    echo "$file_list" | while read -r file; do
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
}

cmd_find_arch() {
    local package=""

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -h | --help)
            show_help_find_arch
            return 0
            ;;
        *)
            if [[ -z "$package" ]]; then
                package="$1"
            else
                echo "Error: Unexpected argument $1" >&2
                show_help_find_arch
                return 1
            fi
            ;;
        esac
        shift
    done

    if [[ -z "$package" ]]; then
        show_help_find_arch
        return 0
    fi

    local archive
    archive=$(archive_resolve "$package") || return 1

    local tar_list dirs
    if ! tar_list=$(tar -tvf "$archive"); then
        echo "Error: failed to list contents of ${archive}" >&2
        return 1
    fi

    dirs=$(printf '%s\n' "$tar_list" | grep '^d' | tr -s ' ' | cut -d' ' -f6- || true)
    if [[ -n "$dirs" ]]; then
        dirs=$(printf '%s\n' "$dirs" | grep -iE "$FOREIGN_ARCH_PATTERN" || true)
    fi
    if [[ -n "$dirs" ]]; then
        dirs=$(printf '%s\n' "$dirs" | grep -vE "$NATIVE_ARCH_PATTERN" || true)
    fi
    if [[ -n "$dirs" ]]; then
        dirs=$(printf '%s\n' "$dirs" | grep -oiE ".*$FOREIGN_ARCH_PATTERN" || true)
    fi

    local dir_list
    dir_list=$(printf '%s\n' "$dirs" | sort -u)

    # Drop directories that are children of another matched directory.
    local selected=()
    while IFS= read -r dir_path; do
        [[ -z "$dir_path" ]] && continue
        local covered=false
        local sel
        for sel in "${selected[@]}"; do
            if [[ "$dir_path" == "${sel%/}"/* ]]; then
                covered=true
                break
            fi
        done
        [[ "$covered" == false ]] && selected+=("$dir_path")
    done <<<"$dir_list"
    dir_list=$(printf '%s\n' "${selected[@]}")

    echo "$dir_list" | while read -r dir_path; do
        [[ -z "$dir_path" ]] && continue
        local stripped_dir="${dir_path#*/}"
        stripped_dir="${stripped_dir%/}"
        if [[ -n "$stripped_dir" ]]; then
            echo "$(dirname "$stripped_dir")|$(basename "$stripped_dir")"
        fi
    done | sort | (
        declare -A groups=()
        while IFS='|' read -r parent child; do
            groups["$parent"]+="${groups[$parent]:+,}$child"
        done

        local parent
        if [[ ${#groups[@]} -gt 0 ]]; then
            mapfile -t sorted_parents < <(printf '%s\n' "${!groups[@]}" | sort)
            for parent in "${sorted_parents[@]}"; do
                local target_path="./$parent"
                [[ "$parent" == "." ]] && target_path="."
                local children="${groups[$parent]}"
                if [[ "$children" == *","* ]]; then
                    echo "rm -rv $target_path/{$children} || die"
                else
                    echo "rm -rv $target_path/$children || die"
                fi
            done
        fi
    )
}

main() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --distdir)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --distdir requires a path" >&2
                return 1
            fi
            DISTDIR="$2"
            shift 2
            ;;
        -h | --help)
            show_help
            return 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Error: Unknown global option $1" >&2
            show_help
            return 1
            ;;
        *) break ;;
        esac
    done

    if [[ "$#" -eq 0 ]]; then
        show_help
        return 0
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
    licenses) cmd_licenses "$@" ;;
    find-exec) cmd_find_exec "$@" ;;
    find-arch) cmd_find_arch "$@" ;;
    -h | --help) show_help ;;
    *)
        echo "Error: Unknown command '$subcommand'" >&2
        show_help
        return 1
        ;;
    esac
}

main "$@"
