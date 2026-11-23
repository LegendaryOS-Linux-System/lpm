# lpm — architektura

## Moduły (`src/`)
| plik | rola |
|---|---|
| `main.h#` | CLI, flagi `--root/--dry-run/-y` |
| `config.h#` | `lpm.hk` (obraz → `/state/etc/lpm/lpm.hk`), błędy przez nidus |
| `layer.h#` | `install/remove/upgrade/rollback/deploy` — warstwy w obrazie |
| `pkgs.h#` | `add/del/pkgs/gen/gc` — magazyn `/packages` |
| `toolcmd.h#` | `/tools`: katalog `tools.hk`, pack/mount/update |
| `rpmio.h#` | `dnf download --resolve`, `rpm -qp`, `rpm2cpio | cpio`, remap ścieżek |
| `plan.h#` | **czysta logika**: `map_path`, porządek topologiczny z cyklami, walidacja nazw (testy) |
| `journal.h#` | dziennik transakcji (jedna naraz, sprzątanie po awarii) |
| `status.h#` | `status`, `doctor` |
| `ui.h#` | colors / progress-bar / nidus |
| reszta | zsynchronizowane moduły libfasttree (`scripts/vendor-fasttree.sh`) |

## Przepływ `lpm install`
1. `dnf5 download --resolve` względem **działającego** `/system` — pobiera tylko to, czego baza nie ma (glibc, Mesa, NVIDIA zostają z obrazu).
2. `rpm -qp` → metadane; `rpm2cpio | cpio` → drzewo; `plan::map_path`: `usr/→system/`, `etc/→system/etc/`, `bin|sbin|lib|lib64|opt→system/…`; `var/ home/ run/…` pomijane (obszar `/state`).
3. `deployment::stage_layered`: nowy `manifest.toml` (generacja+1, parent, `[[layer]]`) + `derive` ⇒ nowy tag FastTree.
4. `fasttree deploy <tag> --atomic`: obraz composefs + podmiana `current` (rename). Restart ⇒ nowy system. `lpm rollback` ⇒ poprzedni.
Skrypty `%post` RPM **nie** są uruchamiane (obraz niezmienny) — patrz ROADMAP, kamień M3.

## Przepływ `lpm add` (nix-like)
Dla każdego RPM z domknięcia: `store/<h32>-<nazwa>-<ver>/{content,wrap,meta.toml}`, hash z (nazwa, wersja, arch, skrót RPM, hashe zależności).
Wrapper `LD_LIBRARY_PATH` = własne lib + closure + `/run/opengl-driver/lib` (na końcu). Generacja profilu = farma symlinków,
`profiles/current` przełączany atomowo. Konflikt plików w profilu jest **raportowany**, nie psuje bibliotek.
Cykle zależności RPM są przecinane (DFS) i zgłaszane ostrzeżeniem.

## Niezmienność
`/system` — composefs (ro). `/state`, `/packages`, `/tools` — montowane `ro`; operacje lpm robią `remount,rw` na czas transakcji i
wracają do `ro` (także przy błędzie). Poza punktami montowania (testy, chroot) wywołania są no-op.
