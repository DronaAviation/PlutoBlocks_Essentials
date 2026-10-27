# PlutoBlocks Essentials

The Pluto C++ library and the ARM build tools that the PlutoBlocks app downloads to build and flash C++ projects. The app reads this repo's releases and `plutoblocks.json`. Nothing here ships inside the app.

## What's here

| Path | What it is |
| --- | --- |
| `magis-lib/` | Library for **PrimusX** and **PrimusV4**: `API/`, `PlutoPilot.h`, `version` |
| `magisv2-lib/` | Library for **PrimusX2** and **PrimusV5**: `API/`, `PlutoPilot.h`, `lib/Version/`, `version` |
| `ld/` | Linker scripts |
| `Makefile` | The reference build; the app runs the same steps without `make` |
| `version` | `Repo_Version`: the library version, matching the release tag |
| `families.json` | The boards each library folder builds for |
| `plutoblocks.json` | Which library version the app gives each board family |

The compiled libraries (`lib<TARGET>_<FW>.a`, 85–160 MB each) are too big for git. They live only in the releases, inside `Pluto_Libs_v<version>.zip`.

## Releases

| Release | Assets |
| --- | --- |
| `v<version>` (e.g. `v3.0.1`) | `Pluto_Libs_v<version>.zip`, built by the **Release library** action |
| `v1.0.0` (build tools) | `mac_gcc_arm64_toolchain.zip` (ARM GCC 14.2.1, Apple Silicon), `windows_gcc_toolchain.zip` (ARM GCC 14.2.1, Windows x64), and `Pluto_Libs_v3.0.0.zip` |

The app takes the build tools from the newest release that has them, by these exact file names. Don't rename or delete them: every installed copy of PlutoBlocks relies on them.

To publish a new library version, see [RELEASING.md](RELEASING.md).

## How the app picks a version

`plutoblocks.json` on `main` names a library version for each board family:

```json
{ "magis-lib": "3.0.0", "magisv2-lib": "3.0.0" }
```

The app checks it when it starts and installs the named version in the background. It finds that version by the zip's name (`Pluto_Libs_v3.0.0.zip`) on any release. A family can move to an older version the same way. If the file is missing or broken, the app keeps its last good choice. Students can go back one version in Settings › Tools.

An optional `"toolchain": "<release tag>"` pins the build tools to one release.
