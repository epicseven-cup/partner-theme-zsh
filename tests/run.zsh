#!/usr/bin/env zsh
# Test suite for partner-theme. Run from anywhere: zsh tests/run.zsh
emulate -L zsh
setopt err_return no_unset 2>/dev/null; unsetopt err_return no_unset

root=${${(%):-%x}:A:h:h}
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

integer pass=0 fail=0
ok()   { (( pass++ )); print -P "  %F{green}✓%f $1" }
bad()  { (( fail++ )); print -P "  %F{red}✗%f $1\n      expected: $2\n      got:      $3" }
eq()   { [[ $2 == $3 ]] && ok $1 || bad $1 $3 $2 }          # eq <name> <actual> <expected>
match(){ [[ $2 == $~3 ]] && ok $1 || bad $1 "$3" $2 }        # match <name> <actual> <glob>

autoload -Uz vcs_info add-zsh-hook
setopt prompt_subst
_partner_root=$root
for f in $root/config/*.zsh $root/lib/{git,pet,prompt,partner}.zsh; do source $f; done

tmp=$(mktemp -d); trap 'rm -rf $tmp' EXIT

# commit <n> [message]: n empty commits in the current repo
commit() { local i; for (( i = 0; i < $1; i++ )); do git commit -q --allow-empty -m "${2:-c$i}"; done }
new_repo() { rm -rf $tmp/repo; git init -q -b main $tmp/repo; cd $tmp/repo; git config user.email t@example.com }
pet_stage() { vcs_info; _partner_pet; print $REPLY_STAGE }

print -P "%B== syntax ==%b"
for f in $root/partner-theme.zsh-theme $root/config/*.zsh $root/lib/*.zsh $root/tests/run.zsh; do
  zsh -n $f 2>/dev/null && ok "${f#$root/} parses" || bad "${f#$root/} parses" "no syntax errors" "syntax error"
done

print -P "%B== config ==%b"
eq "default levels"    "$PARTNER_LEVELS"  "1 5 15 30"
eq "default fire at"   "$PARTNER_FIRE_AT" "6"
eq "bar glyph full"    "$PARTNER_BAR_FULL"  "█"
eq "bar glyph empty"   "$PARTNER_BAR_EMPTY" "░"
for s in EGG BABY CLASS GRAND LEGEND NONE; do
  [[ -n ${PARTNER_STAGE_COLORS[$s]} ]] && ok "stage colour $s set" || bad "stage colour $s set" "a colour code" "empty"
done
for a in ANIMALS CLASSES RANKS TITLES; do
  (( ${#${(P)${:-PARTNER_$a}}} > 0 )) && ok "PARTNER_$a not empty" || bad "PARTNER_$a not empty" ">0 entries" "0"
done

print -P "%B== bar ==%b"
eq "bar 0/4" "$(_partner_bar 0)" "░░░░"
eq "bar 2/4" "$(_partner_bar 2)" "██░░"
eq "bar 4/4" "$(_partner_bar 4)" "████"

print -P "%B== pick ==%b"
a=$(_partner_pick "k" 10); b=$(_partner_pick "k" 10)
eq "pick is deterministic" $a $b
ok_range=1; for k in a b c d e f g; do p=$(_partner_pick $k 5); (( p >= 1 && p <= 5 )) || ok_range=0; done
(( ok_range )) && ok "pick stays within 1..n" || bad "pick stays within 1..n" "1..5" "out of range"

print -P "%B== evolution ==%b"
new_repo
eq "empty repo → EGG" "$(pet_stage)" "EGG"
commit 1;  eq "1 commit  → BABY"   "$(pet_stage)" "BABY"
commit 4;  eq "5 commits → CLASS"  "$(pet_stage)" "CLASS"
commit 10; eq "15 commits → GRAND" "$(pet_stage)" "GRAND"
commit 15; eq "30 commits → LEGEND" "$(pet_stage)" "LEGEND"
vcs_info; _partner_pet
eq "legend bar is full" "$REPLY_BAR" "████"
eq "legend has no next level" "$REPLY_NEXT" ""

print -P "%B== counting (branch scope) ==%b"
PARTNER_SCOPE=branch
new_repo; commit 3
git checkout -q -b feature; commit 2
eq "feature branch counts only commits since branch-off" "$(_partner_branch_count)" "2"
git checkout -q main; commit 1
git checkout -q feature; git merge -q --no-edit main
eq "merging main in does not change the count" "$(_partner_branch_count)" "2"
git checkout -q main
eq "default branch counts all your commits" "$(_partner_branch_count)" "4"
git checkout -q --detach
_partner_branch_count >/dev/null && bad "detached HEAD returns failure" "exit 1" "exit 0" || ok "detached HEAD returns failure"
git checkout -q main
git config user.email other@example.com
eq "only your commits count" "$(_partner_branch_count)" "0"

PARTNER_SCOPE=project

print -P "%B== project scope ==%b"
eq "default scope is project" "$PARTNER_SCOPE" "project"
new_repo; commit 2
git checkout -q -b feature; commit 2
eq "project count spans all branches" "$(_partner_project_count)" "4"
vcs_info; _partner_pet; proj=$REPLY_FULL
git checkout -q main; vcs_info; _partner_pet
eq "same pet on every branch" "$REPLY_FULL" "$proj"
git checkout -q --detach; vcs_info; _partner_pet
eq "pet still shown on detached HEAD" "$REPLY_STAGE" "BABY"
git checkout -q main
partner reroll >/dev/null
eq "project reroll bumps partner.seed" "$(git config --get partner.seed)" "1"
git config user.email other@example.com
eq "project count only counts your commits" "$(_partner_project_count)" "0"
PARTNER_SCOPE=branch
git checkout -q feature; git config user.email t@example.com
eq "branch scope: pet is per branch" "$(vcs_info; _partner_pet; print $REPLY_COUNT)" "2"
PARTNER_SCOPE=project

print -P "%B== fire ==%b"
new_repo; commit 5; vcs_info; _partner_pet
eq "5 commits today: not on fire" "$REPLY_FIRE" ""
commit 1; vcs_info; _partner_pet
eq "6 commits today: on fire" "$REPLY_FIRE" "1"

print -P "%B== uncommitted and unpushed ==%b"
new_repo; print "1\n2\n3" > f.txt; git add f.txt; git commit -q -m f
_partner_git_counts
eq "clean repo: 0 added"               "$REPLY_ADDED"    "0"
eq "clean repo: 0 deleted"             "$REPLY_DELETED"  "0"
eq "no origin: unpushed is empty"      "$REPLY_UNPUSHED" ""
git init -q --bare -b main $tmp/origin.git
git remote add origin $tmp/origin.git; git push -q origin main; git fetch -q
_partner_git_counts
eq "pushed: unpushed is 0"             "$REPLY_UNPUSHED" "0"
commit 2
_partner_git_counts
eq "2 local commits: unpushed is 2"    "$REPLY_UNPUSHED" "2"
git checkout -q -b topic; commit 1
_partner_git_counts
eq "new branch counts commits not on origin" "$REPLY_UNPUSHED" "3"
print "1\nX\n3\n4\n5" > f.txt        # -1 +3 (unstaged)
print "a\nb" > g.txt; git add g.txt     # +2 (staged)
print untracked > u.txt                # not counted
_partner_git_counts
eq "added lines (staged + unstaged)"   "$REPLY_ADDED"   "5"
eq "deleted lines"                     "$REPLY_DELETED" "1"
_partner_precmd >/dev/null; match "folder line shows +/- and ↑" "${PROMPT##*$'\n'}" "*+5*-1*↑3*"
match "pet line has no git status" "${PROMPT%%$'\n'*}" "*commit*"; [[ ${PROMPT%%$'\n'*} == *+5* ]] && bad "pet line has no git status" "no +5" "${PROMPT%%$'\n'*}"
git add -A; git commit -q -m x; git push -q origin topic
_partner_precmd >/dev/null; [[ ${PROMPT##*$'\n'} == *[+↑↓⟳]* ]] && bad "counts hidden when zero" "no status" "$PROMPT" || ok "counts hidden when zero"

print -P "%B== needs rebase ==%b"
new_repo; commit 2
git checkout -q -b topic; commit 1 topic-work
_partner_behind_default; eq "up to date with main: no notice" "$REPLY_BEHIND" ""
git checkout -q main; commit 2 main-work; git checkout -q topic
_partner_behind_default
eq "behind main by 2" "$REPLY_BEHIND" "2"
eq "names the default branch" "$REPLY_BEHIND_NAME" "main"
_partner_precmd >/dev/null; match "prompt shows rebase notice" "${PROMPT##*$'\n'}" "*rebase \(2 behind main\)*"
git rebase -q main; _partner_behind_default
eq "after rebase: no notice" "$REPLY_BEHIND" ""
git checkout -q main; _partner_behind_default
eq "on the default branch: no notice" "$REPLY_BEHIND" ""

print -P "%B== upstream behind ==%b"
new_repo; commit 2
git init -q --bare -b main $tmp/up.git; git remote add origin $tmp/up.git; git push -q -u origin main
_partner_git_counts; eq "in sync: 0 to pull" "$REPLY_UPSTREAM_BEHIND" "0"
git clone -q $tmp/up.git $tmp/other; git -C $tmp/other -c user.email=o@x.com -c user.name=o commit -q --allow-empty -m remote-work; git -C $tmp/other push -q origin main
git fetch -q; _partner_git_counts
eq "1 commit upstream: 1 to pull" "$REPLY_UPSTREAM_BEHIND" "1"
_partner_precmd >/dev/null; match "prompt shows ↓ behind upstream" "${PROMPT##*$'\n'}" "*↓1*"
git checkout -q -b local-only; _partner_git_counts
eq "no upstream: empty" "$REPLY_UPSTREAM_BEHIND" ""
rm -rf $tmp/other

print -P "%B== hatch and evolve messages ==%b"
new_repo
vcs_info; _partner_pet; out=$(_partner_announce)
eq "first sighting is silent" "$out" ""
eq "stage is recorded" "$(git config --get partner.stage)" "EGG"
commit 1; vcs_info; _partner_pet; out=$(_partner_announce)
match "egg hatching is announced" "$out" "*egg hatched*"
vcs_info; _partner_pet; out=$(_partner_announce)
eq "announced only once" "$out" ""
commit 4; vcs_info; _partner_pet; out=$(_partner_announce)
match "evolving is announced" "$out" "*evolved*"
git config partner.stage LEGEND; vcs_info; _partner_pet; out=$(_partner_announce)
eq "going down a stage is silent" "$out" ""
eq "…and the new stage is recorded" "$(git config --get partner.stage)" "CLASS"
PARTNER_SCOPE=branch
new_repo; commit 1; vcs_info; _partner_pet
eq "branch scope keeps the stage per branch" "$REPLY_STAGE_KEY" "partner.main.stage"
PARTNER_SCOPE=project
new_repo; vcs_info; _partner_pet
_partner_precmd >/dev/null; match "egg shows commits to hatch" "${PROMPT%%$'\n'*}" "*0/1 to hatch*"

print -P "%B== reroll (branch scope) ==%b"
PARTNER_SCOPE=branch
new_repo; commit 1
vcs_info; _partner_pet; before=$REPLY_FULL
eq "pet is stable between calls" "$(vcs_info; _partner_pet; print $REPLY_FULL)" "$before"
partner reroll >/dev/null
eq "reroll bumps the seed" "$(git config --get partner.main.seed)" "1"

PARTNER_SCOPE=project

print -P "%B== pet stays the same ==%b"
# the pet as a brand-new shell would show it (no cache, nothing carried over)
fresh_pet() {
  zsh -f -c '
    autoload -Uz vcs_info add-zsh-hook; setopt prompt_subst
    _partner_root=$1; PARTNER_SCOPE=$2
    for f in $1/config/*.zsh $1/lib/{git,pet,prompt,partner}.zsh; do source $f; done
    vcs_info; _partner_pet; print -r -- $REPLY_FULL' _ $root ${1:-project} 2>/dev/null
}
PARTNER_SCOPE=project
new_repo; commit 1; vcs_info; _partner_pet; first=$REPLY_FULL
eq "same pet in a new session"           "$(fresh_pet)" "$first"
eq "same pet after the cache is cleared" "$(_PARTNER_PET_CACHE=(); vcs_info; _partner_pet; print -r -- $REPLY_FULL)" "$first"
commit 30
eq "same pet after evolving"             "$(fresh_pet)" "$first"
git checkout -q -b feature/x; commit 1
eq "same pet on another branch"          "$(fresh_pet)" "$first"
git checkout -q main
eq "same pet after switching back"       "$(fresh_pet)" "$first"
mkdir -p sub; cd sub
eq "same pet from a subdirectory"        "$(fresh_pet)" "$first"
cd ..
# the pick only depends on the repo's folder name and seed; pin one so list edits are caught
eq "animal list size is pinned"          "${#PARTNER_ANIMALS}" "15"
eq "animal for a known key is pinned"    "${PARTNER_ANIMALS[$(_partner_pick "pinned::0:animal" ${#PARTNER_ANIMALS})]}" "Turtle"

PARTNER_SCOPE=branch
new_repo; commit 1; vcs_info; _partner_pet; first=$REPLY_FULL
eq "branch scope: same pet in a new session" "$(fresh_pet branch)" "$first"
git checkout -q -b other; commit 1
git checkout -q main
eq "branch scope: switching back restores the pet" "$(fresh_pet branch)" "$first"
PARTNER_SCOPE=project

print -P "%B== variety ==%b"
typeset -A seen_animals
for n in {1..40}; do seen_animals[$(_partner_pick "repo$n::0:animal" ${#PARTNER_ANIMALS})]=1; done
(( ${#seen_animals} >= 5 )) && ok "different repos get a spread of animals" || bad "different repos get a spread of animals" ">=5 distinct" "${#seen_animals}"
eq "a different name can get a different key" "$([[ $(_partner_pick a:animal 1000) != $(_partner_pick b:animal 1000) ]] && print yes)" "yes"
eq "animal, class, rank and title are picked independently" \
  "$([[ $(_partner_pick k:animal 1000) != $(_partner_pick k:class 1000) || $(_partner_pick k:class 1000) != $(_partner_pick k:rank 1000) ]] && print yes)" "yes"
new_repo; commit 1; vcs_info; _partner_pet; before=$REPLY_FULL
for i in {1..6}; do partner reroll >/dev/null; vcs_info; _partner_pet; [[ $REPLY_FULL != $before ]] && changed=1; done
eq "rerolling eventually gives a different pet" "${changed:-0}" "1"
eq "pet is stable after the last reroll" "$(fresh_pet)" "$REPLY_FULL"
git config --unset partner.seed; vcs_info; _partner_pet
eq "removing partner.seed restores the original pet" "$REPLY_FULL" "$before"
rm -rf $tmp/folder-a $tmp/folder-b
git init -q -b main $tmp/folder-a; git init -q -b main $tmp/folder-b
eq "pet follows the folder name, not the path" \
  "$(cd $tmp/folder-a; fresh_pet)" "$(mkdir -p $tmp/x; git init -q -b main $tmp/x/folder-a; cd $tmp/x/folder-a; fresh_pet)"
rm -rf $tmp/x

print -P "%B== prompt ==%b"
cd $tmp; _partner_precmd >/dev/null
eq "outside a repo: one-line prompt"  "$([[ $PROMPT == *$'\n'* ]] && print multi)" ""
eq "outside a repo: no pet badge"     "$([[ $PROMPT == *'◆'* ]] && print pet)" ""
new_repo; commit 1
false; _partner_precmd >/dev/null
match "failed command shows the exit code" "$PROMPT" "*✖ 1*"
true; _partner_precmd >/dev/null
eq "success shows no error badge"     "$([[ $PROMPT == *✖* ]] && print err)" ""
print x > new.txt; _partner_precmd >/dev/null
match "untracked file marks the branch with ?" "$PROMPT" "*main?*"
git add new.txt; _partner_precmd >/dev/null
match "staged file marks the branch with +" "$PROMPT" "*main+*"
git commit -q -m n; _partner_precmd >/dev/null
eq "clean branch has no marker"       "$([[ $PROMPT == *main[*+?]* ]] && print dirty)" ""
git checkout -q --detach
PARTNER_SCOPE=branch; _partner_precmd >/dev/null
eq "branch scope + detached HEAD: no pet" "$([[ $PROMPT == *'◆'* ]] && print pet)" ""
PARTNER_SCOPE=project; git checkout -q main

print -P "%B== fire badge ==%b"
new_repo; commit 6; _partner_precmd >/dev/null
match "on fire: badge uses the ember background" "$PROMPT" "*%K{$PARTNER_FIRE_BG}*"
new_repo; commit 2; _partner_precmd >/dev/null
eq "not on fire: no ember background" "$([[ $PROMPT == *%K{$PARTNER_FIRE_BG}* ]] && print fire)" ""

print -P "%B== settings overrides ==%b"
old_levels=($PARTNER_LEVELS)
PARTNER_LEVELS=(2 4 6 8); new_repo; commit 1
eq "custom levels: 1 commit is still an egg" "$(pet_stage)" "EGG"
commit 1; eq "custom levels: 2 commits hatch"  "$(pet_stage)" "BABY"
commit 6; eq "custom levels: 8 commits → LEGEND" "$(pet_stage)" "LEGEND"
PARTNER_LEVELS=($old_levels)
old_fire=$PARTNER_FIRE_AT; PARTNER_FIRE_AT=2; new_repo; commit 2; vcs_info; _partner_pet
eq "custom fire threshold" "$REPLY_FIRE" "1"
PARTNER_FIRE_AT=$old_fire
old_icon=$PARTNER_REBASE_ICON; PARTNER_REBASE_ICON='R!'
new_repo; commit 1; git checkout -q -b t; git checkout -q main; commit 1; git checkout -q t; git remote add origin $tmp/origin.git 2>/dev/null
git update-ref refs/remotes/origin/main main; git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
_partner_precmd >/dev/null; match "custom rebase icon is used" "$PROMPT" "*R!*"
PARTNER_REBASE_ICON=$old_icon

print -P "%B== partner status ==%b"
new_repo; commit 1
out=$(partner status 2>&1)
match "status names the pet"            "$out" "*◆*"
match "status shows the commit count"   "$out" "*1 commit*"
match "status says how it was counted"  "$out" "*all your commits in this repo*"
match "status shows commits today"      "$out" "*1 commit* today*"
match "status shows the next evolution" "$out" "*evolves in 4 more*"
eq "today is an alias of status" "$(partner today 2>&1)" "$out"
eq "pet is an alias of status"   "$(partner pet 2>&1)" "$out"
new_repo; match "an egg says when it hatches" "$(partner status 2>&1)" "*hatches after 1 commit*"
new_repo; commit 30; match "a legend is fully evolved" "$(partner status 2>&1)" "*fully evolved*"
PARTNER_SCOPE=branch; new_repo; commit 1
match "branch scope status names the branch" "$(partner status 2>&1)" "*main*"
git checkout -q --detach; match "branch scope status on detached HEAD" "$(partner status 2>&1)" "*detached HEAD*"
PARTNER_SCOPE=project; git checkout -q main
new_repo; commit 1; before=$REPLY_FULL
match "reroll announces the new pet" "$(partner reroll 2>&1)" "*now raises*"
cd $tmp; match "reroll outside a repo is handled" "$(partner reroll 2>&1)" "*not in a git repo*"

print -P "%B== update ==%b"
rm -rf $tmp/theme-src $tmp/theme-live
git init -q -b main $tmp/theme-src; git -C $tmp/theme-src -c user.email=a@b -c user.name=a commit -q --allow-empty -m v1
git clone -q $tmp/theme-src $tmp/theme-live
saved_root=$_partner_root; _partner_root=$tmp/theme-live
out=$(partner update 2>&1); match "update when current says so" "$out" "*up to date*"
git -C $tmp/theme-src -c user.email=a@b -c user.name=a commit -q --allow-empty -m v2
out=$(partner update 2>&1); match "update pulls new commits"     "$out" "*exec zsh*"
eq "update recorded in last-update stamp" "$([[ -f $tmp/theme-live/.git/last-update ]] && print yes)" "yes"
print x > $tmp/theme-live/local.txt; git -C $tmp/theme-live add local.txt; git -C $tmp/theme-live -c user.email=a@b -c user.name=a commit -q -m local
git -C $tmp/theme-src -c user.email=a@b -c user.name=a commit -q --allow-empty -m v3
out=$(partner update 2>&1); match "diverged update fails and points to reset" "$out" "*update failed*reset*"
_partner_root=$saved_root; rm -rf $tmp/theme-src $tmp/theme-live

print -P "%B== command ==%b"
match "partner with no args prints usage" "$(partner 2>&1)" "usage: partner*"
match "usage lists update and reset"      "$(partner 2>&1)" "*update*reset*"
cd $tmp; match "status outside a repo is handled" "$(partner status 2>&1)" "not in a git repo"

print
print -P "%B$pass passed, $fail failed%b"
(( fail == 0 ))
