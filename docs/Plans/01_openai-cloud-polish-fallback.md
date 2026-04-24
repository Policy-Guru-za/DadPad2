# OpenAI Cloud Polish Fallback Plan

Date: 2026-04-23
Project: PolishPad2
Status: Planned

## Goal

Add an OpenAI-backed cloud rewrite path so PolishPad remains useful on iPads that cannot run Apple Intelligence, while preserving the current on-device-first behavior on supported hardware.

Pinned model for this project:

```swift
let DEFAULT_OPENAI_MODEL = "gpt-5-nano-2025-08-07"
```

## Current state

- App has two rewrite tiers only:
  - Apple on-device `SystemLanguageModel`
  - local `RuleBasedPolisher`
- Routing is hard-coded in `PolishPad2/Services/PolishEngine.swift`
- Capability state is binary in `PolishPad2/Domain/PolishRequest.swift`
- UI copy assumes output came from either `on-device AI` or `basic local formatter`
- No backend exists yet for secure OpenAI API use

## Target behavior

Rewrite routing:

1. Use Apple on-device model when available.
2. Else use OpenAI cloud rewrite when:
   - user has opted in to cloud processing
   - network is reachable
   - backend endpoint is configured
3. Else fall back to the existing basic local formatter.

User-facing contract:

- Default app still works with no Apple Intelligence.
- User always sees which engine produced the result:
  - `On-device AI`
  - `OpenAI cloud`
  - `Basic local`
- Cloud use is explicit opt-in.
- Cloud copy states that text leaves device for processing.
- If cloud is unavailable, app remains functional via local formatting.

## Guardrails

- Do not ship an OpenAI API key in the iPad app.
- Backend proxy only for OpenAI requests.
- Pin the exact snapshot `gpt-5-nano-2025-08-07`.
- Use structured output from OpenAI so the app keeps the current `text only` contract.
- Log request IDs server-side for support/debugging.
- Keep the existing on-device path untouched for supported devices.

## Architecture

### iPad app

Add new components:

- `PolishPad2/Services/CloudPolisher.swift`
- `PolishPad2/Services/CloudPolishAPI.swift`
- `PolishPad2/Services/NetworkReachability.swift`
- `PolishPad2/AppModel/CloudPolishSettings.swift`

Extend existing types:

- `PolishPad2/Domain/PolishRequest.swift`
  - add `.cloudModel(reason: String?)` capability
  - add helpers:
    - `usesCloudModel`
    - updated `fallbackReason`
    - updated `outputBadgeText`
- `PolishPad2/Services/PolishEngine.swift`
  - inject cloud settings + reachability + cloud polisher
  - route `foundation -> cloud -> basic`
- `PolishPad2/AppModel/PolishWorkflowModel.swift`
  - surface cloud capability label in captions/status
  - expose settings-driven capability refresh
- `PolishPad2/Views/MainView.swift`
- `PolishPad2/Views/StatusBanner.swift`
  - update banner and status wording
  - add cloud-specific unavailable/offline messaging

### Backend proxy

Create a tiny server, separate from iPad target. Suggested shape:

- `server/`
  - `package.json`
  - `src/index.ts`
  - `src/openai.ts`
  - `src/schema.ts`

Single endpoint:

- `POST /v1/polish`

Request body:

```json
{
  "input": "raw text",
  "mode": "note|email|message",
  "locale": "en-ZA",
  "clientRequestID": "uuid"
}
```

Response body:

```json
{
  "text": "polished result",
  "engine": "openai-cloud",
  "model": "gpt-5-nano-2025-08-07",
  "requestID": "openai request id"
}
```

Backend config:

- `OPENAI_API_KEY`
- `DEFAULT_OPENAI_MODEL=gpt-5-nano-2025-08-07`
- `PORT`

## OpenAI request contract

Use the Responses API via backend only.

System instructions should mirror the current app contract:

- preserve writer intent
- improve grammar/spelling/punctuation/paragraphing
- avoid verbosity
- never invent facts, names, dates, promises, explanations
- return only polished text
- mode-specific instructions for `note`, `email`, `message`

Use structured output:

```json
{
  "type": "object",
  "properties": {
    "text": { "type": "string" }
  },
  "required": ["text"],
  "additionalProperties": false
}
```

## Privacy / UX plan

### First-run cloud consent

Add a lightweight sheet or alert the first time cloud fallback is needed:

- title: `Use OpenAI cloud polish?`
- body: explain that draft text is sent to a secure backend for rewriting when on-device AI is unavailable
- actions:
  - `Use cloud polish`
  - `Stay local only`

Persist choice in `UserDefaults`.

### Settings affordance

Add app setting or inline control:

- `Cloud polish`
  - on/off
