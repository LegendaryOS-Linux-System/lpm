# lpm — roadmapa

| kamień | zakres | status |
|---|---|---|
| M0 | CLI, config.hk, status/doctor, plan (mapowanie ścieżek, DAG), journal | ✅ zrobione, testy |
| M1 | `/tools`: pack/mount/update/catalog, `/packages`: store, profile, wrappery, gc | ✅ w libfasttree (testy) + CLI |
| M2 | `install/remove` end-to-end na prawdziwej Fedorze (**satsolv/lrpm, bez dnf**, composefs, restart) | ⚠ kod przepisany w 0.2, **niezweryfikowany** |
| M2b | `lpm triggers`: sysusers + hooki; luki: tmpfiles.d, alternatives, authselect | ⚠ częściowo |
| M3 | Skrypty RPM: `%sysusers`, `%tmpfiles`, `%systemd_post`→jednostki zenitd, `ldconfig`, `glib-compile-schemas` jako deklaratywne hooki | ⬜ |
| M4 | Backend `satsolv` (libsolv): solver natywny, `lpm upgrade` z ponownym rozwiązaniem warstw względem nowej bazy | ⬜ |
| M5 | `patchelf` + bubblewrap: przeniesienie ścieżek `/usr` w pakietach z `/packages` (dziś: tylko LD_LIBRARY_PATH) | ⬜ |
| M6 | Sterowniki: `lpm gpu` — akmod/kmod w obrazie, `/run/opengl-driver` budowany przy starcie przez zenitd | ⬜ |
| M7 | Podpisy (sigstore/GPG), `fs-verity` na `/system`, ochrona `/state` przed rollbackiem | ⬜ |
| M8 | Auto-update (timer zenitd), `lpm rebase`, kanały (rolling/stable), zdalne repo FastTree | ⬜ |
