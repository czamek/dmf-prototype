# DMF architecture

Source: [EBU white paper, The Dynamic Media Facility Reference Architecture, v2 (15 April 2026)](https://tech.ebu.ch/publications/white-paper-2026-04-15).

A Dynamic Media Facility runs live production as stateless, containerised **Media Functions** on
general-purpose IT, exchanging media through one open **Media Exchange** layer.

## Layers (bottom to top)

| Layer | Responsibility | In this prototype |
|---|---|---|
| Infrastructure | Physical compute, network, storage, timing reference (PTP, NTP, SyncE) | The Mac |
| Host Platform | Makes infrastructure usable; bare metal or type-1 hypervisor; hosts grouped into clusters | Docker Desktop's Linux VM |
| Container Platform | Container engine, container networking, container orchestration (e.g. Kubernetes) | Docker Compose, later k3d |
| Media Exchange | Open, shared-access exchange of live media between Media Functions | MXL |
| Media Functions | Stateless units acting on media (mixing, graphics, colour) | GStreamer-based containers |
| Application & User Interface | Operator access without knowledge of lower layers (HTML5, WebRTC, REST, WebSockets, NMOS IS-12) | Browser monitor and cut button |

The bottom three are generic IT; the EBU leaves them to the IT industry.

## Cross-cutting functions

| Function | Responsibility |
|---|---|
| Orchestration | Creates, configures and destroys resources in every layer, as Infrastructure as Code. Made explicit in v2. |
| Control | Operational control of running resources |
| Monitoring | Alerts and analysis |
| Security | Zero trust: AAA, least privilege, segmentation for multitenancy, continuous validation |

Timing is not a separate vertical: it is a reference in Infrastructure and a timestamp on every grain.

## Where existing standards fit

| Standard | Role in a DMF |
|---|---|
| SMPTE ST 2110 (+ -21 pacing) | Uncompressed I/O at the cluster edge and between clusters |
| SMPTE ST 2059 / PTP | Timing reference; its epoch is MXL's time base |
| AMWA NMOS IS-04 | Discovery; Media Functions map to Nodes, MXL flows are IS-04 Flows |
| AMWA NMOS IS-05 | Connection management |
| AMWA NMOS IS-12 | Device control |
| Kubernetes | Container Platform and Orchestration |
| libfabric, OpenUCX | RDMA transports for Media Exchange between hosts |

Inside a cluster, Media Exchange is preferred over ST 2110 because streaming requires packetising
and copying data.
