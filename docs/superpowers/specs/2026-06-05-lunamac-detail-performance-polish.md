# LunaMac Detail And Performance Polish

## Goal

Polish LunaMac detail pages so they feel native, centered, and consistent with the Home hero, while removing a known wasted catalog-loading pass that contributes to slow startup.

## Approved Direction

Use the native centered layout shown in the visual companion. The page keeps the current cinematic backdrop/header but constrains all actionable content to a centered readable rail. This fixes episode rows appearing pinned to the far-left edge without redesigning the full app.

## Detail Page Layout

- Keep the full-window detail page with a visible back button.
- Use a centered max-width content container for hero metadata, actions, overview, genres, cast, season tabs, and episode rows.
- Preserve the current dark native macOS visual language.
- Replace purple emphasis on detail actions with neutral native styling: white primary play button, dark secondary icon buttons, green only for watched state.
- Keep episode cards horizontal, but align them with the same centered content rail as the rest of the page.

## Artwork Handling

- Detail poster should use the same broad artwork fallback philosophy as Home/AIO metadata.
- For top-level metadata, prefer resolved poster, then AIO raw poster, then `img`, then `image`.
- For episode artwork, normalize season episode data so `thumbnail`, `still`, `img`, and `image` can all produce `MetaVideo.thumbnail`.
- Keep existing placeholders when no artwork is available.

## Performance Fix

- Remove the wasted home startup sequence where `MacHomeView` loads system addon catalogs and then immediately calls `loadFromCollections`, which clears/replaces those rows.
- Home should load collection-backed rows once, using enabled addons and the system addon fallback already fetched during startup.
- Do not add broad caching or new infrastructure in this pass; keep the fix targeted and measurable.

## Testing And Verification

- Add or update model parsing tests for season episode artwork alias normalization.
- Keep existing player visibility tests passing.
- Build LunaMac with `xcodebuild -project Apps/LunaMac/LunaMac.xcodeproj -scheme LunaMac -configuration Debug build`.
- Manually verify detail pages for one movie and one series: centered content, neutral buttons, episode artwork, back button, and source picker/player launch.

## Out Of Scope

- Rebuilding the whole detail page into a new navigation architecture.
- Adding a new image cache/downsampler.
- Replacing the source picker sheet.
- Vendoring KSPlayer/FFmpegKit.
