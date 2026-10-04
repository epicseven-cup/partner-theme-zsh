# The `partner` command.

partner() {
  case $1 in
    status|today|pet)
      git rev-parse --is-inside-work-tree &>/dev/null || { print "not in a git repo"; return 1 }
      local branch=$(git symbolic-ref --short -q HEAD)
      local where=${branch:-detached HEAD}
      [[ $PARTNER_SCOPE == branch ]] || { where=$(git rev-parse --show-toplevel); where=${where:t} }
      vcs_info; _partner_pet
      if [[ -n $REPLY_STAGE ]]; then
        local lc=${PARTNER_STAGE_COLORS[$REPLY_STAGE]}
        print -P "$(_partner_badge "◆ ${REPLY_NAME}" $lc) %F{240}(%f%F{214}${where}%f%F{240})%f"
        _partner_count >/dev/null
        print -P "  ${REPLY_BAR}  ${REPLY_COUNT} commit${${REPLY_COUNT:#1}:+s}  %F{240}(${PARTNER_BRANCH_SCOPE})%f"
        if [[ $REPLY_STAGE == EGG ]]; then
          print -P "  hatches after ${REPLY_NEXT} commit${${REPLY_NEXT:#1}:+s} ${${PARTNER_SCOPE:#branch}:+in this project}${${PARTNER_SCOPE:#project}:+on this branch}  %F{240}→ ???%f"
        elif [[ -n $REPLY_NEXT ]]; then
          print -P "  evolves in $(( REPLY_NEXT - REPLY_COUNT )) more  %F{240}→ final form: ${REPLY_FULL}%f"
        else
          print -P "  %F{$lc}fully evolved%f"
        fi
      else
        print "detached HEAD — no pet here (PARTNER_SCOPE=branch)"
      fi
      local -i t=$(_partner_count_lines "$(_partner_commits_today)")
      print -P "  ${t} commit${${t:#1}:+s} today in this repo  %F{240}(on fire at ${PARTNER_FIRE_AT})%f"
      ;;
    reroll)
      local label
      if [[ $PARTNER_SCOPE == branch ]]; then
        label=$(git symbolic-ref --short -q HEAD 2>/dev/null)
        [[ -n $label ]] || { print "need to be on a branch"; return 1 }
        git config "partner.$label.seed" $(( $(_partner_seed $label) + 1 ))
      else
        label=$(git rev-parse --show-toplevel 2>/dev/null) || { print "not in a git repo"; return 1 }
        label=${label:t}
        git config partner.seed $(( $(git config --get partner.seed 2>/dev/null || print 0) + 1 ))
      fi
      vcs_info; _partner_pet
      print -P "%F{208}◆%f the egg cracks… ${label} now raises: %B${REPLY_FULL}%b"
      ;;
    update)
      local out; out=$(git -C "$_partner_root" pull --ff-only 2>&1) || { print "update failed:\n$out\nrun 'partner reset' to restore a clean install"; return 1 }
      touch "$_partner_root/.git/last-update"
      print -- "$out"
      [[ $out == *"Already up to date"* ]] || print "run 'exec zsh' to load the new version"
      ;;
    reset)
      # Restore a clean install: discard local edits to the theme, match the remote,
      # and re-create the Oh My Zsh symlink if it's missing.
      print -n "discard local changes to the theme and reset to the latest remote version? [y/N] "
      read -q || { print "\ncancelled"; return 1 }
      print
      git -C "$_partner_root" fetch -q && git -C "$_partner_root" reset --hard '@{u}' || { print "reset failed"; return 1 }
      local link=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/partner-theme.zsh-theme
      [[ -e $link ]] || ln -sf "$_partner_root/partner-theme.zsh-theme" "$link"
      touch "$_partner_root/.git/last-update"
      print "reset done, run 'exec zsh' to reload"
      ;;
    *) print "usage: partner status (or today, pet) | partner reroll | partner update | partner reset" ;;
  esac
}

# Opt-in daily self-update (PARTNER_AUTO_UPDATE=1 in ~/.zshrc). Runs in the
# background; the new version loads the next time you open a shell.
_partner_auto_update() {
  local stamp=$_partner_root/.git/last-update
  [[ -f $stamp && -z $stamp(#qN.mh+24) ]] && return
  { git -C "$_partner_root" pull --ff-only -q && touch $stamp } &>/dev/null &!
}
(( ${PARTNER_AUTO_UPDATE:-0} )) && _partner_auto_update
