# partner-theme — an Oh My Zsh theme where every git branch hatches its own pet
#
# Install: see README.md, then set ZSH_THEME="partner-theme" in ~/.zshrc
#
#   digi status      # meet this branch's pet and see when it evolves next
#   digi reroll      # hatch a different pet for this branch
#
# Each branch gets a random animal, class and title, picked from the repo +
# branch name so it stays the same every time you come back. It evolves with
# the commits YOU make on the branch after branching off (merges excluded):
#
#   0    Egg
#   1+   Cat                                 (hatchling)
#   5+   Wizard Cat                          (gets a class)
#   15+  Grand Wizard Cat                    (gets a rank)
#   30+  Grand Wizard Cat of Green Builds    (legend)
#
# Only commits by your git user.email count. Feature branches count from the
# point you branched off (from the branch's local reflog), so merging main in, or
# merging the branch into main, doesn't change its pet. On the default branch
# (main/master) all your commits on it count.
# Commit more than 5 times in a day (in this repo, any branch) and your pet's
# badge turns to embers: dark red, with the name still in its stage colour.
#
# Tweak in ~/.zshrc before oh-my-zsh is sourced:
#   DIGI_LEVELS=(1 5 15 30)   evolution thresholds
#   DIGI_FIRE_AT=6            commits today needed for ON FIRE
#   DIGI_FIRE_BG=52           ember background when on fire
# Outside a repo or on a detached HEAD the pet is hidden.
# A failed command flashes its exit code.

autoload -Uz vcs_info add-zsh-hook
setopt prompt_subst

# Resolve through symlinks so this works when linked into $ZSH_CUSTOM/themes.
_digi_root=${${(%):-%x}:A:h}

# config first (honours anything already set in ~/.zshrc), then logic
for _digi_f in "$_digi_root"/config/*.zsh "$_digi_root"/lib/{git,pet,prompt,digi}.zsh; do
  source "$_digi_f"
done
unset _digi_f
