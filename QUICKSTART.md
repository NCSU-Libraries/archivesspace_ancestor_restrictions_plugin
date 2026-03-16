# Quick Start Guide

## Installation (5 minutes)

### 1. Get the Plugin

**Option A: Clone from GitHub**
```bash
cd /path/to/archivesspace/plugins
git clone https://github.com/YOUR_USERNAME/archivesspace-ancestor-restrictions.git ancestor_restrictions
```

**Option B: Download ZIP**
- Download the latest release from GitHub
- Extract to `/path/to/archivesspace/plugins/ancestor_restrictions`

### 2. Enable the Plugin

Edit `config/config.rb` (create if it doesn't exist):

```ruby
AppConfig[:plugins] = ['ancestor_restrictions']
```

If you already have plugins enabled:
```ruby
AppConfig[:plugins] = ['existing_plugin', 'ancestor_restrictions']
```

### 3. Restart ArchivesSpace

```bash
./archivesspace.sh stop
./archivesspace.sh start
```

Look for this in the logs:
```
INFO -- : Loaded plugin: ancestor_restrictions
```

## Usage

The `ancestor_restrictions_apply` field now appears in all archival object API responses.

### Quick Test

```bash
# Authenticate
curl -X POST http://localhost:8089/users/admin/login \
     -d "password=admin" \
     | jq -r '.session'

# Get any archival object
curl -H "X-ArchivesSpace-Session: SESSION_TOKEN" \
     http://localhost:8089/repositories/2/archival_objects/1 \
     | jq '.ancestor_restrictions_apply'
```

## What It Does

The field is `true` when:
- The root resource has `restrictions: true`, OR
- ANY parent archival object has `restrictions_apply: true`

The field is `false` when:
- No ancestors have restrictions

## Examples

### Scenario 1: Resource with restrictions
```
Resource (restrictions: true)
└── Series (restrictions_apply: false)
    └── File (restrictions_apply: false)
```
**Result**: File has `ancestor_restrictions_apply: true`

### Scenario 2: Parent with restrictions
```
Resource (restrictions: false)
└── Series (restrictions_apply: true)
    └── File (restrictions_apply: false)
```
**Result**: File has `ancestor_restrictions_apply: true`

### Scenario 3: No restrictions
```
Resource (restrictions: false)
└── Series (restrictions_apply: false)
    └── File (restrictions_apply: false)
```
**Result**: File has `ancestor_restrictions_apply: false`

## Performance

- **Single records**: ~2-5 queries (one per level, early exit on first match)
- **Batch operations**: ~4 queries total regardless of batch size
- **Deep hierarchies**: Handles unlimited depth (100 level safety limit)

## Testing

Copy spec to backend and run tests:

```bash
cp plugins/ancestor_restrictions/spec/archival_object_restrictions_spec.rb backend/spec/
build/run backend:test -Dspec='archival_object_restrictions_spec.rb'
```

Expected result:
```
17 examples, 0 failures
```

## Troubleshooting

### Plugin not loading
- Check `config/config.rb` has the plugin enabled
- Look for errors in `logs/archivesspace.out`
- Ensure directory name is exactly `ancestor_restrictions`

### Field not appearing
- Clear browser cache
- Restart ArchivesSpace backend
- Check plugin is listed in startup logs

### Performance issues
- Check database query logs
- Ensure indexes exist on `parent_id` and `root_record_id` columns
- Contact maintainer with details

## Support

- **Issues**: https://github.com/YOUR_USERNAME/archivesspace-ancestor-restrictions/issues
- **Docs**: See README.md for full documentation
- **Community**: ArchivesSpace Google Group

## Code Stats

- **Total code**: ~700 lines
- **Implementation**: ~190 lines
- **Tests**: ~515 lines
- **Test coverage**: 17 comprehensive tests
- **Dependencies**: None (uses core ArchivesSpace libraries only)
