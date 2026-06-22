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

## One-time setup

Do these once; afterwards every merge just works.

### 1. App Store Connect API key

App Store Connect → **Users and Access → Integrations → App Store Connect API**
→ create a **Team Key** with the **App Manager** role. Download the `.p8`
(one-time download). Note the **Key ID** and the **Issuer ID** at the top.

Base64-encode the key (no newline):

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy   # this is ASC_KEY_CONTENT
```

### 2. A private repo for `fastlane match`

`match` stores your **distribution certificate + App Store provisioning profiles**
encrypted in a git repo. Create an **empty private** repo (e.g.
`godemodegame/ios-certificates`).

Populate it once from your Mac (this creates the cert + the three profiles in
your Apple account and pushes them encrypted):

```bash
cd /Users/godemodegame/Documents/currency-converter
bundle install

export MATCH_GIT_URL="https://github.com/godemodegame/ios-certificates.git"
export MATCH_PASSWORD="choose-a-strong-passphrase"   # encrypts the repo contents
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_KEY_CONTENT="$(base64 -i AuthKey_XXXXXXXXXX.p8)"

# Read-write here (drops the readonly the CI lane uses) so it can mint + store them:
bundle exec fastlane match appstore
```

> If you already have an App Store distribution certificate you want to keep,
> run `fastlane match import` instead so match adopts it rather than creating a new one.

### 3. GitHub repo secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|---|---|
| `ASC_KEY_ID` | the Key ID from step 1 |
| `ASC_ISSUER_ID` | the Issuer ID from step 1 |
| `ASC_KEY_CONTENT` | base64 of the `.p8` (step 1) |
| `MATCH_GIT_URL` | `https://github.com/godemodegame/ios-certificates.git` |
| `MATCH_PASSWORD` | the passphrase from step 2 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `base64 -i <(printf 'USER:GHP_TOKEN')` — a PAT with read access to the certs repo, so CI can clone it over HTTPS |

`MATCH_GIT_BASIC_AUTHORIZATION` example:

```bash
printf 'godemodegame:ghp_yourPAT' | base64   # paste result as the secret
```

(Use a fine-grained PAT scoped to **read-only Contents** on the certs repo.)

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
