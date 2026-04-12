# CI evidence

Ez a fájl a main/default branch legutóbbi igazolt zöld CI futásának release-evidence helye.
Kitöltése minden olyan push után szükséges, amelyet release-közeli állapotként akarsz hivatkozni.

## Jelenleg rögzített adatok

- Branch: `main`
- Workflow: [`ci.yml`](../../.github/workflows/ci.yml)
- Legutóbbi zöld run URL: `https://github.com/SZTE-SZF/1-sprint-Admgt/actions/runs/24307480991`
- Commit SHA: `279a11a`
- Run dátuma: `2026-04-12`
- Rövid megjegyzés: az aktuális `main` HEAD-hez tartozó zöld CI futás, amely a release-dokumentáció frissített állapotát igazolja

## Elvárt minimális evidence

- A run státusza zöld / successful.
- A run a main/default branchhez tartozik, nem csak feature branchhez.
- A `lint`, `build` és `test` job is sikeres.
- A security artifactok és a test evidence artifactok elérhetők, ha a workflow generálta őket.

## Jelenlegi állapot

- Státusz: `current for recorded HEAD`
- Megjegyzés: a rögzített run az aktuálisan dokumentált HEAD-hez tartozik, ezért release-evidenceként használható.
- Következő teendő: a következő release-közeli push után ismét frissíteni kell a run URL-t, a commit SHA-t és a dátumot.
