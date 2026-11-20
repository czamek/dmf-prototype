# DMF prototype

A small, runnable **Dynamic Media Facility** (DMF) on one Linux machine, built step by step to learn the
[EBU DMF reference architecture](https://tech.ebu.ch/publications/white-paper-2026-04-15).
Each step adds working code, a tutorial, and reference pages.

**Stack:** a Linux machine with Docker (GitHub Codespaces recommended, see `.devcontainer/`), [MXL](https://github.com/dmf-mxl/mxl) v1.1.0,
GStreamer media functions (`mxlsrc` / `mxlsink`), Python control services.
Docker Compose first, local Kubernetes (k3d) later.

## What we are building

```
 cam-1 (test source) ─┐
                      ├─► mixer ─► programme flow ─► browser monitor (WebRTC)
 cam-2 (test source) ─┘     ▲
                            │ cut
                     control API + NMOS IS-04 registry
```

All media functions share one MXL domain (a RAM-backed volume), so frames move between
containers through shared memory, not over the network.

## Steps

| # | Step | Tutorial | Status |
|---|------|----------|--------|
| 1 | Environment | [01-environment](docs/tutorials/01-environment.md) | Draft |
| 2 | First flow, watched in the browser | | Planned |
| 3 | First Media Function (mixer) | | Planned |
| 4 | Control: NMOS IS-04 registry and cut API | | Planned |
| 5 | Orchestration on k3d | | Planned |
| 6 | Monitoring with Prometheus and Grafana | | Planned |
| 7 | Optional ST 2110 / SRT edge | | Planned |

## Docs

- **Tutorials** (`docs/tutorials/`): do this, then this, and see what happens.
- **Reference** (`docs/reference/`): concepts and facts to look up.
  - [DMF architecture](docs/reference/dmf-architecture.md)
  - [MXL concepts](docs/reference/mxl-concepts.md)

## Layout

```
docs/tutorials/    step-by-step guides, one per step
docs/reference/    concepts, glossary, standards
scripts/           helper scripts
vendor/mxl/        MXL SDK checkout (created by scripts/get-mxl.sh, not committed)
functions/         our own Media Functions (from step 2)
control/           control services (from step 4)
deploy/compose/    Docker Compose files (from step 2)
deploy/k8s/        Kubernetes manifests (from step 5)
```

## Licence

Code: Apache-2.0. Docs: CC-BY-4.0. MXL is Apache-2.0, © contributors to the MXL project.
