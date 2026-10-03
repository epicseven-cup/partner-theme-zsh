# The `digi` command.

digi() {
  case $1 in
    status|today|pet)
      git rev-parse --is-inside-work-tree &>/dev/null || { print "not in a git repo"; return 1 }
      local branch=$(git symbolic-ref --short -q HEAD)
      vcs_info; _digi_pet
      if [[ -n $REPLY_STAGE ]]; then
        local lc=${DIGI_STAGE_COLORS[$REPLY_STAGE]}
        print -P "$(_digi_badge "◆ ${REPLY_NAME}" $lc) %F{240}(%f%F{214}${branch}%f%F{240})%f"
        _digi_branch_count >/dev/null
        print -P "  ${REPLY_BAR}  ${REPLY_COUNT} commit${${REPLY_COUNT:#1}:+s}  %F{240}(${DIGI_BRANCH_SCOPE})%f"
        if [[ $REPLY_STAGE == EGG ]]; then
          print -P "  hatches after ${REPLY_NEXT} commit${${REPLY_NEXT:#1}:+s} on this branch  %F{240}→ ???%f"
        elif [[ -n $REPLY_NEXT ]]; then
          print -P "  evolves in $(( REPLY_NEXT - REPLY_COUNT )) more  %F{240}→ final form: ${REPLY_FULL}%f"
        else
          print -P "  %F{$lc}fully evolved%f"
        fi
      else
        print "detached HEAD — no pet here"
      fi
      local -i t=$(_digi_count_lines "$(_digi_commits_today)")
      print -P "  ${t} commit${${t:#1}:+s} today in this repo  %F{240}(on fire at ${DIGI_FIRE_AT})%f"
      ;;
    reroll)
      local branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
      [[ -n $branch ]] || { print "need to be on a branch"; return 1 }
      git config "digivice.$branch.seed" $(( $(_digi_seed $branch) + 1 ))
      vcs_info; _digi_pet
      print -P "%F{208}◆%f the egg cracks… ${branch} now raises: %B${REPLY_FULL}%b"
      ;;
    *) print "usage: digi status | digi reroll" ;;
  esac
}
