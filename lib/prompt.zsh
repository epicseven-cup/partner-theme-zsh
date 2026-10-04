# Prompt rendering.

# Prints the coloured badge for text $1 in stage colour $2 (embers if on fire).
_partner_badge() {
  local text=$1 c=$2 fg=${3:-232}
  if [[ -n $REPLY_FIRE ]]; then
    print -rn -- "%K{$PARTNER_FIRE_BG}%F{$c}%B ${text} %b%f%k%F{$PARTNER_FIRE_BG}▌%f"
  else
    print -rn -- "%K{$c}%F{$fg}%B ${text} %b%f%k%F{$c}▌%f"
  fi
}

# ── GLOW ── bold colour blocks, no special font needed
_partner_precmd() {
  local -i code=$?
  vcs_info
  _partner_pet
  local lc=${PARTNER_STAGE_COLORS[${REPLY_STAGE:-NONE}]:-208}

  # Line 1: the pet, its progress bar and commit count (only inside a repo)
  local top=""
  if [[ -n $REPLY_STAGE ]]; then
    _partner_announce
    local progress="${REPLY_COUNT} commit${${REPLY_COUNT:#1}:+s}"
    [[ $REPLY_STAGE == EGG ]] && progress="${REPLY_COUNT}/${REPLY_NEXT} to hatch"
    top="$(_partner_badge "◆ ${REPLY_NAME}" $lc) %F{$lc}${REPLY_BAR}%f %F{240}${progress}%f"$'\n'
  fi

  # Line 2: error (if any), path, git, prompt arrow
  local err=""
  if (( code )); then
    err="%K{160}%F{231}%B ✖ ${code} %b%f%k%F{160}▌%f"; lc=160
  fi
  local path_seg="%K{25}%F{231} %3~ %f%k%F{25}▌%f"
  local git_seg=""
  if [[ -n $vcs_info_msg_0_ ]]; then
    local gc=35; [[ $vcs_info_msg_0_ == *[*+?]* ]] && gc=178
    git_seg="%K{$gc}%F{232} ⎇ ${vcs_info_msg_0_} %f%k%F{$gc}▌%f"
    # What changed: lines added/removed, commits to push/pull, and a rebase notice
    _partner_git_counts
    _partner_behind_default
    local st=""
    (( REPLY_ADDED > 0 )) && st+=" %F{71}+${REPLY_ADDED}%f"
    (( REPLY_DELETED > 0 )) && st+=" %F{167}-${REPLY_DELETED}%f"
    (( REPLY_UNPUSHED > 0 )) && st+=" %F{214}↑${REPLY_UNPUSHED}%f"
    (( REPLY_UPSTREAM_BEHIND > 0 )) && st+=" %F{214}↓${REPLY_UPSTREAM_BEHIND}%f"
    [[ -n $REPLY_BEHIND ]] && st+=" %F{214}${PARTNER_REBASE_ICON} rebase (${REPLY_BEHIND} behind ${REPLY_BEHIND_NAME})%f"
    git_seg+=$st
  fi
  PROMPT="${top}${err}${path_seg}${git_seg} %F{$lc}❯%f "
  RPROMPT=""
}

add-zsh-hook precmd _partner_precmd
