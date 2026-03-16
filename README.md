# ArchivesSpace Ancestor Restrictions Plugin

An ArchivesSpace plugin that adds an `ancestor_restrictions_apply` field to archival object JSON responses, indicating whether any ancestor (parent archival objects or root resource) has restrictions applied.

## Features

- 🔍 **Automatic Detection**: Checks entire ancestry chain for restrictions
- ⚡ **Optimized Performance**: Efficient queries for both single records and batch operations
- 🔒 **Read-only Field**: Calculated dynamically, no database changes required
- 📊 **Comprehensive Testing**: Full RSpec test suite included
- 🎯 **API Integration**: Works seamlessly with existing ArchivesSpace API endpoints

## Use Case

This plugin is useful when you need to know if an archival object inherits restrictions from any ancestor in its hierarchy, without having to manually traverse the entire tree structure via the API.

### Example Scenario

```
Resource (restrictions: true)
└── Series (restrictions_apply: false)
    └── Subseries (restrictions_apply: false)
        └── File (restrictions_apply: false)
```

With this plugin, the File will have `ancestor_restrictions_apply: true`, indicating it inherits restrictions from the root Resource.

## Installation

### 1. Download the Plugin

```bash
cd /path/to/archivesspace/plugins
git clone https://github.com/YOUR_USERNAME/archivesspace-ancestor-restrictions.git ancestor_restrictions
```

Or download and extract the ZIP file to your `plugins/` directory.

### 2. Enable the Plugin

Edit your `config/config.rb` file and add the plugin to the plugins list:

```ruby
AppConfig[:plugins] = ['other_plugins', 'ancestor_restrictions']
```

### 3. Restart ArchivesSpace

```bash
# Stop ArchivesSpace
./archivesspace.sh stop

# Start ArchivesSpace
./archivesspace.sh start
```

## Usage

Once installed, the `ancestor_restrictions_apply` field will automatically appear in all archival object JSON responses.

### API Example

```bash
# Authenticate
curl -s -X POST \
  http://localhost:8089/users/admin/login \
  -d "password=admin" | jq -r '.session'

# Get an archival object
curl -s -H "X-ArchivesSpace-Session: YOUR_SESSION_TOKEN" \
  http://localhost:8089/repositories/2/archival_objects/1 | \
  jq '.ancestor_restrictions_apply'
```

### Response Example

```json
{
  "uri": "/repositories/2/archival_objects/123",
  "title": "Correspondence",
  "level": "file",
  "restrictions_apply": false,
  "ancestor_restrictions_apply": true,
  "resource": {
    "ref": "/repositories/2/resources/1"
  },
  "parent": {
    "ref": "/repositories/2/archival_objects/100"
  }
}
```

## How It Works

The plugin:

1. Extends the archival object schema to include the `ancestor_restrictions_apply` field (readonly)
2. Checks the root resource's `restrictions` field (note: resources use `restrictions`, not `restrictions_apply`)
3. Walks up the parent chain checking each archival object's `restrictions_apply` field
4. For batch operations (like `/children` endpoints), recursively fetches ALL ancestors in an optimized way
5. Returns the calculated value in the JSON response

### Performance Optimization

- **Single record queries**: Iterative approach with early exit (stops at first restricted ancestor)
- **Batch operations**: 
  - Walks up the tree level-by-level to collect ALL ancestor IDs (handles deep hierarchies correctly)
  - Fetches all ancestors in 2-3 queries total
  - Uses in-memory lookups for fast restriction checking
  - Employs caching to prevent redundant calculations for records with shared ancestors
- **Depth limit**: 100 levels maximum to prevent infinite loops

**Example**: For 100 records with average 3-level hierarchy:
- Old approach would make ~400 queries
- New approach makes ~4 queries

## Testing

### Backend RSpec Tests

The plugin includes comprehensive RSpec tests (`spec/archival_object_restrictions_spec.rb`).

To run them:

```bash
# Copy the spec file to backend/spec directory
cp plugins/ancestor_restrictions/spec/archival_object_restrictions_spec.rb backend/spec/

# Run the plugin specs using ArchivesSpace's build system
build/run backend:test -Dspec='archival_object_restrictions_spec.rb'
```

**Test Coverage:**
- ✅ Resource-level restrictions inheritance
- ✅ Parent archival object restrictions inheritance  
- ✅ Multi-level hierarchies (4+ levels deep)
- ✅ Batch operations with shared ancestors
- ✅ Large batch operations (20+ records)
- ✅ Edge cases: missing parents, depth limits, empty batches
- ✅ Integration with JSON model serialization
- ✅ Early exit optimization verification

**Test Results**: 17 examples, 0 failures

### Manual Testing

Python test scripts are included in the repository for interactive testing scenarios.

## Technical Details

### Files Structure

```
ancestor_restrictions/
├── LICENSE
├── README.md
├── .gitignore
├── backend/
│   ├── model/
│   │   └── archival_object_restrictions.rb  # Core calculation logic
│   └── plugin_init.rb                        # Plugin integration hook
├── schemas/
│   └── archival_object_ext.rb                # Schema extension
└── spec/
    └── archival_object_restrictions_spec.rb  # RSpec tests
```

### Implementation Approach

The plugin follows the same pattern as ArchivesSpace's built-in `has_unpublished_ancestor` field:

1. **Schema Extension** (`schemas/archival_object_ext.rb`): Adds readonly boolean field
2. **Calculation Module** (`backend/model/archival_object_restrictions.rb`): Contains the logic for both single and batch calculations
3. **Integration Hook** (`backend/plugin_init.rb`): Uses `class_eval` to inject the field into JSON responses

### Key Methods

- `calculate_ancestor_restrictions_apply(obj)` - Single record calculation (iterative with early exit)
- `calculate_ancestor_restrictions_apply_batch(objs)` - Batch processing with optimized queries
- `collect_all_ancestor_ids(objs)` - Fetches ALL ancestors level-by-level for deep hierarchies

## Compatibility

- **ArchivesSpace Version**: v3.0+ (tested on v4.0.0-dev)
- **Database**: MySQL, PostgreSQL (any database supported by ArchivesSpace)
- **Ruby/JRuby**: 9.4.x+

## Migration from Local Plugin

If you have been using this plugin in `plugins/local/`, you can migrate to the standalone version:

1. Disable the local plugin by removing relevant files from `plugins/local/`
2. Install this standalone plugin as described above
3. The data model is identical, so no database changes are needed

## Troubleshooting

### Plugin Not Loading

Check your ArchivesSpace logs for errors:

```bash
tail -f logs/archivesspace.out
```

Ensure the plugin is listed in `config/config.rb` and ArchivesSpace has been restarted.

### Field Not Appearing

1. Verify the plugin is enabled: Check startup logs for "Loaded plugin: ancestor_restrictions"
2. Clear any API response caches
3. Test with a fresh API request

### Performance Issues

The plugin is optimized for performance, but if you experience issues with very large hierarchies:

- Consider adding a database column for caching (requires schema migration)
- Adjust the `max_depth` limit in the code if needed
- Monitor database query logs to identify bottlenecks

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for any new functionality
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/archivesspace-ancestor-restrictions/issues)
- **ArchivesSpace**: [archivesspace.org](https://archivesspace.org)
- **Technical Docs**: [ArchivesSpace Technical Documentation](https://archivesspace.github.io/tech-docs/)

## Changelog

### Version 1.0.0 (2026-03-16)

- Initial release
- Single record and batch calculation support
- Comprehensive test suite
- Performance optimizations for deep hierarchies
- Full documentation

## Credits

Developed for the ArchivesSpace community.
