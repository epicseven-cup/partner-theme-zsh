# Evolution thresholds and fire mode. Set these in ~/.zshrc to override.
(( ${#PARTNER_LEVELS} == 4 )) || typeset -ga PARTNER_LEVELS=(1 5 15 30)
typeset -gi PARTNER_FIRE_AT=${PARTNER_FIRE_AT:-6}

# One pet per project (the default), or one per git branch.
#   project  one pet per repo, evolving with all your commits in it
#   branch   every branch hatches its own pet, evolving with your commits on it
: ${PARTNER_SCOPE:=project}

# When you're on fire the badge turns to embers: dark red background, with the
# pet's name still in its stage colour.
: ${PARTNER_FIRE_BG:=52}    # ember red

# Colour per evolution stage (256-colour codes). Override in ~/.zshrc,
# e.g.  PARTNER_STAGE_COLORS[LEGEND]=220
typeset -gA PARTNER_STAGE_COLORS
: ${PARTNER_STAGE_COLORS[EGG]:=250}      # pale shell grey
: ${PARTNER_STAGE_COLORS[BABY]:=43}      # aqua
: ${PARTNER_STAGE_COLORS[CLASS]:=208}    # orange
: ${PARTNER_STAGE_COLORS[GRAND]:=135}    # violet
: ${PARTNER_STAGE_COLORS[LEGEND]:=199}   # hot magenta
: ${PARTNER_STAGE_COLORS[NONE]:=244}     # outside a repo / detached HEAD

# Progress bar glyphs (██░░). Override in ~/.zshrc if you like.
: ${PARTNER_BAR_FULL:=█}
: ${PARTNER_BAR_EMPTY:=░}

# Icon shown in the "needs a rebase" notice (the branch is behind the default branch).
: ${PARTNER_REBASE_ICON:='⟳'}
