# Contributing to IBM AI Platform Backend

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🚀 Contribution Process

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature: `git checkout -b feature/feature-name`
4. **Develop** following the project conventions
5. **Test** your changes thoroughly
6. **Commit** with descriptive messages
7. **Push** to your fork: `git push origin feature/feature-name`
8. **Pull Request** to the main repository

## 📝 Code Conventions

### Python
- Follow **PEP 8** for code style
- Use **type hints** whenever possible
- Docstrings in **Google Style** format
- Maximum 100 characters per line

### Commits
Use **Conventional Commits**:
- `feat:` - New functionality
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Add or modify tests
- `chore:` - Maintenance tasks

Example: `feat: add support for Llama 3 model`

## 🧪 Testing

Before creating a PR, make sure to:
- [ ] Run `docker-compose up -d` without errors
- [ ] Verify that all APIs respond correctly
- [ ] Test modified endpoints with example requests
- [ ] Check logs for errors

## 🏗️ Architecture

### PPC64le Compatibility
- **CRITICAL**: All solutions must be compatible with Power PC architecture (ppc64le)
- Use the wheels repository: `https://repo.fury.io/mgiessing`
- Avoid dependencies without builds for ppc64le
- Test in a CentOS 9 environment whenever possible

### Docker
- Everything must work with `./setup.sh full`
- Do not create temporary or manual solutions
- Document changes in docker-compose.yaml
- Optimize resource usage (limited CPU/RAM)

## 📚 Documentation

When adding new features:
- Update the relevant README.md
- Add docstrings to functions/classes
- Document environment variables in `.env`
- Include usage examples

## ⚠️ Important

- **DO NOT** commit `.env` files
- **DO NOT** commit model files (*.gguf, *.bin)
- **DO NOT** commit logs or database dumps
- **DO** test in a clean environment before the PR

## 🤝 Code of Conduct

- Be respectful and professional
- Accept constructive criticism
- Focus on what is best for the project
- Help other contributors

## 📞 Contact

For questions or discussions:
- Open an **Issue** on GitHub
- Tag appropriately (bug, enhancement, question)
- Provide detailed context

---

Thank you for contributing to IBM AI Platform Backend! 🚀


