# Evolution thresholds and fire mode. Set these in ~/.zshrc to override.
(( ${#DIGI_LEVELS} == 4 )) || typeset -ga DIGI_LEVELS=(1 5 15 30)
typeset -gi DIGI_FIRE_AT=${DIGI_FIRE_AT:-6}

# When you're on fire the badge turns to embers: dark red background, with the
# pet's name still in its stage colour.
: ${DIGI_FIRE_BG:=52}    # ember red

# Colour per evolution stage (256-colour codes). Override in ~/.zshrc,
# e.g.  DIGI_STAGE_COLORS[LEGEND]=220
typeset -gA DIGI_STAGE_COLORS
: ${DIGI_STAGE_COLORS[EGG]:=250}      # pale shell grey
: ${DIGI_STAGE_COLORS[BABY]:=43}      # aqua
: ${DIGI_STAGE_COLORS[CLASS]:=208}    # orange
: ${DIGI_STAGE_COLORS[GRAND]:=135}    # violet
: ${DIGI_STAGE_COLORS[LEGEND]:=199}   # hot magenta
: ${DIGI_STAGE_COLORS[NONE]:=244}     # outside a repo / detached HEAD

# Progress bar glyphs (██░░). Override in ~/.zshrc if you like.
: ${DIGI_BAR_FULL:=█}
: ${DIGI_BAR_EMPTY:=░}
