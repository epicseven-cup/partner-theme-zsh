# Pet generation: stable per-project (or per-branch) pick + evolution stage.

# Stable pseudo-random index 1..$2 for a string key.
_partner_pick() { local s=$(print -rn -- "$1" | cksum); local -i h=${s%% *}; print $(( h % $2 + 1 )) }

# Per-branch reroll counter, stored in the repo: git config partner.<branch>.seed
# In project scope the counter is the repo-wide git config partner.seed instead.
_partner_seed() { git config --get "partner.$1.seed" 2>/dev/null || print 0 }

# Progress bar with $1 of 4 cells filled, using PARTNER_BAR_FULL / PARTNER_BAR_EMPTY.
_partner_bar() { print -rn -- "${(pl:$1::$PARTNER_BAR_FULL:)}${(pl:$((4-$1))::$PARTNER_BAR_EMPTY:)}" }

typeset -gA _PARTNER_STAGE_RANK=(EGG 0 BABY 1 CLASS 2 GRAND 3 LEGEND 4)

# Prints a one-off message when the pet reaches a new stage. The last stage seen
# is kept in git config (partner.stage, or partner.<branch>.stage in branch scope),
# so it shows once per evolution, however many terminals are open. The first time
# a repo is seen it's recorded silently, so existing pets don't announce themselves.
_partner_announce() {
  [[ -n $REPLY_STAGE && -n $REPLY_STAGE_KEY ]] || return 0
  local seen=$(git config --get "$REPLY_STAGE_KEY" 2>/dev/null)
  [[ $seen == $REPLY_STAGE ]] && return 0
  git config "$REPLY_STAGE_KEY" $REPLY_STAGE 2>/dev/null
  [[ -n $seen ]] || return 0
  (( _PARTNER_STAGE_RANK[$REPLY_STAGE] > ${_PARTNER_STAGE_RANK[$seen]:-99} )) || return 0
  local c=${PARTNER_STAGE_COLORS[$REPLY_STAGE]}
  if [[ $seen == EGG ]]; then
    print -P "%F{$c}◆%f your egg hatched: %B${REPLY_NAME}%b!"
  else
    print -P "%F{$c}◆%f your pet evolved: %B${REPLY_NAME}%b!"
  fi
}

typeset -gA _PARTNER_PET_CACHE

# Builds the pet for this repo (or repo + branch, with PARTNER_SCOPE=branch). Sets:
#   REPLY_STAGE  EGG | BABY | CLASS | GRAND | LEGEND  (empty = no pet shown)
#   REPLY_NAME   e.g. "Grand Wizard Cat"
#   REPLY_FULL   name incl. final-form title, even before it's earned
#   REPLY_BAR    ██░░           REPLY_COUNT your commits (project or branch)
#   REPLY_NEXT   commits needed for the next evolution (empty at max)
#   REPLY_FIRE   1 when you've committed PARTNER_FIRE_AT+ times today
_partner_pet() {
  REPLY_STAGE_KEY= REPLY_STAGE= REPLY_NAME= REPLY_FULL= REPLY_BAR= REPLY_COUNT= REPLY_NEXT= REPLY_FIRE=
  [[ -n $vcs_info_msg_0_ ]] || return
  local -i today=$(_partner_count_lines "$(_partner_commits_today)")
  (( today >= PARTNER_FIRE_AT )) && REPLY_FIRE=1
  local branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
  local repo=$(git rev-parse --show-toplevel 2>/dev/null) key
  if [[ $PARTNER_SCOPE == branch ]]; then
    [[ -n $branch ]] || return
    key="${repo:t}:${branch}:$(_partner_seed $branch)"
    REPLY_STAGE_KEY="partner.${branch}.stage"
  else
    key="${repo:t}::$(git config --get partner.seed 2>/dev/null || print 0)"
    REPLY_STAGE_KEY="partner.stage"
  fi
  local -i n; n=$(_partner_count) || return
  REPLY_COUNT=$n

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
