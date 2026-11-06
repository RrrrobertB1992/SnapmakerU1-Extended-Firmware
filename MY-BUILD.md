# my-build

My own build of paxx12's SnapmakerU1-Extended-Firmware: paxx's `develop` plus my
unmerged PRs and a few local-only patches. This file lives only on the
`my-build` branch and is not meant for upstream.

- Upstream: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware (remote `upstream`)
- My fork: https://github.com/RrrrobertB1992/SnapmakerU1-Extended-Firmware (remote `fork`)
- Base: `upstream/develop` (not `main`; `main` is paxx's release branch and lags behind)
- Built with GitHub Actions on my fork: Actions → Build → Run workflow → branch `my-build`
- Firmware file I flash: `U1_extended_…_upgrade.bin` (profile `extended`, not `-afc` or `-multiace`)

## What's included

Apply in this order, on top of `upstream/develop`.

| # | Change | Source | Status | Drop when |
|---|---|---|---|---|
| 1 | Gradient multicolor spools (OpenSpool `color_type` → `MULTI_MODE`) | PR #818, branch `gradient-color-type` | open | #818 is merged |
| 2 | Internal camera exposure setting (auto/manual) | PR #862, branch `feature/internal-camera-exposure` | open | #862 is merged |
| 3 | LOCAL BUILD ONLY: apply open OpenRFID PRs #36–#39 | commit "LOCAL BUILD ONLY: apply open OpenRFID PRs #36-#39" | local only | suchmememanyskill/OpenRFID #36, #37, #38 and #39 are merged and paxx bumps OpenRFID's `GIT_SHA` |
| 4 | LOCAL BUILD ONLY: Fluidd v1.37.7 with keep-selection fix | commit "LOCAL BUILD ONLY: Fluidd v1.37.7 with keep-selection fix" (`overlays/firmware-extended/62-app-fluidd/local/fluidd.zip`) | local only | fluidd-core/fluidd #2004 is in a Fluidd release and paxx updates Fluidd to it |
| 5 | LOCAL BUILD ONLY: install Fluidd from `local/fluidd.zip` if present | commit "LOCAL BUILD ONLY: install Fluidd from local/fluidd.zip if present" | local only | together with #4 |
| 6 | This file | commit "LOCAL BUILD ONLY: add MY-BUILD.md" | local only | never |

If the Fluidd zip is rebuilt, it must be zipped like the Fluidd release zip, from the contents of `dist/`.

### Not included (on purpose)

- The old camera commits (librockit imposter, camera-before-lmd, rockit-export, flip/mirror). paxx's #876 replaced them, and it's in `develop`.
- Encoder flip/mirror. Not needed. The sensor flip controls in the camera page shouldn't be used either: if they do apply, they also flip Snapmaker's AI detection view.

## Rebuilding after upstream changes

Rebase onto the new `develop`. Commit hashes change on every rebase, so look them up by name.

```
cd ~/SnapmakerU1-Extended-Firmware
git fetch upstream
git checkout my-build
git rebase upstream/develop
git log --oneline upstream/develop..HEAD
git push --force-with-lease fork my-build
```

The log should list the commits from the table above. If a PR was merged, drop its commit during the rebase. If a conflict comes up, stop and sort it out before pushing.

When a PR branch has changed (for example after review), refresh its commit here:

```
git checkout my-build
git rebase --onto upstream/develop <old base> my-build   # or rebuild from scratch, below
```

Rebuilding from scratch:

```
git fetch upstream fork
git checkout -B my-build upstream/develop
git cherry-pick fork/gradient-color-type fork/feature/internal-camera-exposure
git cherry-pick <OpenRFID commit> <Fluidd zip commit> <Fluidd install commit> <MY-BUILD.md commit>
```

The local-only commits can be found with:

```
git log --oneline --grep="LOCAL BUILD ONLY" fork/my-build
```

## After flashing, check

- Info page shows the `my-build` version and Profile `extended`
- Tailscale connects
- Internal camera: WebRTC, MJPEG, snapshot, Snapmaker app live view, `monitor.jpg` updating
- AI detection (foreign object and spaghetti) and timelapse
- Internal Camera Exposure: Manual keeps exposure and gain from the camera controls; Auto follows the light
- OpenRFID reads multicolor and gradient spools
- Fluidd keeps the file selection when the list refreshes
