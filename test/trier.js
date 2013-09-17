'use strict';

var assert = require('chai').assert,

modulePath = '../src/trier';

suite('trier:', function () {
    test('require does not throw', function () {
        assert.doesNotThrow(function () {
            require(modulePath);
        });
    });

    test('require returns object', function () {
        assert.isObject(require(modulePath));
    });

    suite('require:', function () {
        var trier;

        setup(function () {
            trier = require(modulePath);
        });

        teardown(function () {
            trier = undefined;
        });

        test('when function is exported', function () {
            assert.isFunction(trier.when);
        });

        test('when throws when options is null', function () {
            assert.throws(function () {
                trier.when(null);
            });
        });

        test('until function is exported', function () {
            assert.isFunction(trier.until);
        });

        test('until throws when options is null', function () {
            assert.throws(function () {
                trier.until(null);
            });
        });
    });
});

