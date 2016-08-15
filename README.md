Requirements
------------

- [Swift][1]
- [SDL >= 2.0.4][2]


Usage
-----

Install dependencies:

    swift package fetch

Build in release mode and run the project:

    swift build -c release && ./build/release/zenith

You may need to specify the path to the SDL library, e.g.:

    swift build -Xlinker -L/usr/local/lib


[1]: https://swift.org
[2]: https://www.libsdl.org
