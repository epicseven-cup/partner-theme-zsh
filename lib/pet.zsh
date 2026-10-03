# Pet generation: stable per-branch pick + evolution stage.

# Stable pseudo-random index 1..$2 for a string key.
_partner_pick() { local s=$(print -rn -- "$1" | cksum); local -i h=${s%% *}; print $(( h % $2 + 1 )) }

# Per-branch reroll counter, stored in the repo: git config partner.<branch>.seed
# Falls back to the old digivice.<branch>.seed key so existing pets don't change.
_partner_seed() { git config --get "partner.$1.seed" 2>/dev/null || git config --get "digivice.$1.seed" 2>/dev/null || print 0 }

# Builds the pet for this repo + branch. Sets:
#   REPLY_STAGE  EGG | BABY | CLASS | GRAND | LEGEND  (empty = no pet shown)
#   REPLY_NAME   e.g. "Grand Wizard Cat"
#   REPLY_FULL   name incl. final-form title, even before it's earned
#   REPLY_BAR    ██░░           REPLY_COUNT your commits on the branch
#   REPLY_NEXT   commits needed for the next evolution (empty at max)
#   REPLY_FIRE   1 when you've committed PARTNER_FIRE_AT+ times today
# Progress bar with $1 of 4 cells filled, using PARTNER_BAR_FULL / PARTNER_BAR_EMPTY.
_partner_bar() { print -rn -- "${(pl:$1::$PARTNER_BAR_FULL:)}${(pl:$((4-$1))::$PARTNER_BAR_EMPTY:)}" }

typeset -gA _PARTNER_PET_CACHE
_partner_pet() {
  REPLY_STAGE= REPLY_NAME= REPLY_FULL= REPLY_BAR= REPLY_COUNT= REPLY_NEXT= REPLY_FIRE=
  [[ -n $vcs_info_msg_0_ ]] || return
  local -i today=$(_partner_count_lines "$(_partner_commits_today)")
  (( today >= PARTNER_FIRE_AT )) && REPLY_FIRE=1
  local branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
  [[ -n $branch ]] || return
  local -i n; n=$(_partner_branch_count) || return
  REPLY_COUNT=$n

  local repo=$(git rev-parse --show-toplevel 2>/dev/null)
  local key="${repo:t}:${branch}:$(_partner_seed $branch)"
  local pet=${_PARTNER_PET_CACHE[$key]}
  if [[ -z $pet ]]; then
    pet="${PARTNER_ANIMALS[$(_partner_pick "$key:animal" ${#PARTNER_ANIMALS})]}|${PARTNER_CLASSES[$(_partner_pick "$key:class" ${#PARTNER_CLASSES})]}|${PARTNER_RANKS[$(_partner_pick "$key:rank" ${#PARTNER_RANKS})]}|${PARTNER_TITLES[$(_partner_pick "$key:title" ${#PARTNER_TITLES})]}"
    _PARTNER_PET_CACHE[$key]=$pet
  fi
  local -a p=("${(@s:|:)pet}")
  local animal=${p[1]} cls=${p[2]} rank=${p[3]} title=${p[4]}
  REPLY_FULL="$rank $cls $animal $title"

  if   (( n >= PARTNER_LEVELS[4] )); then
    REPLY_STAGE=LEGEND REPLY_NAME="$rank $cls $animal $title" REPLY_BAR=$(_partner_bar 4)
  elif (( n >= PARTNER_LEVELS[3] )); then
    REPLY_STAGE=GRAND  REPLY_NAME="$rank $cls $animal"        REPLY_BAR=$(_partner_bar 3) REPLY_NEXT=$PARTNER_LEVELS[4]
  elif (( n >= PARTNER_LEVELS[2] )); then
    REPLY_STAGE=CLASS  REPLY_NAME="$cls $animal"              REPLY_BAR=$(_partner_bar 2) REPLY_NEXT=$PARTNER_LEVELS[3]
  elif (( n >= PARTNER_LEVELS[1] )); then
    REPLY_STAGE=BABY   REPLY_NAME="$animal"                   REPLY_BAR=$(_partner_bar 1) REPLY_NEXT=$PARTNER_LEVELS[2]
  else
    REPLY_STAGE=EGG    REPLY_NAME="Egg"                       REPLY_BAR=$(_partner_bar 0) REPLY_NEXT=$PARTNER_LEVELS[1]
  fi
}
