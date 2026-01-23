# Budget ![CI](https://github.com/tristandunn/budget/actions/workflows/ci.yml/badge.svg)

A minimal budgeting application.

## Contributing

See the [contributing guidelines](docs/CONTRIBUTING.md).

## Development

Install the dependencies and setup the database.

```
bin/setup
```

To run the application processes.

```
bin/dev
```

If you're making changes, be sure to write and run the tests.

```
bin/rails spec
```

Before pushing changes, check all the code.

```
bin/ci
```

### Docker

Build the image with Docker.

```
docker build -t budget .
```

Run the server using the image.

```
docker run --rm -p 3000:80 -e SECRET_KEY_BASE=$(bin/rails secret) --name budget budget
```

## License

Budget uses the MIT license. See [LICENSE](LICENSE) for more details.
