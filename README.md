# ArchivesSpace Ancestor Restrictions Plugin

An ArchivesSpace plugin that adds an `ancestor_restrictions_apply` field to archival object JSON responses, indicating whether any ancestor (parent archival objects or root resource) has restrictions applied.

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
git clone https://github.com/NCSU-Libraries/archivesspace_ancestor_restrictions_plugin.git ancestor_restrictions
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

### Performance Optimization

- **Single record queries**: Iterative approach with early exit (stops at first restricted ancestor)
- **Batch operations**: 
  - Walks up the tree level-by-level to collect ALL ancestor IDs (handles deep hierarchies correctly)
  - Fetches all ancestors in 2-3 queries total
  - Uses in-memory lookups for fast restriction checking
  - Employs caching to prevent redundant calculations for records with shared ancestors
- **Depth limit**: 100 levels maximum to prevent infinite loops

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

## Compatibility

- **ArchivesSpace Version**: v3.0+ (tested on v4.0.0-dev)
- **Database**: MySQL, PostgreSQL (any database supported by ArchivesSpace)
- **Ruby/JRuby**: 9.4.x+

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for any new functionality
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details
