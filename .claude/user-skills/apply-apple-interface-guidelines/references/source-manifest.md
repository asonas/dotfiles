# Source manifest

Treat `manifest.json` as the state authority. Each page records `title`, `title_ja`, `slug`, `category`, `source_url`, `source_url_ja`, `apple_updated`, `retrieved`, `content_hash`, `status`, `supersedes`, and `related`.

Allowed states are `discovered`, `candidate`, `current`, `missing`, and `deprecated`. A fetched new or changed page becomes candidate. Promote it to current only after URL, content, frontmatter, links, and category counts validate.

Keep the existing current source when discovery or fetch fails. A page missing once becomes missing, not deprecated. Deprecate only after two consecutive update runs confirm disappearance and no redirect, canonical replacement, category move, or merge target exists.

Retain the replaced source for at least 30 days and through the next successful update. Remove or archive it only after Wiki content and Skill references no longer depend on it.

Prefer the Japanese official page when current and equivalent, but retain the English URL. Use English as authority when the Japanese version is absent, stale, or contradictory, and record the difference.

Normalize meaningful headings, prose, tables, platform considerations, and change logs before computing a SHA-256 hash. Ignore navigation, retrieval timestamps, and image-URL-only changes.

