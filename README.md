# dotfiles

zsh (oh-my-zsh + powerlevel10k), fish, tmux, vim/neovim, kitty, yazi and
(Ubuntu only) i3 configs, linked into `$HOME` with
[dotbot](https://github.com/anishathalye/dotbot).

Supported: **Ubuntu** (apt) and **macOS** (Homebrew, Apple Silicon or Intel).

## Install

```sh
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles
./install
```

`./install` is idempotent; re-run it to update everything. It:

1. links the configs (`install.conf.yaml`),
2. runs `scripts/pre-install.sh` – system packages, yazi (+ plugins), uv, oh-my-zsh, p10k, vim-plug,
3. runs `scripts/cargo.sh` – rustup; on Ubuntu also zoxide, tree-sitter, zellij, broot,
4. runs `scripts/node.sh` – nvm + LTS node, gemini/codex/copilot CLIs, claude,
5. inits submodules, installs tmux plugins (tpm) and neovim (`scripts/nvim.sh`).

Afterwards open a new shell and run `p10k configure` once (writes `~/.p10k.zsh`).

## Ubuntu vs macOS

Only the package step differs; the configs are shared and branch on the OS
where command names differ.

| | Ubuntu | macOS |
|---|---|---|
| packages | apt list in `scripts/pre-install.sh` | `Brewfile` via `brew bundle` (keep the two in sync) |
| fzf | git checkout in `~/.fzf` | brew `fzf`; `fzf-preview.sh` linked into `~/.local/bin` |
| gh, fish | apt repo / PPA | brew |
| yazi | yazi apt repo | brew (`Brewfile`; `ffmpeg-full`/`imagemagick-full` force-linked) |
| zoxide, tree-sitter, zellij, broot | cargo (`scripts/cargo.sh`) | brew (`Brewfile`); `cargo.sh` removes old cargo builds |
| neovim | AppImage in `/opt` | brew |
| fd / bat | `fdfind` / `batcat` (aliased to `fd` / `bat`) | `fd` / `bat` |
| open / clipboard | `xdg-open` / `xclip` | `open` / `pbcopy` |
| tmux CPU/RAM line | iostat + `/proc` | `top` + `vm_stat` |
| fonts (kitty) | install MesloLGS NF + Symbols Nerd Font manually | brew casks in `Brewfile` |

macOS notes:

- Homebrew's installer asks for your password once; `pre-install.sh` runs it
  when `brew` is missing.
- A kitty already in `/Applications` is adopted into Homebrew
  (`brew install --cask --adopt kitty`) rather than reinstalled.
- `brew shellenv` is evaluated at the top of `zshrc` / `config.fish`, so
  brew-installed tools are on PATH in every interactive shell.

## yazi

`.npy` / `.npz` files get an array preview – shape, dtype, memory order, size,
values and a min/max/mean line – from `yazi/plugins/npy.yazi`. It shells out to
`python3`; when that interpreter has no numpy it re-runs once under
`uv run --with numpy` (~100 ms), and when uv is missing too it falls back to the
metadata in the file header, which needs no dependencies at all. So a project
venv's numpy is used when yazi is launched inside one, and previews still work
outside one. Point `YAZI_NPY_PYTHON` at another interpreter to override.

Image and PDF previews are sized to the preview pane by
`yazi/plugins/fit-preview.yazi`: images are upscaled to at least half the pane
width (bounded by its height), and PDF pages are rendered at the full pane width.
A page taller than the pane is shown in slices; `J`/`K` scroll through the
slices and on to the next page. It reads the cell size in pixels from the tty
via `python3`, and needs poppler (`pdfinfo`, `pdftoppm`) and ImageMagick.

Reading is header-first, so a multi-GB array previews as fast as a small one,
and object arrays are never unpickled (that would run code from the file).

## i3 (Ubuntu / X11)

`i3/` is linked to `~/.config/i3` on Linux only (`if: [ "$(uname)" = Linux ]` in
`install.conf.yaml`); macOS skips it. `./install` does **not** apt-install i3 or
its companions — the package list, the polybar / rofi / dunst files that are not in
this repo yet, Korean input, and the i3 gotchas (`exec_always` only re-runs on
*restart*, not *reload*; the `xset` idle-blank race) are all in
[`i3/i3_setup.md`](i3/i3_setup.md).

## Manual / optional

- **conda**: install Miniconda (or Anaconda) into `~/miniconda3` (or set
  `CONDADIR`); `zshrc` / `config.fish` pick it up.
- `scripts/korean.sh` – Korean input + fonts, Ubuntu only.
- `scripts/pdf.sh` – pandoc/poppler, a viewer (zathura on Ubuntu, Skim on macOS), full TeX (texlive-full / MacTeX, ~5 GB) and tdf. Run manually; MacTeX asks for your password. `~/.config/nvim` (vimtex) picks skim on macOS.
- fish prompt: `fisher install IlanCosman/tide@v6` (see the end of `config.fish`).
