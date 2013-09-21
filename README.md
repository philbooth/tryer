# trier.js

[![Build status][ci-image]][ci-status]

Because everyone loves a trier!
Conditional
and repeated
function invocation
for node
and browser.

## Conditional?

Conditional function invocation
means you can specify
some pre-requisite condition
that must be satisfied
before your function
will be called by trier.

## Repeated?

Repeated function invocation
means you can specify
some post-requisite condition
that must be satisfied
before trier will stop
making calls to your function.

## Installation

### Via NPM

```
npm install trier
```

### Via Jam

```
jam install trier
```

### Via Git

```
git clone git@github.com:philbooth/trier.js.git
```

## Usage

### Loading the library

Both
CommonJS
(e.g.
if you're running on [Node.js][node]
or if you're in the browser with [Browserify])
and AMD
(e.g. if you're using [Require.js][require])
loading styles are supported.
If neither system is detected,
the library defaults to
exporting it's interface globally
as `trier`.

### Calling the library

trier.js exports two public functions,
`when` and `until`.

#### trier.when (options)

Performs some action
when prerequesite conditions
are met.

Accepts a single options object,
which supports the following properties:

* `predicate`: Callback function used to test precondition.
  Should return `false` to postpone `action` or `true` to perform it.
  Defaults to nop.
* `action`: The function you want to call. Defaults to nop.
* `fail`: Callback function to be invoked if `limit` tries are reached.
  Defaults to nop.
* `context`: Context object used when applying `predicate`, `action` and `fail`.
  Defaults to `{}`.
* `args`: Arguments array used when applying `predicate`, `action` and `fail`.
  Defaults to `[]`.
* `interval`: Retry interval in milliseconds.
  Use negative numbers to indicate that subsequent retries should wait for twice the preceding interval
  (i.e. exponential waits).
  Defaults to -1000.
* `limit`: Maximum retry count, at which point the call fails and retry iterations cease.
  Use a negative number to indicate that call should continue indefinitely
  (i.e. never fail).
  Defaults to -1.

Example:
```javascript
trier.when({
    predicate: function () {
        return db.isConnected;
    },
    action: function () {
        db.insert(user);
        next();
    },
    fail: function () {
        log.error('No database connection, terminating.');
        process.exit(1);
    },
    interval: 1000,
    limit: 10
});
```

#### trier.until (options)

Performs some action repeatedly
until postrequisite conditions
are met.

Accepts a single options object,
which supports the following properties:

* `predicate`: Callback function used to test postcondition.
  Should return `false` to retry `action` or `true` to stop it.
  Defaults to nop.
* `action`: The function you want to call. Defaults to nop.
* `fail`: Callback function to be invoked if `limit` tries are reached.
  Defaults to nop.
* `context`: Context object used when applying `predicate`, `action` and `fail`.
  Defaults to `{}`.
* `args`: Arguments array used when applying `predicate`, `action` and `fail`.
  Defaults to `[]`.
* `interval`: Retry interval in milliseconds.
  Use negative numbers to indicate that subsequent retries should wait for twice the preceding interval
  (i.e. exponential waits).
  Defaults to -1000.
* `limit`: Maximum retry count, at which point the call fails and retry iterations cease.
  Use a negative number to indicate that call should continue indefinitely
  (i.e. never fail).
  Defaults to -1.

Example:
```javascript
var sent = false
trier.until({
    predicate: function () {
        return sent;
    },
    action: function () {
        smtp.send(email, function (error) {
            if (!error) {
                sent = true;
                next();
            }
        });
    },
    interval: -1000,
    limit: -1
});
```

## Development

### Dependencies

The build environment relies on
Node.js,
[NPM],
[JSHint],
[Mocha],
[Chai] and
[UglifyJS].
Assuming that you already have Node.js and NPM set up,
you just need to run `npm install`
to install all of the dependencies as listed in `package.json`.

### Unit tests

The unit tests are in `test/trier.js`.
You can run them with the command `npm test` or `jake test`.
To run the tests in a web browser,
open `test/trier.html`.

## License

[MIT][license]

[ci-image]: https://secure.travis-ci.org/philbooth/trier.js.png?branch=master
[ci-status]: http://travis-ci.org/#!/philbooth/trier.js
[node]: http://nodejs.org/
[browserify]: http://browserify.org/
[require]: http://requirejs.org/
[npm]: https://npmjs.org/
[jshint]: https://github.com/jshint/node-jshint
[mocha]: http://visionmedia.github.com/mocha
[chai]: http://chaijs.com/
[uglifyjs]: https://github.com/mishoo/UglifyJS
[license]: https://github.com/philbooth/trier.js/blob/master/COPYING

