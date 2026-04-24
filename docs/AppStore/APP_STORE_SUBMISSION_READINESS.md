# PolishPad App Store Submission Readiness

## Positioning

PolishPad is a private iPad writing utility that helps users turn rough typed or dictated text into clearer notes, emails, and messages.

Do not describe PolishPad as stroke, rehabilitation, therapy, clinical, medical device, patient treatment, diagnosis, recovery, or aphasia treatment software.

## Privacy and Support Links

- Privacy Policy: `https://redcliffebay.com/polishpad/privacy`
- Support: `https://redcliffebay.com/polishpad/support`
- Support email configured in app: `support@redcliffebay.com`

The in-app constants live in `PolishPad2/Views/AboutSheet.swift`.

Public page source drafts:

- Privacy Policy: `docs/AppStore/PRIVACY_POLICY.md`
- Support: `docs/AppStore/SUPPORT.md`
- App Store metadata pack: `docs/AppStore/APP_STORE_METADATA.md`

## App Review Notes Draft

PolishPad is an iPad-first writing utility. A user enters text manually or by using standard iPad keyboard dictation, then taps Note, Email, or Text to rewrite the draft into editable output.

No account, login, backend, demo credentials, subscription, or external service is required. The app uses Apple's on-device Foundation Models framework when available. If the on-device model is unavailable, the app falls back to a basic local formatter so the app remains usable.

Suggested review flow:

1. Type or dictate rough text into Draft.
2. Tap Polish for note, Polish for email, and Polish for text.
3. Switch between Draft and Result.
4. Edit the result if desired.
5. Test Copy, Share, Undo, Retry on an error state, and Clear.
6. If testing without on-device model availability, confirm the fallback banner and basic local output.

## App Privacy Label Direction

Intended answer for the current shipped architecture: data is not collected by the developer.

This depends on the app continuing to have no accounts, no backend, no analytics, no advertising, no third-party tracking, no crash logs containing user text, and no server-side AI. Legal review is required before final submission.

## Accessibility Label Caution

Do not claim App Store accessibility support fields until verified on device or simulator. Minimum checks: VoiceOver, Larger Text, contrast, tap targets, keyboard focus, landscape, Split View, and Reduced Motion.

## Pre-Submission Checklist

- Publish `docs/AppStore/PRIVACY_POLICY.md` at `https://redcliffebay.com/polishpad/privacy`.
- Publish `docs/AppStore/SUPPORT.md` at `https://redcliffebay.com/polishpad/support`.
- Replace `[INSERT DATE]` and `[INSERT SUPPORT EMAIL]` before publishing.
- Confirm `support@redcliffebay.com` exists or update `PolishPad2/Views/AboutSheet.swift` to the final support email.
- Confirm app icon renders in the built app and archive validation has no icon warnings.
- Capture accurate iPad screenshots from the final build.
- Confirm App Privacy details match the final shipped architecture.
- Enter App Store metadata from `docs/AppStore/APP_STORE_METADATA.md`.
- Confirm age rating, category, pricing, availability, and support URL in App Store Connect.
- Run a signed Release archive and upload validation with the production Apple Developer team.
