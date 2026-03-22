# CI evidence

Ez a fájl a main/default branch legutóbbi igazolt zöld CI futásának release-evidence helye.
Kitöltése minden olyan push után szükséges, amelyet release-közeli állapotként akarsz hivatkozni.

## Kitöltendő adatok

- Branch: `main`
- Workflow: [`ci.yml`](../../.github/workflows/ci.yml)
- Legutóbbi zöld run URL: `https://github.com/SZTE-SZF/1-sprint-Admgt/actions/runs/23404984466`
- Commit SHA: `b0790f1`
- Run dátuma: `2026-03-22`
- Rövid megjegyzés: a release-readiness dokumentáció, a Flutter dependency audit és a lokális quality gate frissítések utáni állapotot igazolja

## Elvárt minimális evidence

- A run státusza zöld / successful.
- A run a main/default branchhez tartozik, nem csak feature branchhez.
- A `lint`, `build` és `test` job is sikeres.
- A security artifactok és a test evidence artifactok elérhetők, ha a workflow generálta őket.

## Jelenlegi állapot

- Státusz: `passing`
- Megjegyzés: a konkrét GitHub Actions run URL, commit SHA és futási dátum rögzítve van ehhez a release-közeli állapothoz.
