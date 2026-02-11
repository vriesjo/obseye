# Contributing to Obseye

Thank you for your interest in contributing to Obseye! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/obseye.git`
3. Create a feature branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Test your changes
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin feature/my-feature`
8. Create a Pull Request

## Development Setup

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2+
- Basic knowledge of monitoring concepts

### Running Locally

```bash
# Start the stack
make start

# View logs
make logs

# Stop the stack
make stop
```

## Testing Changes

Before submitting a Pull Request:

1. Validate configuration:
   ```bash
   docker compose config --quiet
   ```

2. Run the test script:
   ```bash
   ./test.sh
   ```

3. Start the stack and verify:
   - All services are running: `docker compose ps`
   - Grafana is accessible: http://localhost:3000
   - Dashboards load correctly
   - Metrics are being collected

4. Check for errors in logs:
   ```bash
   docker compose logs
   ```

## Adding New Features

### Adding a New Exporter

1. Add the service to `docker-compose.yml`
2. Add scrape config to `config/prometheus/prometheus.yml`
3. Update documentation in README.md
4. Create or update relevant Grafana dashboard

### Adding New Alert Rules

1. Edit `config/prometheus/alerts.yml`
2. Follow the existing format
3. Test the alert triggers
4. Document the alert in README.md

### Adding New Dashboards

1. Create dashboard in Grafana UI
2. Export as JSON
3. Save to `config/grafana/dashboards/`
4. Test by restarting Grafana
5. Document in README.md

## Code Style

- Use consistent YAML indentation (2 spaces)
- Follow Docker Compose best practices
- Add comments for complex configurations
- Keep alert expressions readable

## Pull Request Guidelines

- Clear description of changes
- Reference related issues
- Include tests if applicable
- Update documentation
- Follow semantic commit messages

## Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `config`: Configuration changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

## Questions?

Feel free to open an issue for:
- Bug reports
- Feature requests
- Questions about the project
- Help with contributions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
