// Conditional and repeated task invocation for node and browser.

/*globals setTimeout, define, module */

(function (globals) {
    'use strict';

    var functions = {
        when: when,
        until: until
    };

    exportFunctions();

    // Public function `when`.
    //
    // Performs some action when prerequisite conditions are met.
    //
    // @option predicate {function} Callback used to test precondition. Should
    //                              return `false` to postpone `action` or `true`
    //                              to perform it. Defaults to nop.
    // @option action {function}    The thing you want to do. Defaults to nop.
    // @option fail {function}      Callback to be invoked if `limit` tries are
    //                              reached. Defaults to nop.
    // @option context {object}     Context object used when applying `predicate`,
    //                              `action` and `fail`. Defaults to `{}`.
    // @option args {array}         Arguments array used when applying `predicate`,
    //                              `action` and `fail`. Defaults to `[]`.
    // @option interval {number}    Retry interval in milliseconds. Use negative
    //                              numbers to indicate that subsequent retries
    //                              should wait for double the interval than the
    //                              preceding iteration (i.e. exponential waits).
    //                              Defaults to -1000.
    // @option limit {number}       Maximum retry count, at which point the call
    //                              fails and retry iterations cease. Use a negative
    //                              number to indicate that call should continue
    //                              indefinitely (i.e. never fail). Defaults to -1.
    //
    // @example
    //     trier.when({
    //         predicate: function () {
    //             return db.isConnected;
    //         },
    //         action: function () {
    //             db.insert(user);
    //             next();
    //         },
    //         fail: function () {
    //             log.error('No database connection, terminating.');
    //             process.exit(1);
    //         },
    //         interval: 1000,
    //         limit: 10
    //     });
    function when (options) {
        conditionallyPerformActionOrRecur(false, normaliseOptions(options));
    }

    function normaliseOptions (options) {
        return {
            count: 0,
            action: normaliseFunction(options.action),
            predicate: normaliseFunction(options.predicate),
            fail: normaliseFunction(options.fail),
            interval: normaliseNumber(options.interval, -1000),
            limit: normaliseNumber(options.limit, -1),
            context: normaliseObject(options.context),
            args: normaliseArray(options.args)
        };
    }

    function normaliseFunction (fn) {
        return normalise(fn, isFunction, nop);
    }

    function isFunction (fn) {
        return typeof fn === 'function';
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

    function conditionallyPerformActionOrRecur (isPreAction, options) {
        iterate();

        function iterate () {
            if (isPreAction) {
                performAction(options);
            }

            if (shouldRetry(options)) {
                incrementCount(options);

                if (shouldFail(options)) {
                    return fail(options);
                }

                updateInterval(options);

                return recur(iterate, options);
            }

            if (!isPreAction) {
                performAction(options);
            }
        }
    }

    function shouldRetry (options) {
        return !options.predicate.apply(options.context, options.args);
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

    function updateInterval (options) {
        if (options.interval < 0) {
            options.interval *= 2;
        }
    }

    function recur (fn, options) {
        setTimeout(fn, Math.abs(options.interval));
    }

    function performAction (options) {
        options.action.apply(options.context, options.args);
    }

    // Public function `until`.
    //
    // Performs some action repeatedly until postrequisite conditions are met.
    //
    // @option predicate {function} Callback used to test postcondition. Should
    //                              return `false` to retry `action` or `true`
    //                              to stop it. Defaults to nop.
    // @option action {function}    The thing you want to do. Defaults to nop.
    // @option fail {function}      Callback to be invoked if `limit` tries are
    //                              reached. Defaults to nop.
    // @option context {object}     Context object used when applying `predicate`,
    //                              `action` and `fail`. Defaults to `{}`.
    // @option args {array}         Arguments array used when applying `predicate`,
    //                              `action` and `fail`. Defaults to `[]`.
    // @option interval {number}    Retry interval in milliseconds. Use negative
    //                              numbers to indicate that subsequent retries
    //                              should wait for double the interval than the
    //                              preceding iteration (i.e. exponential waits).
    //                              Defaults to -1000.
    // @option limit {number}       Maximum retry count, at which point the call
    //                              fails and retry iterations cease. Use a negative
    //                              number to indicate that call should continue
    //                              indefinitely (i.e. never fail). Defaults to -1.
    //
    // @example
    //     var sent = false
    //     trier.until({
    //         predicate: function () {
    //             return sent;
    //         },
    //         action: function () {
    //             smtp.send(email, function (error) {
    //                 if (!error) {
    //                     sent = true;
    //                     next();
    //                 }
    //             });
    //         },
    //         interval: -1000,
    //         limit: -1
    //     });
    function until (options) {
        conditionallyPerformActionOrRecur(true, normaliseOptions(options));
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

