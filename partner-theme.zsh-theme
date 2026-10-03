# partner-theme — an Oh My Zsh theme where every git branch hatches its own pet
#
# Install: see README.md, then set ZSH_THEME="partner-theme" in ~/.zshrc
#
#   partner status      # meet this branch's pet and see when it evolves next
#   partner reroll      # hatch a different pet for this branch
#   partner update      # pull the latest theme version
#   partner reset       # restore a clean install from the remote
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
#   PARTNER_LEVELS=(1 5 15 30)   evolution thresholds
#   PARTNER_FIRE_AT=6            commits today needed for ON FIRE
#   PARTNER_FIRE_BG=52           ember background when on fire
#   PARTNER_AUTO_UPDATE=1        pull theme updates in the background once a day
# Outside a repo or on a detached HEAD the pet is hidden.
# A failed command flashes its exit code.

autoload -Uz vcs_info add-zsh-hook
setopt prompt_subst

# Resolve through symlinks so this works when linked into $ZSH_CUSTOM/themes.
_partner_root=${${(%):-%x}:A:h}

# config first (honours anything already set in ~/.zshrc), then logic
for _partner_f in "$_partner_root"/config/*.zsh "$_partner_root"/lib/{git,pet,prompt,partner}.zsh; do
  source "$_partner_f"
done
unset _partner_f
