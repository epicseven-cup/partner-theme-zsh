# Pet generation: stable per-branch pick + evolution stage.

# Stable pseudo-random index 1..$2 for a string key.
_digi_pick() { local s=$(print -rn -- "$1" | cksum); local -i h=${s%% *}; print $(( h % $2 + 1 )) }

# Per-branch reroll counter, stored in the repo: git config digivice.<branch>.seed
_digi_seed() { git config --get "digivice.$1.seed" 2>/dev/null || print 0 }

# Builds the pet for this repo + branch. Sets:
#   REPLY_STAGE  EGG | BABY | CLASS | GRAND | LEGEND  (empty = no pet shown)
#   REPLY_NAME   e.g. "Grand Wizard Cat"
#   REPLY_FULL   name incl. final-form title, even before it's earned
#   REPLY_BAR    ▰▰▱▱           REPLY_COUNT your commits on the branch
#   REPLY_NEXT   commits needed for the next evolution (empty at max)
#   REPLY_FIRE   1 when you've committed DIGI_FIRE_AT+ times today
typeset -gA _DIGI_PET_CACHE
_digi_pet() {
  REPLY_STAGE= REPLY_NAME= REPLY_FULL= REPLY_BAR= REPLY_COUNT= REPLY_NEXT= REPLY_FIRE=
  [[ -n $vcs_info_msg_0_ ]] || return
  local -i today=$(_digi_count_lines "$(_digi_commits_today)")
  (( today >= DIGI_FIRE_AT )) && REPLY_FIRE=1
  local branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
  [[ -n $branch ]] || return
  local -i n; n=$(_digi_branch_count) || return
  REPLY_COUNT=$n

  local repo=$(git rev-parse --show-toplevel 2>/dev/null)
  local key="${repo:t}:${branch}:$(_digi_seed $branch)"
  local pet=${_DIGI_PET_CACHE[$key]}
  if [[ -z $pet ]]; then
    pet="${DIGI_ANIMALS[$(_digi_pick "$key:animal" ${#DIGI_ANIMALS})]}|${DIGI_CLASSES[$(_digi_pick "$key:class" ${#DIGI_CLASSES})]}|${DIGI_RANKS[$(_digi_pick "$key:rank" ${#DIGI_RANKS})]}|${DIGI_TITLES[$(_digi_pick "$key:title" ${#DIGI_TITLES})]}"
    _DIGI_PET_CACHE[$key]=$pet
  fi
  local -a p=("${(@s:|:)pet}")
  local animal=${p[1]} cls=${p[2]} rank=${p[3]} title=${p[4]}
  REPLY_FULL="$rank $cls $animal $title"

  if   (( n >= DIGI_LEVELS[4] )); then
    REPLY_STAGE=LEGEND REPLY_NAME="$rank $cls $animal $title" REPLY_BAR='▰▰▰▰'
  elif (( n >= DIGI_LEVELS[3] )); then
    REPLY_STAGE=GRAND  REPLY_NAME="$rank $cls $animal"        REPLY_BAR='▰▰▰▱' REPLY_NEXT=$DIGI_LEVELS[4]
  elif (( n >= DIGI_LEVELS[2] )); then
    REPLY_STAGE=CLASS  REPLY_NAME="$cls $animal"              REPLY_BAR='▰▰▱▱' REPLY_NEXT=$DIGI_LEVELS[3]
  elif (( n >= DIGI_LEVELS[1] )); then
    REPLY_STAGE=BABY   REPLY_NAME="$animal"                   REPLY_BAR='▰▱▱▱' REPLY_NEXT=$DIGI_LEVELS[2]
  else
    REPLY_STAGE=EGG    REPLY_NAME="Egg"                       REPLY_BAR='▱▱▱▱' REPLY_NEXT=$DIGI_LEVELS[1]
  fi
}
