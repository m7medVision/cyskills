# Cyskills bootstrap reference

`step-cyskills` runs four scripts, all self-contained bash with no runtime dependencies beyond coreutils.

## Config files (next to the scripts)

`cyskills.conf`
: `CYSKILLS_DATA` — base dir for self-installed resources (default `~/tools`). Override by env var.

`tools.conf` — one tool per line:
```
name|probe|apt|pacman|aur|purpose
```
`probe` is a command name (`command -v`) or an absolute path (`-x`). Empty package columns mean manual/pip install and are reported as such.

`resources.conf` — one asset per line:
```
name|paths|sentinel|apt|pacman|aur|git|purpose
```
`paths` is colon-separated and supports `$HOME`; a path counts only when `path/sentinel` exists (or `sentinel` is empty). `git` is the fallback clone URL, cloned into `$CYSKILLS_DATA/<name>`.

## Distro detection

`preflight.sh` reads `/etc/os-release` and detects:

| Distro | Detection | Hint style |
| --- | --- | --- |
| Kali / Debian | `apt` present, `ID`/`ID_LIKE` contains `debian` or `kali` | `sudo apt install <pkg>` |
| BlackArch | `pacman` present and `[blackarch]` in `/etc/pacman.conf` (or `/etc/pacman.d/blackarch*`) | `sudo pacman -S <pkg>` |
| Arch / other pacman | `pacman` present, no BlackArch repo | `yay -S <pkg>` / `paru -S <pkg>` (AUR) |
| Other | no apt/pacman | `git clone` fallback or manual note |

Env overrides: `SECLISTS_DIR`, `CYSKILLS_DATA`, and any `*_DIR` named in `resources.conf` are honored before the default paths.

## Scope gate

`scope-init.sh` writes `work/<case>/scope.md` with `auth.status: pending` unless `--authorized --auth-basis` was supplied. `scope-guard.sh --case <name>` exits `0` only when `auth.status: granted` and at least one in-scope asset exists; otherwise exit `2` with the missing field. Nothing proceeds to target work while the guard fails.

## Resource resolution

`preflight.sh` never installs. It reports present/missing status with the exact install command, and the agent asks the user before running it. Never browse or download outside `CYSKILLS_DATA` without explicit approval.