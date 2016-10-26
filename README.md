zenith [![Build Status](https://travis-ci.org/emlai/zenith.svg?branch=master)](https://travis-ci.org/emlai/zenith)
======

zenith is an upcoming graphical open-world roguelike game, still in its early development stages.


Requirements
------------

- [Swift >= 3.0][1]
- [SDL >= 2.0.4][2]


Usage
-----

Build in release mode and run the project:

    swift build -c release && .build/release/zenith

You may need to specify the path to the SDL library, e.g.:

    swift build -Xlinker -L/usr/local/lib


Contributing
------------

Contributions are welcome! Fork the project and submit a pull request, or open an issue to discuss/propose changes.


[1]: https://swift.org
[2]: https://www.libsdl.org