- secondary copy:
  - `Uses OpenAI when Apple Intelligence is unavailable`

### Status language

Replace binary language with three-tier language:

- on-device available:
  - `Editable note output from on-device AI.`
- cloud used:
  - `Editable note output from OpenAI cloud.`
- local fallback:
  - `Editable note output from basic local formatter.`

### Failure messaging

- offline + cloud opted in:
  - `Cloud polish is unavailable offline. Using a basic local formatter instead.`
- cloud server unreachable:
  - `Cloud polish is temporarily unavailable. Using a basic local formatter instead.`
- cloud refused / invalid response:
  - `PolishPad couldn’t finish this cloud rewrite.`

## File-by-file implementation plan

### Phase 1: domain and routing

1. Update `PolishPad2/Domain/PolishRequest.swift`
   - add cloud capability case
   - update helpers and badge labels
2. Refactor `PolishPad2/Services/PolishEngine.swift`
   - inject cloud dependencies
   - separate capability detection from execution
   - preserve cancellation semantics

### Phase 2: cloud client

1. Add `CloudPolishAPI`
   - `URLSession` wrapper
   - request/response models
   - timeout + status code handling
2. Add `CloudPolisher`
   - map `PolishRequest` -> backend request
   - sanitize returned text
   - map backend/network errors -> `PolishEngineError`

### Phase 3: settings and reachability

1. Add `CloudPolishSettings`
   - opt-in state
   - endpoint availability
2. Add `NetworkReachability`
   - cheap online/offline signal
3. Refresh capability on:
   - app launch
   - settings change
   - foregrounding if needed

### Phase 4: UI updates

1. Update `PolishWorkflowModel`
   - cloud-aware captions/status
2. Update `StatusBanner`
   - cloud-specific messages
3. Add consent/settings UI in `MainView`
   - minimal, not a settings overhaul

### Phase 5: backend

1. Scaffold `server/`
2. Add `POST /v1/polish`
3. Call OpenAI Responses API with:
   - `model = DEFAULT_OPENAI_MODEL`
   - structured output
   - request ID logging
4. Add basic abuse protection:
   - max input length
   - per-IP rate limiting
   - server-side request validation

### Phase 6: verification

1. Unit tests
2. backend contract tests
3. manual iPad verification on non-eligible hardware

## Testing plan

### App unit tests

Add tests for:

- foundation eligible -> on-device path selected
- foundation ineligible + cloud opted in + online -> cloud path selected
- foundation ineligible + cloud opted out -> basic local path selected
- foundation ineligible + cloud opted in + offline -> basic local path selected
- cloud response empty -> processing error
- cloud request cancelled -> no stale UI update
- capability badge text renders correct engine

### Backend tests

Add tests for:

- valid request -> valid structured response
- invalid `mode` rejected
- overlong input rejected
- OpenAI timeout -> mapped 5xx or retryable response
- request ID propagated to logs

### Manual QA

Primary device: iPad Air 4 on iPadOS 26.

Scenarios:

1. Cloud off, no Apple Intelligence:
   - note/email/message still work via local formatter
2. Cloud on, online:
   - note/email/message use OpenAI cloud
3. Cloud on, offline:
   - graceful fallback to basic local
4. Cloud on, backend down:
   - graceful fallback to basic local
5. Apple Intelligence-capable device:
   - on-device path still wins

## Rollout sequence

1. Land domain + routing refactor behind compile-safe defaults.
2. Add backend proxy.
3. Wire app to backend behind `cloud polish` opt-in.
4. Add tests.
5. Manual test on iPad Air 4.
6. Ship with cloud off by default until consent UX is verified.

## Risks

- `gpt-5-nano-2025-08-07` is cheaper and faster, but likely weaker than larger rewrite models.
- Cloud latency may feel materially slower than on-device.
- Network reachability can flap; local fallback must remain instant and reliable.
- Without explicit consent copy, privacy expectations will be wrong.
- If backend is not added, any client-side API-key shortcut would be a security regression.

## Acceptance criteria

- App produces polished output on non-Apple-Intelligence iPads.
- Exact model pin is used server-side:

```swift
DEFAULT_OPENAI_MODEL = "gpt-5-nano-2025-08-07"
```

- No OpenAI API key exists in the iOS app bundle or source config.
- UI clearly distinguishes on-device, cloud, and local-basic output.
- Offline path still works.
- Automated tests cover routing and cloud fallback.

## Notes

- Official OpenAI docs currently list `gpt-5-nano-2025-08-07` as a valid GPT-5 nano snapshot.
- OpenAI currently recommends newer `GPT-5.4` variants for many fresh workloads, but this plan intentionally pins the snapshot requested for this app.
