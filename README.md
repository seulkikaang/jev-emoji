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
