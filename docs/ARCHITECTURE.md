# lpm — architektura (0.2)

| plik | rola |
|---|---|
| `main.h#` | wejście: **importy bit** (`libfasttree` jako `ft`, `lrpm` jako `rp`, colors, nidus, progress-bar), parsowanie opcji, dyspozytor komend, `triggers` |
| `config.h#` | `lpm.hk` (obraz + `/state/etc/lpm/lpm.hk`) → `Config` (**tylko typy proste**; `root: string` zamiast `Layout`) |
| `rpmio.h#` | adapter na **lrpm**: `prepare` (sync → solver → pobranie), `extract`, `sync`, `search`; `inspect` (`rpm -qp`) dla `lpm add` |
| `layer.h#` | `install`/`remove`/`rollback`/`upgrade`/`deploy` — warstwy w obrazie; FastTree przez `ft::api::*` |
| `pkgs.h#` | `add`/`del`/`pkgs`/`gen`/`gc` — magazyn `/packages` przez `ft::api::pkg_*`/`profile_*` |
| `toolcmd.h#` | `/tools` przez `ft::api::tool_*` i `ft::api::hk_*` |
| `status.h#` | `status`, `doctor` |
| `plan.h#` | tylko `remap_tree` (I/O); czysta logika → `lrpm::lpath` |
| `journal.h#` | dziennik transakcji (`/state/lpm/journal`) |
| `ui.h#` | wygląd: colors/progress-bar/nidus |

## Przepływ `lpm install`
1. `rpmio::prepare` → `rp::txn::flat_prepare`: metadane (cache) → **satsolv** względem `installed.xml` + atrapy z `compat.hk` → pobranie i weryfikacja RPM (sha256, GPG).
2. Rozpakowanie każdego RPM (`bsdtar`) → `remap_tree` (/usr→/system, /etc→/system/etc; /var,/home→pomijane) do drzewa zmian.
3. Nowy `installed.xml` (baza + bloki nowych pakietów) dokładany do drzewa zmian.
4. `ft::api::stage_layered` (derive: baza + zmiany → nowy tag) → `ft::api::deploy` (composefs + dm-verity + atomowa podmiana `current`).
5. Restart ⇒ nowy system; `lpm rollback` = `ft::api::rollback`.
`lpm remove` przebudowuje od obrazu bazowego z RPM-ów pozostałych żądań (lista w `/state/lpm/requests/*.list`, bloki `*.blocks`, baza `/state/lpm/base-installed.xml`).

## Zasady użycia bibliotek (zob. ../libfasttree/docs/USING-AS-LIBRARY.md)
* importy bit tylko w `main.h#`; wywołania `ft::api::…`/`rp::…`; typy w pozycji typu przez nazwę modułu (`lpath::Node`);
* żadnych pól struktur lpm z typami bibliotek, żadnych literałów struktur bibliotek (N2) — konstruktory i fasady są w bibliotekach.

## Czego nadal brakuje
`lpm triggers` obsługuje sysusers i polecenia z `[hooks]`; `tmpfiles.d`, `alternatives`, `authselect` — nie (ROADMAP M2).
