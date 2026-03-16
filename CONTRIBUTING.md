# Contributing to ArchivesSpace Ancestor Restrictions Plugin

Thank you for considering contributing to this plugin! This document provides guidelines for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:

- A clear, descriptive title
- Steps to reproduce the problem
- Expected behavior
- Actual behavior
- ArchivesSpace version
- Database type (MySQL, PostgreSQL, etc.)
- Any relevant log output

### Suggesting Enhancements

Enhancement suggestions are welcome! Please create an issue with:

- A clear, descriptive title
- Detailed description of the proposed enhancement
- Use cases that would benefit from the enhancement
- Any implementation suggestions you might have

### Pull Requests

1. **Fork the repository** and create your branch from `main`

2. **Make your changes**
   - Follow the existing code style
   - Add tests for any new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Copy spec to backend/spec
   cp spec/archival_object_restrictions_spec.rb /path/to/archivesspace/backend/spec/
   
   # Run tests
   cd /path/to/archivesspace
   build/run backend:test -Dspec='archival_object_restrictions_spec.rb'
   ```

4. **Ensure all tests pass**
   - All existing tests must continue to pass
   - Add new tests for new functionality
   - Aim for good test coverage

5. **Update documentation**
   - Update README.md if you've changed functionality
   - Update CHANGELOG.md following the existing format
   - Add inline code comments for complex logic

6. **Submit your pull request**
   - Reference any related issues
   - Describe what your PR does
   - Note any breaking changes

## Code Style

- Follow Ruby community best practices
- Use clear, descriptive variable names
- Add comments for complex logic
- Keep methods focused and concise
- Prefer readability over cleverness

## Testing Guidelines

- Write tests for all new functionality
- Test both success and failure cases
- Test edge cases (empty inputs, nil values, etc.)
- Use descriptive test names that explain what is being tested
- Follow the existing RSpec pattern in the codebase

## Performance Considerations

This plugin is designed for performance:

- Minimize database queries
- Use batch operations when processing multiple records
- Implement early exit conditions where possible
- Consider memory usage for large operations
- Test with realistic data volumes

## Questions?

Feel free to create an issue for any questions about contributing.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
