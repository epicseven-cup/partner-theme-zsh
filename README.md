# partner-theme-zsh

An [Oh My Zsh](https://ohmyz.sh) theme where every git branch hatches its own pet.
Your pet evolves as you commit on the branch, so your prompt shows how much work you've put in.

```
 ◆ Wizard Cat  ▰▰▱▱ 7 commits
 ~/projects/app  ⎇ feature/login*  ❯
```

## Requirements

- zsh and [Oh My Zsh](https://ohmyz.sh)
- git
- A terminal with 256-colour support and Unicode (for `◆ ▰ ▱ ▌ ⎇ ❯ ✖`). No special font needed.

## Install

Clone the repo and symlink the theme file into Oh My Zsh's custom themes folder:

```sh
git clone https://github.com/epicseven-cup/partner-theme-zsh.git ~/partner-theme-zsh
ln -s ~/partner-theme-zsh/partner-theme.zsh-theme \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/partner-theme.zsh-theme"
```

Then set the theme in `~/.zshrc` and reload:

```sh
ZSH_THEME="partner-theme"
```

```sh
exec zsh
```

Keep the clone where it is. The theme loads `config/` and `lib/` from the repo through the symlink, so copying only the `.zsh-theme` file will not work.

**Update:** `git -C ~/partner-theme-zsh pull`

**Uninstall:** remove the symlink and change `ZSH_THEME` back.

## What you see

The prompt has two lines:

1. **The pet badge**: name, progress bar and your commit count on this branch. Hidden outside a git repo and on a detached HEAD.
2. **The working line**: current path, git branch, then the prompt arrow.

The branch segment is green when clean and amber when there are changes. Its suffix shows what changed: `*` unstaged, `+` staged, `?` untracked files.

If the last command failed, a red `✖ <exit code>` badge appears before the path and the arrow turns red.

## How pets work

Each branch gets a random animal, class, rank and title. The pick is derived from the repo name and branch name, so you get the same pet every time you come back to that branch.

The pet evolves with the commits **you** make on the branch:

| Commits | Stage | Example | Colour |
|---|---|---|---|
| 0 | Egg | `Egg` | grey |
| 1+ | Hatchling | `Cat` | aqua |
| 5+ | Class | `Wizard Cat` | orange |
| 15+ | Rank | `Grand Wizard Cat` | violet |
| 30+ | Legend | `Grand Wizard Cat of Green Builds` | magenta |

### What counts as a commit

- Only commits whose author email matches your `git config user.email`.
- Merge commits are never counted.
- **Feature branches** count from the point you branched off, read from the branch's local reflog. Merging main into the branch, or the branch into main, doesn't change its pet.
- **Default branch** (`main`, `master` or `trunk`, or whatever `origin/HEAD` points to): all your commits on it count.
- **Fallback:** if the branch-off point is unknown (the reflog expired, or the branch was rebased), your commits that are not on the default branch count instead.

### On fire

Commit more than 5 times in a day (6 or more, in this repo, on any branch) and the badge turns to embers: a dark red background, with the pet's name still in its stage colour. Commits are counted from the local reflog, so new commits and cherry-picks count; amends, merges, pulls, rebases and checkouts don't.

## Commands

```sh
digi status   # your pet, progress, how many commits until it evolves, commits today
digi reroll   # hatch a different pet for the current branch
```

`digi status` also tells you how the count was decided (for example "your commits since branching off at a1b2c3d").

`digi reroll` stores a counter in the repo's git config (`digivice.<branch>.seed`). Remove it with `git config --unset digivice.<branch>.seed` to go back to the original pet.

## Customise

Everything you'd want to change lives in `config/`:

```
config/
  animals.zsh    the hatchling pool
  classes.zsh    gained at stage 3
  ranks.zsh      gained at stage 4
  titles.zsh     the legend suffix
  settings.zsh   thresholds, fire mode, colours
```

You can edit those files directly, or leave the repo untouched and override from `~/.zshrc`. Set values **before** the `source $ZSH/oh-my-zsh.sh` line. Anything you define there wins over the defaults:

```sh
DIGI_ANIMALS=(Cat Dog Axolotl)
DIGI_LEVELS=(1 5 15 30)     # commits for each evolution
DIGI_FIRE_AT=6              # commits per day for the ember badge
DIGI_FIRE_BG=52             # ember background colour (256-colour code)
```

Stage colours can be changed after Oh My Zsh loads:

```sh
DIGI_STAGE_COLORS[LEGEND]=220   # EGG, BABY, CLASS, GRAND, LEGEND, NONE
```

> **Note:** pets are picked by position in each list. Adding, removing or reordering entries changes which pet existing branches get.

## Project layout

```
partner-theme.zsh-theme   entry point that Oh My Zsh loads
config/                   user-editable pools and settings
lib/
  git.zsh                 vcs_info setup, branch-off and commit counting
  pet.zsh                 stable per-branch pick and evolution stage
  prompt.zsh              badge and prompt rendering
  digi.zsh                the `digi` command
```

## Troubleshooting

- **Theme not found:** check that the symlink exists in `$ZSH_CUSTOM/themes` and isn't broken (`ls -l`).
- **Garbled symbols or wrong colours:** use a terminal with Unicode and 256-colour support.
- **Pet stuck at Egg:** your `git config user.email` must match your commit authors.
- **Count changed after a rebase:** the branch-off point is lost, so the fallback counts your commits that are not on the default branch.
- **Slow prompt in a huge repo:** the theme runs a few git commands on every prompt; the untracked-file check is the most expensive.
