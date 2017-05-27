zenith [![Build Status](https://travis-ci.org/emlai/zenith.svg?branch=master)](https://travis-ci.org/emlai/zenith)
======

zenith is an upcoming graphical open-world roguelike game, still in its early development stages.

![screenshot from 2017-05-27 19-24-37](https://cloud.githubusercontent.com/assets/7543552/26522927/15fdea12-4314-11e7-9830-c65c397579fa.png)

![screenshot from 2017-05-27 19-35-17](https://cloud.githubusercontent.com/assets/7543552/26522929/161ae5d6-4314-11e7-92ab-fc9d87038586.png)

![screenshot from 2017-05-27 19-30-05](https://cloud.githubusercontent.com/assets/7543552/26522928/15ff2206-4314-11e7-9926-abe0a259f7d4.png)

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
