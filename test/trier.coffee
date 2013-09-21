'use strict'

{ assert } = require 'chai'

modulePath = '../src/trier'

suite 'trier:', ->
  test 'require does not throw', ->
    assert.doesNotThrow ->
      require modulePath

  test 'require returns object', ->
    assert.isObject require modulePath

  suite 'require:', ->
    trier = undefined

    setup ->
      trier = require modulePath

    teardown ->
      trier = undefined

    test 'when function is exported', ->
      assert.isFunction trier.when

    test 'when throws when options is null', ->
      assert.throws ->
        trier.when null

    test 'when does not throw when options is empty object', ->
      assert.doesNotThrow ->
        trier.when {}

    test 'until function is exported', ->
      assert.isFunction trier.until

    test 'until throws when options is null', ->
      assert.throws ->
        trier.until null

    test 'until does not throw when options is empty object', ->
      assert.doesNotThrow ->
        trier.until {}

