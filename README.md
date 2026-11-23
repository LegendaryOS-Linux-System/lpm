# lpm — LegendaryOS Package Manager

Niezmienny menedżer pakietów dla LegendaryOS (Fedora + zenitd + FastTree). Napisany w **H#** (`src/`),
z modułem **Z#** (`mod/`) i skryptami **Hacker Lang** (`source-code/`), w układzie projektu **nula** (`nula.hk`).
Biblioteki: `colors`, `nidus`, `progress-bar` (bit.io) oraz **libfasttree** (moduły dołączone do `src/`).

```
lpm install <pkg>...     warstwa w obrazie systemu (nowy deployment FastTree, aktywny po restarcie) — jak rpm-ostree install
lpm remove  <pkg>...     usuń warstwę (przebudowa od obrazu bazowego z RPM-ów w cache)
lpm upgrade | deploy <tag> | rollback | deployments
lpm add <pkg>...         pakiet do /packages (styl nix; atomowa generacja profilu, BEZ restartu)
lpm del | pkgs | gen | gen-rollback | gc
lpm tools add|add-all|update|list|catalog|mount-all|path|remove     narzędzia /tools (git -> squashfs)
lpm search | status | doctor | layout-check | version
opcje: --root DIR  --dry-run  -y
```

Dwa tryby instalacji, jedno źródło (RPM-y Fedory): `install` = jak rpm-ostree (część obrazu, rollback całego systemu),
`add` = jak nix (własna ścieżka w store z hashem wejść, brak konfliktów zależności, sterowniki zawsze z `/system`).

## Budowanie
```
bit build            # wymaga h# >= 0.9 i bit; pobiera colors/nidus/progress-bar z github.com/bit-io
scripts/vendor-fasttree.sh   # po zmianach w ../libfasttree
h# test src/tests/plan_test.h#
```
Dokumentacja: `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/Z-SHARP-GAPS.md`.

## Status (v0.1.0)
Zweryfikowane: kompilacja, testy jednostkowe czystej logiki, smoke-test `status`/`tools add`/`--dry-run` na sztucznym korzeniu.
**Niezweryfikowane** (brak dnf5/composefs/rejestru w środowisku autora): `install/remove/add` na prawdziwych RPM-ach,
`fasttree deploy`, `upgrade`. Szczegóły i ryzyka: `docs/ROADMAP.md`.
