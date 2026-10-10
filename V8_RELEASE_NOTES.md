# Mystery Escape’s V8 — Release candidate (partial implementation)

## Implemented in this archive
- V7 source incorporated directly on top of V6, including interactive clock corrections and readability changes.
- 100 main cases retained, plus 30 extra junior case records (50 junior total). The new junior puzzles are basic and require editorial/playability review.
- Deterministic 365-day schedule for the daily challenge. A day chooses one of 100 existing cases; **not 365 unique authored puzzles**. Local date rollover applies when opening the daily challenge.
- Offline service configuration scaffolding with online rankings, ads, IAP, cosmetics, lives all disabled. No actual payment, advertising, or networking SDK is integrated.
- Static V8 audit and blocking GitHub Actions gate before iOS build.

## Not completed / must not be represented as complete
- Full manual review of every puzzle solution, originality, and difficulty; replacing all easy puzzles.
- Weekly event, 365 original challenges, complete chain logic for impossible mode, fully illustrated junior levels, online backend, IAP, ads, and advanced audio work.
- Godot headless runtime validation locally (Godot binary unavailable), real touch testing, audio verification on iPhone, and installation test.
- Automated UI screenshot checks and save migration using actual historic iPhone save files.

## Safety and compatibility
Keep the same bundle identifier and legacy user:// save filename. Back up the V6 project and an iPhone save before updating. Test installing the unsigned IPA with your existing personal test workflow. No real monetization is enabled.
