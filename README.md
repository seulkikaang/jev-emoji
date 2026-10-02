# JEV Emoji for macOS

A lightweight menu bar emoji picker that asks Jev through TypeSafe directly or Vercel AI Gateway to rank emoji from your current text or search query.

## Build and open

Requires macOS 13 or newer and Xcode Command Line Tools.

```sh
./scripts/build-app.sh
open "build/JEV Emoji.app"
```

The app appears in the menu bar. Open it with **Option + Command + E**. Type a feeling, situation, or sentence to ask Jev for ten fitting emoji. Press **Return** to insert the first result, or click any emoji.

For local development, you can set `CODE_SIGN_IDENTITY` to an existing Apple signing identity when running `./scripts/build-app.sh`. The script signs the app and verifies the signature. Using the same identity across rebuilds helps macOS recognize the app for permissions and Keychain access; permissions still need to be granted normally. Without this variable, the build has no Apple development or Developer ID signature. An Apple Development signature does not complete signing and notarization for public distribution.

## Context suggestions and insertion

Allow **JEV Emoji** under **System Settings → Privacy & Security → Accessibility**. The app reads selected text or up to 140 characters in the current paragraph before the cursor. At the start of a paragraph it reads the following text instead. That text is sent to the provider selected in settings for Jev evaluation. Picking an emoji pastes it into the previous app and restores the clipboard contents shortly afterward.

The context card shows the source app and the actual captured text. If the editor does not expose its caret, the app explicitly reports that and labels the fallback as popular emoji. Select a sentence and reopen, or use manual search. Context is captured when opening the picker, not continuously while typing.

Notion/Electron accessibility is enabled before capture. Standard text ranges use the focused input's value when range-string lookup is unsupported; browser text markers provide a bounded fallback without reading unrelated page regions. Secure inputs are excluded. Network loading, successful Jev rankings, and fallback suggestions have distinct states.

Without this permission, the picker and manual search still work; it cannot read the other app's text or insert into it.

## Jev connection

Settings let you choose **Vercel AI Gateway** (the existing default) or **TypeSafe**. Each provider has its own keychain entry: `AI_GATEWAY_API_KEY` or `TYPESAFE_API_KEY`, under service `com.jev.emoji`. Switching providers preserves both keys; saving or deleting applies only to the selected provider. Keys are never bundled with the app. Switching cancels outstanding recommendations.

- Vercel: `https://ai-gateway.vercel.sh/v1/evaluate`, model `typesafe-ai/jev`.
- TypeSafe: `https://api.typesafe.ai/v1/systemone`, model `jev-latest`.

Both send a typed choice question, the 87 emoji candidate descriptions, and at most 140 characters of the query/context. The top ten are ranked by returned probabilities; this does not guarantee ten equally relevant answers. Responses must contain a valid choice and the complete probability distribution. Requests time out after eight seconds.

