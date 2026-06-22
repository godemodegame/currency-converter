# Release pipeline (GitHub Actions + Fastlane)

Two triggers, one workflow ([`.github/workflows/release.yml`](../.github/workflows/release.yml)):

| Trigger | Lane | Result |
|---|---|---|
| **Merge to `main-1`** | `beta` | Archive → sign → bump build number → upload to **TestFlight**. No review submission. |
| **Push a `vX.Y.Z` tag** | `release` | Same build, but the marketing version is set from the tag, then the build is **submitted to App Store review**. |

You can also trigger either lane by hand: Actions → *Release* → **Run workflow** → pick the lane.

## Cutting a release (the tag flow)

```bash
git checkout main-1 && git pull
git tag v1.2.0      # the version users will see (must be a NEW, unreleased version)
git push origin v1.2.0
```

The tag `v1.2.0` sets `MARKETING_VERSION` to `1.2.0`, builds, uploads, and submits
that version for review.

> **Prerequisite for the tag flow:** the version's **metadata + screenshots must
> already be prepared in App Store Connect** (the `release` lane uploads the binary
> and submits, but skips metadata/screenshots). Create the new version in App Store
> Connect and fill it in before pushing the tag — otherwise the submission has
> nothing to review. (Want metadata managed from the repo too? Say so and I'll wire
> up `fastlane deliver` metadata/screenshot folders.)
>
> **Compliance answers are pre-filled** in [`Fastfile`](Fastfile): export
> compliance comes from `ITSAppUsesNonExemptEncryption=false` in
> [Info.plist](../CurrencyConverter/Info.plist), and the IDFA questionnaire is
> answered for an AdMob app (`IDFA_SUBMISSION`). Verify those match your actual
> ad usage — they're legal attestations.

---

## Setup status — already configured ✅

The one-time setup below has been done. For reference, the pieces are:

- **App Store Connect API key** (App Manager role) — `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT`.
- **Signing storage:** private repo `godemodegame/ios-certificates`, populated via
  `fastlane match appstore` (Apple Distribution cert + App Store profiles for the
  3 bundle ids), encrypted with `MATCH_PASSWORD`.
- **CI access to the certs repo:** a **read-only SSH deploy key** on
  `ios-certificates`; its private half is the `MATCH_SSH_KEY` secret, and
  `MATCH_GIT_URL` is the SSH form `git@github.com:godemodegame/ios-certificates.git`.
  The workflow writes the key to `~/.ssh` and match clones over SSH.

The 6 GitHub Actions secrets on this repo:

| Secret | What |
|---|---|
| `ASC_KEY_ID` | API Key ID |
| `ASC_ISSUER_ID` | API Issuer ID |
| `ASC_KEY_CONTENT` | base64 of the `.p8` |
| `MATCH_GIT_URL` | `git@github.com:godemodegame/ios-certificates.git` |
| `MATCH_PASSWORD` | passphrase that encrypts the match repo |
| `MATCH_SSH_KEY` | private deploy key for read access to the match repo |

> **Keep the `MATCH_PASSWORD` safe** (password manager). You need it to run match
> locally again — e.g. to renew the certificate or add the cert on another Mac.

### Re-running match locally (renewals, new Mac)

```bash
cd /Users/godemodegame/Documents/currency-converter
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"   # fastlane needs Ruby 3.x, not system 2.6
bundle install

export MATCH_GIT_URL="https://github.com/godemodegame/ios-certificates.git"  # https is fine locally
export MATCH_PASSWORD="<your saved passphrase>"
bundle exec fastlane match appstore \
  --api_key_path /path/to/asc_api_key.json   # {key_id, issuer_id, key, in_house:false}
```

---

## Run it / verify

- **TestFlight:** merge a PR into `main-1` (or Actions → *Release* → Run workflow → `beta`).
- **App Store review:** push a `vX.Y.Z` tag (or Run workflow → `release`).

A TestFlight build appears in App Store Connect → TestFlight a few minutes after the
run goes green (StoreKit processing). The `release` lane additionally waits for that
processing before submitting, so it runs longer.

## Notes

- **Build number** = the GitHub Actions run number (monotonic, never collides).
- **Marketing version** = the git tag on the `release` flow (`v1.2.0` → `1.2.0`).
  On the `beta` flow it stays at the project's current `MARKETING_VERSION`.
- This is separate from [`ci.yml`](../.github/workflows/ci.yml) (the
  unsigned build + logic tests on every PR), so PR feedback stays fast.
- Run a lane locally with the same env vars: `bundle exec fastlane beta`
  (it skips `setup_ci`'s temporary keychain when not on CI). For a local `release`
  dry run, also set `APP_VERSION=1.2.0`.
- Pushing a commit and a tag together (`git push --follow-tags`) fires **two** runs
  — `beta` for the branch and `release` for the tag. Push the tag on its own if you
  want only the review submission.
