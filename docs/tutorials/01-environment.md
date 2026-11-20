# Step 1: Set up the environment

**Goal:** by the end of this step, two containers are writing a video flow and an audio flow
into a shared MXL domain, and two more are reading them. You will look at the flows from the
inside and see how they map onto the DMF layers.

**Time:** about an hour, most of it the first image build.

**You need:** a GitHub account and a browser (recommended path), or a Linux or Mac machine with
at least 16 GB of memory.

> Status: draft. These steps follow the MXL v1.1.0 repository and have not yet been run end to
> end. Please note anything that differs and we will fix the page.

MXL is Linux-only, and building it needs about 8 GB of memory on its own. Pick one of the two
paths below, then continue at section 3. Everything from section 3 on is the same for both.

## 1. Recommended: run it in GitHub Codespaces

A codespace is a Linux machine in the cloud with VS Code and Docker, opened from your browser.
This repo includes a ready-made configuration in `.devcontainer/` that asks for a 4-core,
16 GB machine, installs Docker, and fetches MXL v1.1.0 for you.

1. Open <https://github.com/czamek/dmf-prototype>.
2. Click **Code → Codespaces → Create codespace on main**.
   If GitHub offers a machine type, choose **4-core**.
3. Wait for VS Code to open in the browser. The first start runs `scripts/get-mxl.sh`, so
   `vendor/mxl` already exists.
4. Open a terminal (**Terminal → New Terminal**) and check Docker:

   ```sh
   docker run --rm hello-world
   ls vendor/mxl
   ```

Personal GitHub accounts include free Codespaces hours each month; check the current quota under
GitHub **Settings → Billing**. A codespace stops after 30 minutes idle and keeps your files;
**stop** it from <https://github.com/codespaces> when you finish a session, and **delete** it when
you no longer need it.

## 2. Alternative: run it on your own machine

Use this path only on a machine with **16 GB of memory or more**.

### Linux

Install Docker Engine and Git from your distribution, then:

```sh
git clone https://github.com/czamek/dmf-prototype.git
cd dmf-prototype
./scripts/get-mxl.sh          # clones MXL v1.1.0 into vendor/mxl
```

### Mac with Apple Silicon

1. Install the Xcode command line tools (this gives you `git`): `xcode-select --install`.
2. Install [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
   (Apple Silicon download), start it with `open -a Docker`, and run `docker run --rm hello-world`.
3. In **Settings → Resources**, give the Docker VM at least **4 CPUs, 8 GB memory and 40 GB
   disk**. Building the MXL SDK compiles C++ and Rust and runs out of memory with less.
4. In **Settings → General → Virtual Machine Options**, keep **Apple Virtualization framework**.
   We build native arm64 images, so Rosetta emulation is not needed.
5. Clone the project and fetch MXL as in the Linux steps above.

We pin MXL to a release tag so the tutorials keep working when MXL moves on.

## 3. Build the MXL example images

The MXL repository ships a Docker Compose example with six containers. Build it natively:

```sh
cd vendor/mxl/examples
docker compose build
```

The first build downloads Debian, GStreamer, vcpkg and Rust, and compiles the SDK, its tools and
the GStreamer plugin. Expect it to take a while; later builds reuse the cache.

Check that the images match your machine (no emulation):

```sh
docker image inspect mxl-example-video-flow-writer --format '{{.Architecture}}'
# amd64 in Codespaces, arm64 on an Apple Silicon Mac
```

## 4. Start the mini facility

```sh
docker compose up -d
docker compose ps
```

You should see six running services:

| Service | What it does | DMF layer |
|---|---|---|
| `video-flow-writer` | `mxl-gst-testsrc` writes a 1080p29.97 v210 test pattern | Media Function |
| `audio-flow-writer` | `mxl-gst-testsrc` writes float32 audio tones | Media Function |
| `video-fake-reader`, `audio-fake-reader` | Pretend to consume the flows, updating "last read time" | Media Function |
| `video-flow-info`, `audio-flow-info` | Run `mxl-info` every 5 seconds | Monitoring |

All six mount the same volume, `mxl-domain`. It is a **tmpfs** volume (RAM, not disk), and it is
the MXL **domain**: the shared place where flows live.

## 5. Watch a flow

```sh
docker logs -f mxl-example-video-flow-info-1
```

Every five seconds you get a block like this:

```
- Flow [5fbec3b1-1b0f-417d-9059-8b94a47197ed]
                    Format: Video
         Grain/sample rate: 30000/1001
               Grain count: ...
                Head index: 52939144165
           Last write time: ...
          Latency (grains): 1
                    Active: true
```

Things to notice:

- **Head index** keeps rising by about 150 every 5 seconds (29.97 grains per second). It is not a
  counter that started at zero: it is the current time in nanoseconds since the SMPTE ST 2059
  epoch, divided by the length of one frame. Every function on the host computes the same index
  for the same moment, which is how MXL keeps things in time without negotiating sequence numbers.
- **Grain count** is the size of the ring buffer: how many frames of history are kept.
- **Latency (grains)** is how far behind "now" the newest frame is.
- **Active: true** means a writer currently holds the flow open.

Press `Ctrl+C` to stop following the log.

## 6. Look inside the domain

The domain is just a directory of files. Open a shell in a container that mounts it:

```sh
docker compose run --rm --entrypoint bash video-flow-info
ls -la /mxl-domain
ls -la /mxl-domain/5fbec3b1-1b0f-417d-9059-8b94a47197ed.mxl-flow
cat /mxl-domain/5fbec3b1-1b0f-417d-9059-8b94a47197ed.mxl-flow/flow_def.json
ls /mxl-domain/5fbec3b1-1b0f-417d-9059-8b94a47197ed.mxl-flow/grains
mxl-info -d /mxl-domain -l
exit
```

You should find:

- one `<flow-id>.mxl-flow` directory per flow;
- `data`, the 2048-byte flow header that readers and writers memory-map;
- `flow_def.json`, an **NMOS IS-04 Flow** description (format, frame rate, size, colour);
- `grains/`, one file per ring-buffer slot, each holding a grain header and one frame.

Nothing here is a network stream. A reader maps these files read-only and gets a pointer to the
same memory the writer filled.

## 7. Stop it

```sh
docker compose down
```

Because the domain is tmpfs, the flows disappear with the volume. That is intended: live media
is not stored.

## What you just built, layer by layer

| DMF layer | In this step |
|---|---|
| Infrastructure | The CPU and RAM of your codespace or computer |
| Host Platform | The codespace's Linux VM, or the Linux VM inside Docker Desktop |
| Container Platform | Docker Engine and Docker Compose |
| Media Exchange | The MXL domain on a shared tmpfs volume |
| Media Functions | The test-source writers and the readers |
| Monitoring (vertical) | `mxl-info` printing flow health |
| Orchestration (vertical) | `docker-compose.yaml`, declaring what runs |

## If something goes wrong

| Symptom | Likely cause and fix |
|---|---|
| Build stops with "killed" or exit code 137 | Docker VM is out of memory: raise memory to 8 GB or more |
| `invalid instruction` in container logs | You are running amd64 images under emulation; rebuild locally as above |
| `bind source path does not exist: /dev/shm/mxl` | You are using a compose file with a host bind mount; use the named tmpfs volume as in the example |
| Head index stops rising | The writer container exited: `docker compose logs video-flow-writer` |

## Next

Step 2 replaces the example with our own Compose file and adds a browser monitor, so you can see
the picture instead of just the numbers.

Reference: [DMF architecture](../reference/dmf-architecture.md) ·
[MXL concepts](../reference/mxl-concepts.md)
