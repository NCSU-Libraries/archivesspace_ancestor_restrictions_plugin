# Changelog

All notable changes to the ArchivesSpace Ancestor Restrictions Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-16

### Added
- Initial release of the plugin
- `ancestor_restrictions_apply` field added to archival object JSON responses
- Single record calculation with early exit optimization
- Batch calculation with optimized ancestor fetching (2-3 queries for entire batch)
- Level-by-level tree walking to handle deep hierarchies correctly
- Depth limit (100 levels) to prevent infinite loops
- Comprehensive RSpec test suite (17 tests, 100% pass rate)
- Full documentation including installation, usage, and API examples
- MIT License