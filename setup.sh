#!/bin/bash
# Setup script for the ArchivesSpace Ancestor Restrictions Plugin

echo "=========================================="
echo "ArchivesSpace Ancestor Restrictions Plugin"
echo "Setup Script"
echo "=========================================="
echo ""

# Get the plugin directory
PLUGIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_NAME="$(basename "$PLUGIN_DIR")"

echo "Plugin directory: $PLUGIN_DIR"
echo "Plugin name: $PLUGIN_NAME"
echo ""

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: ArchivesSpace Ancestor Restrictions Plugin v1.0.0"
    echo "✓ Git repository initialized"
else
    echo "✓ Git repository already exists"
fi

echo ""
echo "=========================================="
echo "Installation Instructions"
echo "=========================================="
echo ""
echo "1. Copy or clone this plugin to your ArchivesSpace plugins directory:"
echo "   cp -r $PLUGIN_DIR /path/to/archivesspace/plugins/"
echo ""
echo "2. Edit config/config.rb (or common/config/config-defaults.rb) and add:"
echo "   AppConfig[:plugins] = ['other_plugins', '$PLUGIN_NAME']"
echo ""
echo "3. Restart ArchivesSpace:"
echo "   ./archivesspace.sh stop && ./archivesspace.sh start"
echo ""
echo "=========================================="
echo "Testing"
echo "=========================================="
echo ""
echo "To run the RSpec tests:"
echo ""
echo "  cd /path/to/archivesspace"
echo "  cp plugins/$PLUGIN_NAME/spec/archival_object_restrictions_spec.rb backend/spec/"
echo "  build/run backend:test -Dspec='archival_object_restrictions_spec.rb'"
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
