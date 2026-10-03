# vcs_info setup and git history helpers.

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats '%b%u%c'
zstyle ':vcs_info:git:*' actionformats '%b|%a%u%c'
zstyle ':vcs_info:git*+set-message:*' hooks partner-untracked
+vi-partner-untracked() {
  [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]] &&
    [[ -n $(git ls-files --others --exclude-standard 2>/dev/null | head -1) ]] &&
    hook_com[unstaged]+='?'
}


# The repo's default branch as local + remote refs that exist, e.g. "main origin/main".
_partner_default_refs() {
  local -a refs
  local r=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  local name=${r#origin/}
  if [[ -z $name ]]; then
    for name in main master trunk; do
      git show-ref -q --verify "refs/heads/$name" && break
      name=
    done
  fi
  [[ -n $name ]] || return 1
  git show-ref -q --verify "refs/heads/$name" && refs+=("refs/heads/$name")
  [[ -n $r ]] && refs+=("refs/remotes/$r")
  print -r -- "$name ${refs[*]}"
}

# The commit a branch was created from, read from the oldest entry in its local
# reflog ("branch: Created from ..."). Empty if that entry is gone or the branch
# was rebased since (the start point is no longer in its history).
_partner_branch_start() {
  local hash msg
  git log -g --format='%H%x09%gs' "refs/heads/$1" 2>/dev/null | tail -1 | IFS=$'\t' read -r hash msg
  [[ $msg == 'branch: Created from'* ]] || return 1
  # a rebase moves the branch onto a new base, so the original start no longer applies
  git log -g --format='%gs' "refs/heads/$1" 2>/dev/null | grep -q '^rebase' && return 1
  git merge-base --is-ancestor "$hash" HEAD 2>/dev/null || return 1
  print -r -- $hash
}

# How PARTNER_BRANCH_SCOPE was decided, for `partner status`.
typeset -g PARTNER_BRANCH_SCOPE=

# Your commits on the current branch (merges excluded). Returns 1 on a detached HEAD.
#  - default branch: all your commits on it
#  - other branches: your commits since you branched off, following the branch's
#    own line only (so merging main in, or merging it into main, changes nothing)
#  - fallback when the branch-off point is unknown (reflog expired, or rebased):
#    your commits that aren't on the default branch
_partner_branch_count() {
  local branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
  [[ -n $branch ]] || return 1
  local me=$(git config user.email 2>/dev/null)
  local -a who=(); [[ -n $me ]] && who=(--fixed-strings "--author=<$me>")
  local -a d=(${=$(_partner_default_refs)})
  local start
  if (( ! ${#d} )) || [[ $branch == ${d[1]} ]]; then
    PARTNER_BRANCH_SCOPE="all your commits on ${branch}"
    git rev-list --count --no-merges $who HEAD 2>/dev/null || print 0
  elif start=$(_partner_branch_start $branch); then
    PARTNER_BRANCH_SCOPE="your commits since branching off at ${start:0:7}"
    git rev-list --count --no-merges --first-parent $who HEAD "^$start" 2>/dev/null || print 0
  else
    PARTNER_BRANCH_SCOPE="your commits not on ${d[1]} (rebased, or branch-off point unknown)"
    git rev-list --count --no-merges $who HEAD --not ${d[2,-1]} 2>/dev/null || print 0
  fi
}

# Prints "hash<TAB>message" for each commit made in this repo today (any branch),
# read from the local HEAD reflog. Counts new commits and cherry-picks; skips
# amends, merges, pulls, rebases and checkouts.
_partner_commits_today() {
  local today=$(date +%Y-%m-%d) ref hash msg
  git log -g --date=short --format='%gd%x09%h%x09%gs' HEAD 2>/dev/null |
  while IFS=$'\t' read -r ref hash msg; do
    [[ $ref == *"@{$today}" ]] || break     # reflog is newest-first; stop at yesterday
    case $msg in
      'commit: '*|'commit (initial): '*|'cherry-pick: '*) print -r -- "$hash	${msg#*: }" ;;
    esac
  done
}

_partner_count_lines() { local -a l; [[ -n $1 ]] && l=("${(@f)1}"); print ${#l} }
