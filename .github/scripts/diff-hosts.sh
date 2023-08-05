#!/usr/bin/env bash

# host_exists(flake, host)
# Checks if ${flake}#nixosConfigurations.$host
# Returns 0 if it does, 1 if it does not
function host_exists() {
    local cmd="nix eval $1#nixosConfigurations --apply 'builtins.hasAttr \"$2\"'"
    # echo "$cmd"
    has_host=$(eval "$cmd")
    if [[ $has_host == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# get_hosts(flake, available_hosts)
# Store a list of all available hosts in flake to $available_hosts
function get_hosts() {
    local -n hosts=$2
    IFS=" " read -r -a hosts <<< "$(nix eval $1#nixosConfigurations --raw --apply 'x: builtins.concatStringsSep " " (builtins.attrNames x)')"
}

set -o errexit
# When using to check local changes, the step summary is not needed
step_summary="${GITHUB_STEP_SUMMARY-/dev/null}"

before_ref="${GITHUB_BASE_REF-main}"
before_ref="origin/${before_ref/#refs\/heads\//}"
if [[ $GITHUB_REF == "target/refs/main" ]]; then
    # If triggered on main, compare with the previous commit
    before_ref="$(git log  HEAD~1 -1 --format=format:"%H")"
fi

before_rev="$(git rev-parse "$before_ref")"
before_rev_abbr="$before_ref"
before_flake="git+file:.?ref=${before_rev}"

after_rev="$(git rev-parse --verify HEAD)"
after_rev_abbr="$(git rev-parse --abbrev-ref HEAD)"
if [[ -z $(git status --short) ]]; then
    # If the working tree is clean, we can use the latest commit hash directly
    # and thus profit from even more reduced build times
    after_flake="git+file:.?ref=${after_rev}"
else
    # That way the script can be used to check local (non commited) changes
    after_flake="."
fi

before_hosts=()
get_hosts "$before_flake" before_hosts
after_hosts=()
get_hosts "$after_flake" after_hosts
all_hosts=( "${before_hosts[@]}" "${after_hosts[@]}" )

# Unite both arrays
# From https://stackoverflow.com/a/33153989
declare -A _all_hosts
for k in "${all_hosts[@]}"; do _all_hosts["$k"]=1; done
all_hosts=("${!_all_hosts[@]}")

echo -e "## Closure differences\n" >> "$step_summary"
dirty=""
if [[ -n $(git status --short) ]]; then
    dirty="-DIRTY"
fi
echo -e "_Comparing prior $before_rev_abbr ([$before_rev]) with current $after_rev_abbr ([$after_rev]$dirty)_\n" | tee -a "$step_summary"
repo_url="${GITHUB_SERVER_URL}/$GITHUB_REPOSITORY"
{
    echo "[$before_rev]: $repo_url/commit/$before_rev";
    echo "[$after_rev]: $repo_url/commit/$after_rev";
} >> "$step_summary"


for host in "${all_hosts[@]}"; do
    host_exists "$before_flake" "$host" && a_exists=true || a_exists=false
    host_exists "$after_flake" "$host" && b_exists=true || b_exists=false
    if $a_exists && ! $b_exists; then
        echo -e "**${host}** was removed\n" | tee -a "$step_summary"
    elif ! $a_exists && $b_exists; then
        echo -e "**${host}** was added\n" | tee -a "$step_summary"
    else
        echo "::group::Diff-closures for ${host}"
        drv="nixosConfigurations.$host.config.system.build.toplevel"
        diff_cmd="nix store diff-closures ${before_flake}#${drv} ${after_flake}#${drv}"
        # Initially build host so that we don't spam the log
        change_lines=$($diff_cmd 2>&1 | wc -l)
        # Run once so that we have the colorful output in the github actions log
        $diff_cmd && build_ok=true || build_ok=false
        if [[ $change_lines -gt 0 ]] || [[ ! $build_ok ]]; then
            if $build_ok; then
                echo "ok"
                echo "${host} changed"
                echo -e "<details>\n<summary><b>${host}</b> changed</summary>\n\n" >> "$step_summary"
            else
                echo "${host} failed to build"
                echo -e "<details>\n<summary><b>${host}</b> failed to build</summary>\n\n" >> "$step_summary"
            fi

            {
                echo '```';
                $diff_cmd --show-trace | sed -e 's/\x1b\[[0-9;]*m//g';
                echo '```';
                echo -e "\n</details>\n";
            } >> "$step_summary" 2>&1
        else
            echo -e "**${host}** has not changed\n" | tee -a "$step_summary"
        fi

        echo "::endgroup::"
    fi
done
