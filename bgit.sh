#!/usr/bin/env bash
set -euo pipefail
DEFAULT_OUTPUT="$HOME/tmp/dev"
REPO_PATH="."
OUTPUT_DIR="$DEFAULT_OUTPUT"
INCLUDE_SUBMODULES=false
NO_COMPRESS=false
usage() {
	cat <<'USAGE'
Usage: git-bundle [OPTIONS]
Create a compressed git bundle for offline analysis.
Options:
    -r, --repo PATH       Path to git repository (default: current directory)
    -o, --output DIR      Output directory (default: ~/tmp/dev)
    -s, --submodules      Include git submodules
    --no-compress         Skip gzip compression
    -h, --help            Show this help message
Output: {repo-name}_{YYYY-MM-DD_HH-MM-SS}.bundle[.gz]
USAGE
}
parse_args() {
	parsed=$(getopt -o "r:o:sh" --long "repo:,output:,submodules,no-compress,help" -n "git-bundle" -- "$@")
	eval set -- "$parsed"
	while true; do
		case "$1" in
		-r | --repo)
			REPO_PATH="$2"
			shift 2
			;;
		-o | --output)
			OUTPUT_DIR="$2"
			shift 2
			;;
		-s | --submodules)
			INCLUDE_SUBMODULES=true
			shift
			;;
		--no-compress)
			NO_COMPRESS=true
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		--)
			shift
			break
			;;
		*)
			echo "Error: Unknown option: $1" >&2
			usage >&2
			exit 1
			;;
		esac
	done
}
validate_repo() {
	if [[ ! -d "$1/.git" ]] && ! git -C "$1" rev-parse --git-dir &>/dev/null; then
		echo "Error: Not a git repository: $1" >&2
		exit 1
	fi
}
validate_output_dir() {
	if [[ ! -d $OUTPUT_DIR ]]; then
		echo "Error: Output directory does not exist: $OUTPUT_DIR" >&2
		exit 1
	fi
}
get_repo_name() {
	local name
	name=$(git -C "$1" config --get remote.origin.url 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//' || true)
	[[ -z $name ]] && name=$(basename "$(cd "$1" && pwd)")
	echo "$name"
}
get_timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }
create_bundle() {
	git -C "$1" bundle create "$2" --all
	if [[ $INCLUDE_SUBMODULES == true ]]; then
		while IFS= read -r submodule_path; do
			[[ -z $submodule_path ]] && continue
			local sub_bundle="${2%.bundle}_$(basename "$submodule_path").bundle"
			git -C "$1/$submodule_path" bundle create "$sub_bundle" --all
		done < <(git -C "$1" config --file .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}' || true)
	fi
}
compress_bundle() {
	gzip -f "$1"
	echo "${1}.gz"
}
main() {
	parse_args "$@"
	REPO_PATH=$(cd "$REPO_PATH" && pwd)
	validate_repo "$REPO_PATH"
	validate_output_dir
	local repo_name=$(get_repo_name "$REPO_PATH")
	local timestamp=$(get_timestamp)
	local bundle_path="${OUTPUT_DIR}/${repo_name}_${timestamp}.bundle"
	echo "Creating bundle for: $repo_name"
	create_bundle "$REPO_PATH" "$bundle_path"
	[[ $NO_COMPRESS == false ]] && bundle_path=$(compress_bundle "$bundle_path")
	echo "Bundle created: $bundle_path"
}
main "$@"
