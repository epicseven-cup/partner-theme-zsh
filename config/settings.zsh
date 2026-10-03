# Evolution thresholds and fire mode. Set these in ~/.zshrc to override.
(( ${#PARTNER_LEVELS} == 4 )) || typeset -ga PARTNER_LEVELS=(1 5 15 30)
typeset -gi PARTNER_FIRE_AT=${PARTNER_FIRE_AT:-6}

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

# Icon shown before the changed-file count on the pet line (~2).
: ${PARTNER_FILES_ICON:='~'}
