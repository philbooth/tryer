# trier.js

[![Build status][ci-image]][ci-status]

Because everyone loves a trier!
Conditional
and repeated
function invocation
for node
and browser.

## Say what?

Sometimes,
you want to defer
calling a function
until a certain
pre-requisite condition is met.
Other times,
you want to
call a function
repeatedly
until some post-requisite condition
is satisfied.
Occasionally,
you might even want
to do both
for the same function.

To save you writing
explicit conditions
and loops
on each of those occasions,
trier.js implements
a predicate-based approach
that hides the cruft
behind a simple,
functional interface.

Additionally,
it allows you to easily specify
retry intervals
and limits,
so that your code
doesn't hog the CPU.
It also supports
exponential incrementation
of retry intervals,
which can be useful
when handling
indefinite error states
such as network failure.

## How can I install it?

You can install trier.js
with one of
the package managers:
[NPM];
[Jam];
[Bower];
or [Component].
The package name
for the first three
is `trier`
and for Component
it's `philbooth/trier.js`:

```
npm install trier

jam install trier

bower install trier

component install philbooth/trier.js
```

Alternatively,
you can just clone
the git repository
from GitHub:

```
git clone git@github.com:philbooth/trier.js.git
```

## How do I use it in my code?

If you are running in
[Node.js][node],
[Browserify]
or another CommonJS-style
environment,
you can `require`
trier.js like so:

```javascript
var trier = require('trier');
```

It also the supports
the AMD-style format
preferred by [Require.js][require]:

```javascript
require.config({
    paths: {
        trier: 'trier/src/trier'
    }
});

require([ 'trier' ], function (trier) {
});
```

If you are
including trier.js
with an HTML `<script>` tag,
or neither of the above environments
are detected,
trier.js will just export its interface globally
as `trier`.

trier.js
has no dependencies
and exports
a single public function,
`attempt`,
which enables you to
conditionally
and repeatedly
call functions
without writing
explicit `if` statements
or loops.

`trier.attempt` takes one argument,
an options object
that supports
the following properties:

* `when`:
  A callback function
  used to test the pre-condition
  for function invocation.
  Until `when` returns true
  (or a truthy value),
  the `action` function
  will not be called.
  If undefined,
  it defaults to a function
  defined as
  `function () { return true; }`.
* `until`:
  A callback function
  used to test the post-condition
  for terminating
  function invocation.
  After `until` returns true
  (or a truthy value),
  the `action` function
  will no longer be called.
  If undefined,
  it defaults to a function
  defined as
  `function () { return true; }`.
* `action`:
  The invocation target.
  A function
  that will be called
  according to the values
  returned by
  `when`
  and `until`.
  If undefined,
  it defaults to a function
  defined as
  `function () {}`.
  If your implementation
  of `action`
  expects any arguments,
  it will be treated
  as asynchronous
  and passed
  an additional function parameter,
  `done`.
  You must call `done`
  when the action
  is finished.
* `fail`:
  The error handler.
  A function
  that will be called
  if `limit`
  falsey values
  are returned by
  `when` or `until`.
  If undefined,
  it defaults to a function
  defined as
  `function () {}`.
* `limit`:
  Failure limit,
  representing the number of times
  that `when`
  or `until`
  may return a falsey value,
  before the invocation
  is deemed to have failed
  and attempts
  to call `action`
  will cease.
  A negative number
  indicates that the attempt
  should never fail,
  instead continuing indefinitely
  until `when`
  and `until`
  have returned
  truthy values.
  Defaults to -1.
* `interval`:
  A number
  representing the
  retry interval,
  in milliseconds.
  Use a negative number to indicate
  that each subsequent retry
  should wait for twice the interval
  from the preceding iteration
  (i.e. exponential incrementation).
  The default value is
  -1000,
  signifying that
  the initial retry interval
  should be one second
  and that each subsequent retry
  should double
  the previous interval.
* `context`:
  The context object
  (i.e. `this`)
  on which to invoke
  the functions
  `when`,
  `until`,
  `action` and
  `fail`.
  Defaults to
  an empty object.
* `args`:
  The arguments array
  that will be provided
  to the functions
  `when`,
  `until`,
  `action` and
  `fail`.
  Defaults to
  an empty array.

Examples:
```javascript
// Attempt to insert a database record, waiting until a
// connection is available before doing so. The retry
// interval is 1 second on each occasion and the call
// will fail after 10 attempts.
trier.attempt({
    when: function () {
        return db.isConnected;
    },
    action: function () {
        db.insert(record);
    },
    fail: function () {
        log.error('No database connection, terminating.');
        process.exit(1);
    },
    interval: 1000,
    limit: 10
});

// Attempt to send email message, optionally retrying with
// exponentially increasing intervals starting at 1 second.
// Continue to make attempts until the call succeeds.
var sent = false
trier.attempt({
    until: function () {
        return sent;
    },
    action: function (done) {
        smtp.send(email, function (error) {
            if (!error) {
                sent = true;
            }
            done();
        });
    },
    interval: -1000,
    limit: -1
});
```

## How do I set up the build environment?

The build environment relies on
Node.js,
NPM,
[JSHint],
[CoffeeScript],
[Mocha],
[Chai],
[spooks.js][spooks] and
[UglifyJS].
Assuming that you already have
Node.js
and NPM
installed,
you just need to run
`npm install`
to set up all of the dependencies
as listed in `package.json`.

The unit tests are in `test/trier.coffee`.
You can run them with the command `npm test`.

## What license is trier.js released under?

[MIT][license]

[ci-image]: https://secure.travis-ci.org/philbooth/trier.js.png?branch=master
[ci-status]: http://travis-ci.org/#!/philbooth/trier.js
[npm]: https://npmjs.org/
[jam]: http://jamjs.org/
[component]: http://component.io/
[bower]: http://bower.io/
[node]: http://nodejs.org/
[browserify]: http://browserify.org/
[require]: http://requirejs.org/
[jshint]: https://github.com/jshint/node-jshint
[coffeescript]: http://coffeescript.org/
[mocha]: http://visionmedia.github.com/mocha
[chai]: http://chaijs.com/
[spooks]: https://github.com/philbooth/spooks.js
[uglifyjs]: https://github.com/mishoo/UglifyJS
[license]: https://github.com/philbooth/trier.js/blob/master/COPYING