As of **2026-10-01**, TypeSafe advertises $42 per billion input tokens ($0.042 per million). At that rate, a 4,610-input-token request is an **estimate** of $0.00019362; an earlier successful Gateway response reported $0, which is not proof that every request is free. Provider pricing and access policies can differ. A $5 key budget is a spending cap, not purchased credit. Gateway free accounts have returned 403 for Jev; the app distinguishes this from an invalid key (401). Confirm current pricing and account eligibility with [TypeSafe](https://typesafe.ai/) and [Vercel pricing](https://vercel.com/docs/ai-gateway/pricing).

## Distribution

This is a native macOS app. GitHub publishes its source or a packaged release; it does not host the app as a website. The local build is not signed with a Developer ID or notarized for public distribution. Public releases need an appropriate signing/notarization process; do not publish personal API keys in source or binaries. Each installation should register its own provider key.

Accessibility references: [Electron](https://www.electronjs.org/docs/latest/tutorial/accessibility), [Chromium text markers](https://github.com/chromium/chromium/blob/main/ui/accessibility/platform/browser_accessibility_cocoa.mm).

## Get the source and build on your Mac

This build script targets Apple Silicon (arm64). You need macOS 13 or later, Git and Xcode Command Line Tools. Intel builds are not provided by this script.

```sh
git clone https://github.com/seulkikaang/jev-emoji.git
cd jev-emoji
./scripts/build-app.sh
```

Then open `build/JEV Emoji.app`. Open the picker's settings, choose TypeSafe or Vercel AI Gateway and register your own provider API key. Grant Accessibility permission in System Settings to let the app read your active editor's current text. Keys are saved locally in Keychain and are not included in a published ZIP.

## Download a developer preview

1. Open this repository's **Releases** page.
2. Choose a release explicitly labeled **developer preview**, then download its Apple Silicon ZIP under **Assets**.
3. Extract the ZIP to find `JEV Emoji.app`.

The preview has not completed Developer ID signing and Apple notarization. A local ad-hoc signature or successful build does not complete these distribution steps. macOS may block an internet-downloaded preview. Do not disable system-wide security controls. Developers can inspect the source and build locally instead. Download availability is not a guarantee of installation or Accessibility permissions on another Mac.

## Publish your own source repository

Install GitHub CLI from its official instructions (`https://cli.github.com/`) and authenticate your own account:

```sh
gh auth login
gh auth status
```

For a new local project without Git history or an existing remote, initialize Git and create your own public repository:

```sh
git init -b main
gh repo create YOUR_ACCOUNT/YOUR_REPOSITORY --public --source=. --remote=origin
```

These are examples, not commands executed on this existing project. Replace the account and repository placeholders before use, review public visibility and inspect your local files first. Do not run them inside an already configured repository. This project already has a repository, so the lecture uses `gh repo view seulkikaang/jev-emoji` and updates the existing repository instead of creating another one.

Check your current branch and remote before uploading:

```sh
git branch --show-current
git remote -v
```

Before uploading, inspect the file list and exclude API keys, credentials, personal captures, local builds, model files and videos through `.gitignore`. Review your changes:

```sh
git status --short
git diff -- README.md
git diff --check
```

For a reviewed README-only change, select that file and check the selection:

```sh
git add README.md
git diff --cached -- README.md
git status --short
```

Save the selected change and send it to your own repository's branch:

```sh
git commit -m "docs: explain source and preview publication"
git push origin main
```

These commands assume your remote is named `origin`, your branch is `main`, and you have permission to push. Open GitHub afterward and confirm the commit and README actually appear. GitHub stores the source; it does not turn this native Mac app into a website.

## Publish an app file as a GitHub Release

The default build script does not sign unless `CODE_SIGN_IDENTITY` is supplied. For a separate local developer preview you can explicitly apply an ad-hoc signature before verification:

```sh
codesign --force --sign - --identifier com.jev.emoji "build/JEV Emoji.app"
```

An ad-hoc signature does not identify an Apple-approved developer or notarize the app. Signing/replacing an app can require macOS permissions to be granted again. The lecture packages the already verified current app without rebuilding or signing it again. After your build has a valid signature, package it as a ZIP:

```sh
codesign --verify --strict --verbose=2 "build/JEV Emoji.app"
ditto -c -k --sequesterRsrc --keepParent "build/JEV Emoji.app" "build/JEV-Emoji-arm64-developer-preview.zip"
shasum -a 256 "build/JEV-Emoji-arm64-developer-preview.zip"
```

With authenticated GitHub CLI, save the release notes in a text file and publish a new preview using:

```sh
gh release create YOUR_NEW_TAG build/JEV-Emoji-arm64-developer-preview.zip --repo YOUR_ACCOUNT/YOUR_REPOSITORY --target YOUR_REVIEWED_COMMIT --title "Developer preview" --notes-file YOUR_NOTES_FILE --prerelease
```

Replace the placeholders with your own new tag, repository, reviewed commit and notes path. The lecture uses the existing `seulkikaang/jev-emoji` repository and a new `v0.1.1` preview; it does not create a duplicate repository. State the supported Mac architecture and macOS version, the provider-key requirement and the current signing/notarization status. Verify the published page and download the asset once; compare its SHA-256 with the ZIP you uploaded.

Publishing a source commit and publishing a Release are separate operations. Ordinary user distribution also needs the appropriate Apple signing/notarization process, which this preview has not completed.
