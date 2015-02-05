# Environment Linter

This script helps identify issues with OS X machine setup for basic web
development with Ruby. It assumes OS X 10.8 or newer.

## Usage:

```sh
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/mikelikesbikes/environment_linter/master/test_setup.rb)"
```

This will check several common sticking points with machine setup and attempt to
give useful solutions to common problems. Sometimes the solution is to get
outside help. This is because any number of things could cause the issue, and it
needs to be further explored. On the positive side, it at least lets you know
that something is weird.

## Contributing

I'd love people to add to this project with checks for other pieces of machine
setup. Please create an Issue for discussion before offering a Pull Request. I'd
hate you to spend a bunch of time adding checks for things I don't plan to
integrate.

## License

Environment Linter is licensed under the [MIT License].

[mit license]: http://www.opensource.org/licenses/MIT

