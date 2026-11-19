# MXL concepts

Source: [dmf-mxl/mxl](https://github.com/dmf-mxl/mxl) v1.1.0 docs (Architecture.md, Timing.md, Tools.md).

MXL (Media eXchange Layer) is the open-source reference implementation of the DMF Media Exchange
layer: a C++ SDK with a C API and Rust bindings, Apache-2.0, hosted by the Linux Foundation with
the EBU and NABA. v1.0 (February 2026) added the same-host Flow API; v1.1 adds the Fabrics API for
moving grains between hosts.

## Model

| Term | Meaning |
|---|---|
| Domain | A directory on a tmpfs volume (e.g. `/dev/shm/mxl`) holding flows. Several domains can coexist. |
| Flow | A one-way stream with a UUID, at `<domain>/<flowId>.mxl-flow/`, described by an NMOS IS-04 Flow in `flow_def.json` |
| Grain | One unit of media: a video frame or an ANC packet burst |
| Writer / reader | One writer fills grains; any number of readers map them read-only. No packets, no copies. |
| Discrete flow | Ring of whole grains: video (`video/v210`, `video/v210a`) and ANC (`video/smpte291`) |
| Continuous flow | Ring of samples per channel: audio (`audio/float32`) |

## Files in a flow directory

| Path | Contents |
|---|---|
| `data` | 2048-byte flow header (config and runtime info such as head index), memory-mapped |
| `flow_def.json` | NMOS IS-04 Flow resource |
| `access` | Touched by readers so "last read time" is reliable |
| `grains/<n>` | Grain header plus payload for ring slot n, memory-mapped |

## Timing

- Time base: nanoseconds since the SMPTE ST 2059-1 (PTP) epoch, in TAI.
- Grain duration = 1e9 × rate denominator / rate numerator (20 ms at 50 fps).
- Grain index = timestamp / grain duration. Ring slot = grain index mod grain count.
- The ring is **not a queue**: a writer must write each grain at the index for its time, and
  resynchronise (drop, repeat, resample) if its source clock drifts from the host clock.
- Single host: NTP or PTP both work. Multiple hosts: clocks must not drift against each other.

## Safety and lifecycle

- Readers map memory `PROT_READ`; sync uses Linux futexes.
- Access is controlled by UNIX permissions on domain and flow directories.
- Writers hold advisory locks; `mxlGarbageCollectFlows()` (or `mxl-info -g`) removes stale flows.

## Core API (C)

| Call | Purpose |
|---|---|
| `mxlCreateInstance(domain, options)` | Open a domain |
| `mxlCreateFlowWriter(...)` | Create or open a flow for writing from a flow definition |
| `mxlFlowWriterOpenGrain` / `mxlFlowWriterCommitGrain` | Get a buffer for a grain index, fill it, commit (whole or in slices) |
| `mxlCreateFlowReader(...)` | Open a flow for reading |
| `mxlFlowReaderGetGrain` | Wait for and get a complete grain at an index |
| `mxlFlowReaderGetGrainSlice` | Get a partially written grain once enough slices are valid |
| `mxlFlowReaderGetSamples` | Read audio samples (continuous flows) |

## Tools

| Tool | Purpose |
|---|---|
| `mxl-info` | List flows in a domain, print flow details, garbage-collect |
| `mxl-gst-testsrc` | Write GStreamer test patterns and tones into flows |
| `mxl-gst-sink` | Play a flow through GStreamer |
| `mxlsrc`, `mxlsink` | GStreamer elements (Rust) to read from and write to MXL in any pipeline |

MXL URIs look like `mxl:///dev/shm/mxl?id=<flow-id>`.
