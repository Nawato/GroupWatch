# Changelog

All notable changes to GroupWatch are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2026-11-21

### Added

- Per-list auto actions for direct party invites: auto accept or auto
  decline, with chat feedback, the list sound, and a session kill switch
  when the client blocks the call.
- Group Finder applicant integration: applicant rows and tooltips show
  the lists and notes for that player, role fit is checked against the
  active listing, and manual Invite/Decline buttons are provided for
  matching applicants.
- Custom user sound files in `Sounds/`, with runtime registration,
  preview, and a missing-file fallback.
- EllesmereUI-style appearance with a matching built-in fallback theme,
  live accent updates, and a real scrollbar.
- Multilingual support for nine client locales.

### Changed

- Realms are normalized through `GetNormalizedRealmName` when the client
  provides it, with `GetRealmName` as fallback.
- Skinning lookups are cached per refresh, and pooled widgets reuse their
  data tables.
- The drag drop-target hit test runs every second frame while dragging.

### Fixed

- Context menus and tooltips no longer throw on nil names, realms, or
  unexpected context data from guild, community, party, raid, friends,
  chat and LFG sources.
- Corrupted saved variables are repaired on load instead of throwing.
- User-defined alert messages containing stray `%` characters no longer
  break roster updates.

[0.6.0]: https://github.com/Nawato/GroupWatch/compare/edc68d9...v0.6.0
