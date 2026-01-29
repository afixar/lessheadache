# Contributing to lessheadache

Thank you for your interest in contributing to lessheadache! This document provides guidelines for contributing to the project.

## Development Setup

1. Fork the repository
2. Clone your fork:
```bash
git clone https://github.com/yourusername/lessheadache.git
cd lessheadache
```

3. Create a branch for your changes:
```bash
git checkout -b feature/your-feature-name
```

## Testing Your Changes

### Syntax Checking

Always check your bash scripts for syntax errors:
```bash
bash -n lessheadache.sh
bash -n install.sh
```

### ShellCheck

Use ShellCheck to validate shell scripts:
```bash
shellcheck lessheadache.sh
shellcheck install.sh
```

### Testing on a Development Server

Always test your changes on a development server before submitting:

1. Set up a test cPanel/WHM environment
2. Install lessheadache using your modified scripts
3. Run with `--dry-run` first
4. Check logs for errors
5. Verify all features work as expected

## Code Style

### Shell Script Guidelines

- Use 4 spaces for indentation (no tabs)
- Use descriptive variable names
- Add comments for complex logic
- Use functions for reusable code
- Handle errors gracefully
- Quote all variables (e.g., `"$variable"`)
- Use `[[ ]]` for conditionals instead of `[ ]`
- Declare and assign variables separately to avoid masking return values

### Example:
```bash
# Good
local wp_version
wp_version=$(get_wordpress_version "$wp_path")

# Avoid
local wp_version=$(get_wordpress_version "$wp_path")
```

## Commit Messages

Follow these guidelines for commit messages:

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Fix bug" not "Fixes bug")
- First line should be 50 characters or less
- Reference issues and pull requests when applicable
- Be descriptive but concise

Example:
```
Add malware quarantine feature

- Implement automatic quarantine for detected malware
- Add configuration option to enable/disable quarantine
- Update documentation with quarantine instructions

Fixes #123
```

## Pull Request Process

1. Update the README.md if you're adding new features
2. Update EXAMPLES.md with usage examples for new features
3. Ensure all shell scripts pass ShellCheck
4. Test your changes on a development server
5. Update the version number if applicable
6. Submit your pull request with a clear description

## What to Contribute

### Ideas for Contributions

- Bug fixes
- Documentation improvements
- New features (see Issues for ideas)
- Performance improvements
- Security enhancements
- Test coverage
- Support for additional malware scanners
- Integration with other tools

### Priority Areas

- Automated testing framework
- Support for additional control panels (DirectAdmin, Plesk)
- Database scanning and optimization
- Plugin/theme vulnerability scanning
- Automated backup before remediation
- Web interface for configuration and monitoring

## Security

If you discover a security vulnerability, please email security@example.com instead of opening a public issue.

## Questions?

Feel free to open an issue for:
- Questions about the codebase
- Discussion about new features
- Help with development setup
- Clarification on documentation

## License

By contributing to lessheadache, you agree that your contributions will be licensed under the same license as the project.
