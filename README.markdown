Saloon
======

[AtomPub][] server implemented using [Sinatra][] and [CouchDB][].

## Getting started

    gem install sinatra atom-tools
    git clone git://github.com/sr/saloon.git
    cd saloon
    ruby lib/app.rb

## Running the tests

    gem install sr-couchy test-spec mocha
    rake database:redo test

## Status

Saloon currently passes [APE][]'s basic tests. See the [report][] for details.

## Todo

* Fix most of APE's warnings
* Implement support for slug
* Implement media entry

## Author

Written by Simon Rozet <simon@rozet.name>

## License

    (The MIT License)

    Copyright (c) 2008 Simon Rozet <simon@rozet.name>

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    'Software'), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[AtomPub]: http://bitworking.org/projects/atom/rfc5023.html
[Sinatra]: http://sinatra.rubyforge.org
[CouchDB]: http://couchdb.org
[APE]: http://ape.rubyforge.org
[report]: http://atonie.org/2008/saloon/report
