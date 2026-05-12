Guide audio can now be generated automatically.

Run:

- `npm run generate-guide-audio`
- `npm run render-guide`

This will create assets in `public/audio/generated/guide/`:

- `audio/generated/guide/music/season-1-bed.mp3`
- `audio/generated/guide/voice/*.mp3`
- `audio/generated/guide/sfx/*.wav`

The manual promo paths below are still available if you want to override or build a separate short ad manually.

Manual promo asset paths:

- `audio/music/startup-cinematic-bed.mp3`
- `audio/voice-over/00-hook.mp3`
- `audio/voice-over/01-problem-spread.mp3`
- `audio/voice-over/02-problem-fatigue.mp3`
- `audio/voice-over/03-solution-core.mp3`
- `audio/voice-over/04-solution-flow.mp3`
- `audio/voice-over/05-solution-assets.mp3`
- `audio/voice-over/06-feature-dashboard.mp3`
- `audio/voice-over/07-feature-transactions.mp3`
- `audio/voice-over/08-feature-stats.mp3`
- `audio/voice-over/09-feature-trust.mp3`
- `audio/voice-over/10-emotion-control.mp3`
- `audio/voice-over/11-emotion-clarity.mp3`
- `audio/voice-over/12-call-to-action.mp3`
- `audio/sfx/transition-whoosh.wav`
- `audio/sfx/swipe-soft.wav`
- `audio/sfx/click-soft.wav`
- `audio/sfx/solution-ping.wav`
- `audio/sfx/stat-ping.wav`
- `audio/sfx/benefit-ping.wav`
- `audio/sfx/cta-ping.wav`

Assets are intentionally disabled by default in `src/data/audio-plan.json`.
Set `enabled` to `true` per track once the real files are in place.
