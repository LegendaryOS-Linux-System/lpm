# lpm — LegendaryOS Package Manager (0.2.0)

Produkcyjny, **niezmienny** menedżer pakietów LegendaryOS — **zamiast dnf**. System nie ma dnf, a lpm tego nie zakłada:
zależności liczy **satsolv** (libsolv), RPM-y pobiera i weryfikuje sam, obrazy składa **libfasttree** (FastTree/composefs).
Napisany w **H#** (`src/`), z modułem **Z#** (`mod/`) i skryptami **Hacker Lang** (`source-code/`), w układzie **nula**.

Biblioteki **wyłącznie przez bit** (`src/main.h#`), bez żadnej kopii cudzego kodu:
`libfasttree` (obrazy, układ, wdrożenia, /packages, /tools), `lrpm` (rpm-md → satsolv → pobranie → rozpakowanie), `colors`, `nidus`, `progress-bar`.

```
lpm sync                 odśwież metadane repozytoriów rpm-md
lpm install <pkg>...     warstwa w obrazie systemu (nowy deployment FastTree, aktywny po restarcie) — jak rpm-ostree install
lpm remove  <pkg>...     usuń warstwę (przebudowa od obrazu bazowego z RPM-ów w cache)
lpm upgrade | deploy <tag> | rollback | deployments
lpm add <pkg>...         pakiet do /packages (styl nix; atomowa generacja profilu, BEZ restartu)
lpm del | pkgs | gen | gen-rollback | gc
lpm tools add|add-all|update|list|catalog|mount-all|path|remove     narzędzia /tools (git -> squashfs)
lpm search | status | doctor | layout-check | triggers | version
opcje: --root DIR  --dry-run  -y
```

## Jak lpm radzi sobie bez dnf
1. **Baza systemu** = `/system/share/legendaryos/installed.xml` (zapisuje lepm przy budowie obrazu, lpm przy warstwach).
   Solver zna `Provides/Requires` zainstalowanych pakietów, więc dokłada tylko brakujące.
2. **Problem „Requires: systemd”**: polityka `compat.hk` (atrapy `Provides`, wykluczenia, hooki) — [../lrpm/docs/POLICY.md](../lrpm/docs/POLICY.md).
3. **Skryptlety RPM nie są uruchamiane.** Zamiast tego `lpm triggers` (usługa zenitd po zmianie wdrożenia): `sysusers.d` + hooki z `compat.hk`.
4. Wymagane narzędzia (żadne to dnf): `curl gawk bsdtar zstd sha256sum git mksquashfs mkcomposefs veritysetup`, `rpm` (`rpmkeys`, `rpm -qp` dla `lpm add`). `lpm doctor` sprawdza.

## Budowanie
```
bit build                       # h# >= 0.9, bit; pobiera libfasttree, lrpm (→ satsolv), colors, nidus, progress-bar
../lrpm/scripts/run-tests.sh    # testy czystej logiki (lpath/pure) — bez bibliotek bit (N4)
h# test src/tests/remap_test.h# # test plikowy (>4 GB RAM)
```
Dokumentacja: `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/Z-SHARP-GAPS.md`.

## Status (0.2.0)
**Przepisane w sesji bez kompilatora H#** (brak `h#`/`bit`/libsolv/Fedory): całość warstwy RPM (`rpmio`, `layer`, `pkgs`, `config`, `status`, `toolcmd`, `main`)
oraz przejście na `use "bit -> libfasttree"`. Kod z 0.1 (kompilował się i miał testy) został zmieniony — **pierwszy krok: `bit build`**, potem testy.
Szczegóły ryzyk: `docs/ROADMAP.md`, `../Z-SHARP-GAPS.md`.
