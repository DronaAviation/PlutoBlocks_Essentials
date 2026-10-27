# Publishing a library version

For the firmware team. A new version takes four steps, and the app picks it up only at the last one, so nothing reaches students early.

## 1. Commit the library files

On a branch (then merge to `main`), or straight to `main`:

- Update the headers in `magis-lib/API/` and `magisv2-lib/API/` and anything else that changed.
- Set the new firmware version in the `version` file of each family that changed:
  ```
  FW_Version = 3.0.1
  API_Version = 1.0.0
  ```
- Set the library version in the top-level `version` file: `Repo_Version = 3.0.1`.
- Don't commit `.a` files. Git refuses them (`.gitignore`), and the **Check** action fails if one gets in.

The **Check** action runs on every push. It fails if a family's `version`, `API/` or `PlutoPilot.h` is missing.

## 2. Build the `.a` files

Build one per board, named `lib<TARGET>_<FW_Version>.a` with that family's `FW_Version`:

| Family | Boards (`TARGET`) |
| --- | --- |
| `magis-lib` | `PRIMUSX`, `PRIMUSV4` |
| `magisv2-lib` | `PRIMUS_X2_v1`, `PRIMUS_V5` |

For 3.0.1, with `magisv2-lib` at firmware 3.0.1 and `magis-lib` unchanged at 2.0.1, that's `libPRIMUSX_2.0.1.a`, `libPRIMUSV4_2.0.1.a`, `libPRIMUS_X2_v1_3.0.1.a` and `libPRIMUS_V5_3.0.1.a`. Every release carries all four, even for a family that didn't change. Adding a board means adding it to `families.json` (and to the app).

To list the exact names for a version:

```bash
bash .github/scripts/library.sh expect 3.0.1
```

## 3. Publish the release

On GitHub: **Releases › Draft a new release**.
- **Tag:** `v3.0.1` on `main` (the same number as `Repo_Version`)
- **Title:** `v3.0.1`
- **Notes:** what changed for each family. The app shows these notes as the library's changelog ("What's new").
- **Attach** the four `.a` files.
- Click **Publish release**.

Or from a terminal:

```bash
gh release create v3.0.1 --target main --title v3.0.1 --notes-file notes.md \
  libPRIMUSX_2.0.1.a libPRIMUSV4_2.0.1.a libPRIMUS_X2_v1_3.0.1.a libPRIMUS_V5_3.0.1.a
```

The **Release library** action then:
1. checks out the tag and checks that `version` says `Repo_Version = 3.0.1`;
2. waits until all four `.a` files are uploaded, and fails if any is missing or extra;
3. builds `Pluto_Libs_v3.0.1.zip` from the tagged files and the `.a` files;
4. attaches the zip and removes the loose `.a` files.

If it fails, its log says why. Fix the problem (re-upload a file, or move the tag), then run it again from **Actions › Release library › Run workflow** with the tag.

Don't mark the release as a pre-release or leave it as a draft. The app skips both.

## 4. Roll it out

The app doesn't use the new version until `plutoblocks.json` names it. Edit it on `main`:

```json
{ "magis-lib": "3.0.0", "magisv2-lib": "3.0.1" }
```

Each app moves to it on its next launch and keeps the previous version for going back. To roll back for everyone, set the old version again.

A published version that `plutoblocks.json` doesn't name reaches nobody, so a release can sit there until you've checked its zip.
