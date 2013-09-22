// Conditional and repeated task invocation for node and browser.

/*globals setTimeout, define, module */

(function (globals) {
    'use strict';

    var functions = {
        attempt: attempt
    };

    exportFunctions();

    // Public function `attempt`.
    //
    // Performs some action when pre-requisite conditions are met and/or until
    // post-requisite conditions are satisfied.
    //
    // @option when {function}    Callback used to test pre-condition. Should return
    //                            `false` to postpone `action` or `true` to perform it.
    //                            Defaults to `function () { return true; }`.
    // @option until {function}    Callback used to test post-condition. Should return
    //                            `false` to retry `action` or `true` to terminate it.
    //                            Defaults to `function () { return true; }`.
    // @option action {function}  The thing you want to do. Defaults to `function () {}`.
    //                            If your implementation of `action` expects any arguments,
    //                            it will be treated as asynchronous and passed an extra
    //                            function parameter, `done`. You must call `done` when
    //                            the action is finished.
    // @option fail {function}    Callback to be invoked if `limit` tries are reached.
    //                            Defaults to `function () {}`.
    // @option context {object}   Context object used when applying `when`, `until`,
    //                            `action` and `fail`. Defaults to `{}`.
    // @option args {array}       Arguments array used when applying `when`, `until`,
    //                            `action` and `fail`. Defaults to `[]`.
    // @option interval {number}  Retry interval in milliseconds. Use negative numbers to
    //                            indicate that subsequent retries should wait for double
    //                            the interval from the preceding iteration (exponential
    //                            waits). Defaults to -1000.
    // @option limit {number}     Maximum retry count, at which point the call fails and
    //                            retry iterations cease. Use a negative
    //                            number to indicate that call should continue
    //                            indefinitely (i.e. never fail). Defaults to -1.
    //
    // @example
    //     trier.attempt({
    //         when: function () {
    //             return db.isConnected;
    //         },
    //         action: function () {
    //             db.insert(user);
    //         },
    //         fail: function () {
    //             log.error('No database connection, terminating.');
    //             process.exit(1);
    //         },
    //         interval: 1000,
    //         limit: 10
    //     });
    //
    // @example
    //     var sent = false
    //     trier.attempt({
    //         until: function () {
    //             return sent;
    //         },
    //         action: function (done) {
    //             smtp.send(email, function (error) {
    //                 if (!error) {
    //                     sent = true;
    //                 }
    //                 done();
    //             });
    //         },
    //         interval: -1000,
    //         limit: -1
    //     });
    function attempt (options) {
        options = normaliseOptions(options);

        iterate();

        function iterate () {
            if (conditionallyRecur('when')) {
                if (isActionSynchronous(options)) {
                    performAction(options);
                    return conditionallyRecur('until');
                }

                performAction(options, function () {
                    conditionallyRecur('until');
                });
            }
        }

        function conditionallyRecur (predicateKey) {
            if (shouldRetry(options, predicateKey)) {
                incrementCount(options);

                if (shouldFail(options)) {
                    fail(options);
                }  else {
                    recur(iterate, postIncrementInterval(options));
                }

                return false;
            }

            return true;
        }
    }

    function normaliseOptions (options) {
        return {
            count: 0,
            when: normalisePredicate(options.when),
            until: normalisePredicate(options.until),
            action: normaliseFunction(options.action),
            fail: normaliseFunction(options.fail),
            interval: normaliseNumber(options.interval, -1000),
            limit: normaliseNumber(options.limit, -1),
            context: normaliseObject(options.context),
            args: normaliseArray(options.args)
        };
    }

    function normalisePredicate (fn) {
        return normalise(fn, isFunction, yes);
    }

    function isFunction (fn) {
        return typeof fn === 'function';
    }

    function yes () {
        return true;
    }

    function normaliseFunction (fn) {
        return normalise(fn, isFunction, nop);
    }

    function nop () {
    }

    function normalise(thing, predicate, defaultValue) {
        if (predicate(thing)) {
            return thing;
        }

        return defaultValue;
    }

    function normaliseNumber (number, defaultNumber) {
        return normalise(number, isNumber, defaultNumber);
    }

    function isNumber (number) {
        return typeof number === 'number' && number === number;
    }

    function normaliseObject (object) {
        return normalise(object, isObject, {});
    }

    function isObject (object) {
        return typeof object === 'object' && object !== null && isArray(object) === false;
    }

    function isArray (array) {
        if (Array.isArray) {
            return Array.isArray(array);
        }

        return Object.prototype.toString.call(array) === '[object Array]';
    }

    function normaliseArray (array) {
        return normalise(array, isArray, []);
    }

    function isActionSynchronous (options) {
        return options.action.length === 0;
    }

    function shouldRetry (options, predicateKey) {
        return !options[predicateKey].apply(options.context, options.args);
    }

    function incrementCount (options) {
        options.count += 1;
    }

    function shouldFail (options) {
        return options.limit >= 0 && options.count >= options.limit;
    }

    function fail (options) {
        options.fail.apply(options.context, options.args);
    }

    function postIncrementInterval (options) {
        var currentInterval = options.interval;

        if (options.interval < 0) {
            options.interval *= 2;
        }

        return currentInterval;
    }

    function recur (fn, interval) {
        setTimeout(fn, Math.abs(interval));
    }

    function performAction (options, done) {
        options.action.apply(options.context, done ? options.args.concat(done) : options.args);
    }

    function exportFunctions () {
        if (typeof define === 'function' && define.amd) {
            define(function () {
                return functions;
            });
        } else if (typeof module !== 'undefined' && module !== null) {
            module.exports = functions;
        } else {
            globals.trier = functions;
        }
    }
}(this));

