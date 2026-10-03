# Prompt rendering.

# Prints the coloured badge for text $1 in stage colour $2 (embers if on fire).
_digi_badge() {
  local text=$1 c=$2 fg=${3:-232}
  if [[ -n $REPLY_FIRE ]]; then
    print -rn -- "%K{$DIGI_FIRE_BG}%F{$c}%B ${text} %b%f%k%F{$DIGI_FIRE_BG}▌%f"
  else
    print -rn -- "%K{$c}%F{$fg}%B ${text} %b%f%k%F{$c}▌%f"
  fi
}

# ── GLOW ── bold colour blocks, no special font needed
_digi_precmd() {
  local -i code=$?
  vcs_info
  _digi_pet
  local lc=${DIGI_STAGE_COLORS[${REPLY_STAGE:-NONE}]:-208}

  # Line 1: the pet, with its progress bar (only inside a repo, on a branch)
  local top=""
  if [[ -n $REPLY_STAGE ]]; then
    top="$(_digi_badge "◆ ${REPLY_NAME}" $lc) %F{$lc}${REPLY_BAR}%f %F{240}${REPLY_COUNT} commit${${REPLY_COUNT:#1}:+s}%f"$'\n'
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
  fi
  PROMPT="${top}${err}${path_seg}${git_seg} %F{$lc}❯%f "
  RPROMPT=""
}

add-zsh-hook precmd _digi_precmd
