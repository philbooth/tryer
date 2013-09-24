'use strict'

{ assert } = require 'chai'
spooks = require 'spooks'

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

    test 'attempt function is exported', ->
      assert.isFunction trier.attempt

    test 'attempt throws when options is null', ->
      assert.throws ->
        trier.attempt null

    test 'attempt does not throw when options is object', ->
      assert.doesNotThrow ->
        trier.attempt {}

    suite 'when passing immediately:', ->
      log = predicate = action = fail = pass = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: true }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        pass = spooks.fn { name: 'pass', log, callback: done }
        context = {}
        args = [ 'foo', 'bar' ]
        trier.attempt { when: predicate, action, fail, pass, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = pass = context = args = undefined

      test 'predicate was called once', ->
        assert.strictEqual log.counts.predicate, 1

      test 'predicate was passed correct arguments', ->
        assert.lengthOf log.args.predicate[0], 2
        assert.strictEqual log.args.predicate[0][0], 'foo'
        assert.strictEqual log.args.predicate[0][1], 'bar'

      test 'predicate was applied to correct context', ->
        assert.strictEqual log.these.predicate[0], context

      test 'action was called once', ->
        assert.strictEqual log.counts.action, 1

      test 'action was passed correct arguments', ->
        assert.lengthOf log.args.action[0], 2
        assert.strictEqual log.args.action[0][0], 'foo'
        assert.strictEqual log.args.action[0][1], 'bar'

      test 'action was applied to correct context', ->
        assert.strictEqual log.these.action[0], context

      test 'fail was not called', ->
        assert.strictEqual log.counts.fail, 0

      test 'pass was called once', ->
        assert.strictEqual log.counts.pass, 1

      test 'pass was passed correct arguments', ->
        assert.lengthOf log.args.pass[0], 2
        assert.strictEqual log.args.pass[0][0], 'foo'
        assert.strictEqual log.args.pass[0][1], 'bar'

      test 'pass was applied to correct context', ->
        assert.strictEqual log.these.pass[0], context

    suite 'when failing three times:', ->
      log = predicate = action = fail = pass = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        pass = spooks.fn { name: 'pass', log, callback: done }
        context = {}
        args = [ 'baz' ]
        trier.attempt { when: predicate, action, fail, pass, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = pass = context = args = undefined

      test 'predicate was called three times', ->
        assert.strictEqual log.counts.predicate, 3

      test 'predicate was passed correct arguments first time', ->
        assert.lengthOf log.args.predicate[0], 1
        assert.strictEqual log.args.predicate[0][0], 'baz'

      test 'predicate was applied to correct context first time', ->
        assert.strictEqual log.these.predicate[0], context

      test 'predicate was passed correct arguments second time', ->
        assert.lengthOf log.args.predicate[1], 1
        assert.strictEqual log.args.predicate[1][0], 'baz'

      test 'predicate was applied to correct context second time', ->
        assert.strictEqual log.these.predicate[1], context

      test 'predicate was passed correct arguments third time', ->
        assert.lengthOf log.args.predicate[2], 1
        assert.strictEqual log.args.predicate[2][0], 'baz'

      test 'predicate was applied to correct context third time', ->
        assert.strictEqual log.these.predicate[2], context

      test 'action was not called', ->
        assert.strictEqual log.counts.action, 0

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

      test 'fail was passed correct arguments', ->
        assert.lengthOf log.args.fail[0], 1
        assert.strictEqual log.args.fail[0][0], 'baz'

      test 'fail was applied to correct context', ->
        assert.strictEqual log.these.fail[0], context

      test 'pass was not called', ->
        assert.strictEqual log.counts.pass, 0

    suite 'when failing five times:', ->
      log = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log, callback: done }
        fail = spooks.fn { name: 'fail', log, callback: done }
        trier.attempt { when: predicate, action, fail, interval: 0, limit: 5 }

      teardown ->
        log = predicate = action = fail = undefined

      test 'predicate was called five times', ->
        assert.strictEqual log.counts.predicate, 5

      test 'action was not called', ->
        assert.strictEqual log.counts.action, 0

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

    suite 'when failing exponential:', ->
      log = timestamps = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = []
        predicate = spooks.fn {
          name: 'predicate',
          log,
          result: false,
          callback: ->
            timestamps.push Date.now()
        }
        action = spooks.fn { name: 'action', log, callback: done }
        fail = spooks.fn { name: 'fail', log, callback: done }
        timestamps.push Date.now()
        trier.attempt { when: predicate, action, fail, interval: -32, limit: 4 }

      teardown ->
        log = timestamps = predicate = action = fail = undefined

      test 'five timestamps were recorded', ->
        assert.lengthOf timestamps, 5

      test 'first interval is immediate', ->
        assert.isTrue timestamps[1] < timestamps[0] + 16

      test 'second interval is about 32 ms', ->
        assert.isTrue timestamps[2] > timestamps[1] + 16
        assert.isTrue timestamps[2] < timestamps[1] + 48

      test 'third interval is about 64 ms', ->
        assert.isTrue timestamps[3] > timestamps[2] + 48
        assert.isTrue timestamps[3] < timestamps[2] + 80

      test 'fourth interval is about 128 ms', ->
        assert.isTrue timestamps[4] > timestamps[3] + 112
        assert.isTrue timestamps[4] < timestamps[3] + 144

    suite 'until passing immediately:', ->
      log = predicate = action = fail = pass = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: true }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        pass = spooks.fn { name: 'pass', log, callback: done }
        context = {}
        args = [ 'foo', 'bar' ]
        trier.attempt { until: predicate, action, fail, pass, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = pass = context = args = undefined

      test 'predicate was called once', ->
        assert.strictEqual log.counts.predicate, 1

      test 'predicate was passed correct arguments', ->
        assert.lengthOf log.args.predicate[0], 2
        assert.strictEqual log.args.predicate[0][0], 'foo'
        assert.strictEqual log.args.predicate[0][1], 'bar'

      test 'predicate was applied to correct context', ->
        assert.strictEqual log.these.predicate[0], context

      test 'action was called once', ->
        assert.strictEqual log.counts.action, 1

      test 'action was passed correct arguments', ->
        assert.lengthOf log.args.action[0], 2
        assert.strictEqual log.args.action[0][0], 'foo'
        assert.strictEqual log.args.action[0][1], 'bar'

      test 'action was applied to correct context', ->
        assert.strictEqual log.these.action[0], context

      test 'fail was not called', ->
        assert.strictEqual log.counts.fail, 0

      test 'pass was called once', ->
        assert.strictEqual log.counts.pass, 1

      test 'pass was passed correct arguments', ->
        assert.lengthOf log.args.pass[0], 2
        assert.strictEqual log.args.pass[0][0], 'foo'
        assert.strictEqual log.args.pass[0][1], 'bar'

      test 'pass was applied to correct context', ->
        assert.strictEqual log.these.pass[0], context

      test 'pass was called once', ->
        assert.strictEqual log.counts.pass, 1

      test 'pass was passed correct arguments', ->
        assert.lengthOf log.args.pass[0], 2
        assert.strictEqual log.args.pass[0][0], 'foo'
        assert.strictEqual log.args.pass[0][1], 'bar'

      test 'pass was applied to correct context', ->
        assert.strictEqual log.these.pass[0], context

    suite 'until failing three times:', ->
      log = predicate = action = fail = pass = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        pass = spooks.fn { name: 'pass', log, callback: done }
        context = {}
        args = [ 'baz' ]
        trier.attempt { until: predicate, action, fail, pass, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = pass = context = args = undefined

      test 'predicate was called three times', ->
        assert.strictEqual log.counts.predicate, 3

      test 'predicate was passed correct arguments first time', ->
        assert.lengthOf log.args.predicate[0], 1
        assert.strictEqual log.args.predicate[0][0], 'baz'

      test 'predicate was applied to correct context first time', ->
        assert.strictEqual log.these.predicate[0], context

      test 'predicate was passed correct arguments second time', ->
        assert.lengthOf log.args.predicate[1], 1
        assert.strictEqual log.args.predicate[1][0], 'baz'

      test 'predicate was applied to correct context second time', ->
        assert.strictEqual log.these.predicate[1], context

      test 'predicate was passed correct arguments third time', ->
        assert.lengthOf log.args.predicate[2], 1
        assert.strictEqual log.args.predicate[2][0], 'baz'

      test 'predicate was applied to correct context third time', ->
        assert.strictEqual log.these.predicate[2], context

      test 'action was called three times', ->
        assert.strictEqual log.counts.action, 3

      test 'action was passed correct arguments first time', ->
        assert.lengthOf log.args.action[0], 1
        assert.strictEqual log.args.action[0][0], 'baz'

      test 'action was applied to correct context first time', ->
        assert.strictEqual log.these.action[0], context

      test 'action was passed correct arguments second time', ->
        assert.lengthOf log.args.action[1], 1
        assert.strictEqual log.args.action[1][0], 'baz'

      test 'action was applied to correct context second time', ->
        assert.strictEqual log.these.action[1], context

      test 'action was passed correct arguments third time', ->
        assert.lengthOf log.args.action[2], 1
        assert.strictEqual log.args.action[2][0], 'baz'

      test 'action was applied to correct context third time', ->
        assert.strictEqual log.these.action[2], context

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

      test 'fail was passed correct arguments', ->
        assert.lengthOf log.args.fail[0], 1
        assert.strictEqual log.args.fail[0][0], 'baz'

      test 'fail was applied to correct context', ->
        assert.strictEqual log.these.fail[0], context

      test 'pass was not called', ->
        assert.strictEqual log.counts.pass, 0

    suite 'until failing five times:', ->
      log = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        trier.attempt { until: predicate, action, fail, interval: 0, limit: 5 }

      teardown ->
        log = predicate = action = fail = undefined

      test 'predicate was called five times', ->
        assert.strictEqual log.counts.predicate, 5

      test 'action was called five times', ->
        assert.strictEqual log.counts.action, 5

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

    suite 'until failing exponential:', ->
      log = timestamps = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = []
        predicate = spooks.fn {
          name: 'predicate',
          log,
          result: false,
          callback: ->
            timestamps.push Date.now()
        }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        timestamps.push Date.now()
        trier.attempt { until: predicate, action, fail, interval: -32, limit: 4 }

      teardown ->
        log = timestamps = predicate = action = fail = undefined

      test 'five timestamps were recorded', ->
        assert.lengthOf timestamps, 5

      test 'first interval is immediate', ->
        assert.isTrue timestamps[1] < timestamps[0] + 16

      test 'second interval is about 32 ms', ->
        assert.isTrue timestamps[2] > timestamps[1] + 16
        assert.isTrue timestamps[2] < timestamps[1] + 48

      test 'third interval is about 64 ms', ->
        assert.isTrue timestamps[3] > timestamps[2] + 48
        assert.isTrue timestamps[3] < timestamps[2] + 80

      test 'fourth interval is about 128 ms', ->
        assert.isTrue timestamps[4] > timestamps[3] + 112
        assert.isTrue timestamps[4] < timestamps[3] + 144

    suite 'when passing immediately and until failing five times:', ->
      log = predicateWhen = predicateUntil = action = fail = undefined

      setup (done) ->
        log = {}
        predicateWhen = spooks.fn { name: 'predicateWhen', log, result: true }
        predicateUntil = spooks.fn { name: 'predicateUntil', log, result: false }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        trier.attempt { when: predicateWhen, until: predicateUntil, action, fail, interval: 0, limit: 5 }

      teardown ->
        log = predicateWhen = predicateUntil = action = fail = undefined

      test 'when predicate was called five times', ->
        assert.strictEqual log.counts.predicateWhen, 5

      test 'until predicate was called five times', ->
        assert.strictEqual log.counts.predicateUntil, 5

      test 'action was called five times', ->
        assert.strictEqual log.counts.action, 5

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

    suite 'when failing five times and until passing immediately:', ->
      log = predicateWhen = predicateUntil = action = fail = undefined

      setup (done) ->
        log = {}
        predicateWhen = spooks.fn { name: 'predicateWhen', log, result: false }
        predicateUntil = spooks.fn { name: 'predicateUntil', log, result: true }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        trier.attempt { when: predicateWhen, until: predicateUntil, action, fail, interval: 0, limit: 5 }

      teardown ->
        log = predicateWhen = predicateUntil = action = fail = undefined

      test 'when predicate was called five times', ->
        assert.strictEqual log.counts.predicateWhen, 5

      test 'until predicate was never called', ->
        assert.strictEqual log.counts.predicateUntil, 0

      test 'action was never called', ->
        assert.strictEqual log.counts.action, 0

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

    suite 'when passing immediately and until failing exponential:', ->
      log = timestamps = predicateWhen = predicateUntil = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = { predicateWhen: [], predicateUntil: [] }
        predicateWhen = spooks.fn {
          name: 'predicateWhen',
          log,
          result: true,
          callback: ->
            timestamps.predicateWhen.push Date.now()
        }
        predicateUntil = spooks.fn {
          name: 'predicateUntil',
          log,
          result: false,
          callback: ->
            timestamps.predicateUntil.push Date.now()
        }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        now = Date.now()
        timestamps.predicateWhen.push now
        timestamps.predicateUntil.push now
        trier.attempt { when: predicateWhen, until: predicateUntil, action, fail, interval: -32, limit: 4 }

      teardown ->
        log = predicateWhen = predicateUntil = action = fail = undefined

      test 'five timestamps were recorded for when', ->
        assert.lengthOf timestamps.predicateWhen, 5

      test 'five timestamps were recorded for until', ->
        assert.lengthOf timestamps.predicateUntil, 5

      test 'first when interval is immediate', ->
        assert.isTrue timestamps.predicateWhen[1] < timestamps.predicateWhen[0] + 16

      test 'first until interval is immediate', ->
        assert.isTrue timestamps.predicateUntil[1] < timestamps.predicateUntil[0] + 16

      test 'second when interval is about 32 ms', ->
        assert.isTrue timestamps.predicateWhen[2] > timestamps.predicateWhen[1] + 16
        assert.isTrue timestamps.predicateWhen[2] < timestamps.predicateWhen[1] + 48

      test 'second until interval is about 32 ms', ->
        assert.isTrue timestamps.predicateUntil[2] > timestamps.predicateUntil[1] + 16
        assert.isTrue timestamps.predicateUntil[2] < timestamps.predicateUntil[1] + 48

      test 'third when interval is about 64 ms', ->
        assert.isTrue timestamps.predicateWhen[3] > timestamps.predicateWhen[2] + 48
        assert.isTrue timestamps.predicateWhen[3] < timestamps.predicateWhen[2] + 80

      test 'third until interval is about 64 ms', ->
        assert.isTrue timestamps.predicateUntil[3] > timestamps.predicateUntil[2] + 48
        assert.isTrue timestamps.predicateUntil[3] < timestamps.predicateUntil[2] + 80

      test 'fourth when interval is about 128 ms', ->
        assert.isTrue timestamps.predicateWhen[4] > timestamps.predicateWhen[3] + 112
        assert.isTrue timestamps.predicateWhen[4] < timestamps.predicateWhen[3] + 144

      test 'fourth until interval is about 128 ms', ->
        assert.isTrue timestamps.predicateUntil[4] > timestamps.predicateUntil[3] + 112
        assert.isTrue timestamps.predicateUntil[4] < timestamps.predicateUntil[3] + 144

    suite 'when failing exponential and until passing immediately:', ->
      log = timestamps = predicateWhen = predicateUntil = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = { predicateWhen: [], predicateUntil: [] }
        predicateWhen = spooks.fn {
          name: 'predicateWhen',
          log,
          result: false,
          callback: ->
            timestamps.predicateWhen.push Date.now()
        }
        predicateUntil = spooks.fn {
          name: 'predicateUntil',
          log,
          result: true,
          callback: ->
            timestamps.predicateUntil.push Date.now()
        }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        now = Date.now()
        timestamps.predicateWhen.push now
        timestamps.predicateUntil.push now
        trier.attempt { when: predicateWhen, until: predicateUntil, action, fail, interval: -32, limit: 4 }

      teardown ->
        log = timestamps = predicateWhen = predicateUntil = action = fail = undefined

      test 'five timestamps were recorded for when', ->
        assert.lengthOf timestamps.predicateWhen, 5

      test 'one timestamp was recorded for until', ->
        assert.lengthOf timestamps.predicateUntil, 1

      test 'first when interval is immediate', ->
        assert.isTrue timestamps.predicateWhen[1] < timestamps.predicateWhen[0] + 16

      test 'second when interval is about 32 ms', ->
        assert.isTrue timestamps.predicateWhen[2] > timestamps.predicateWhen[1] + 16
        assert.isTrue timestamps.predicateWhen[2] < timestamps.predicateWhen[1] + 48

      test 'third when interval is about 64 ms', ->
        assert.isTrue timestamps.predicateWhen[3] > timestamps.predicateWhen[2] + 48
        assert.isTrue timestamps.predicateWhen[3] < timestamps.predicateWhen[2] + 80

      test 'fourth when interval is about 128 ms', ->
        assert.isTrue timestamps.predicateWhen[4] > timestamps.predicateWhen[3] + 112
        assert.isTrue timestamps.predicateWhen[4] < timestamps.predicateWhen[3] + 144

    suite 'asynchronous action:', ->
      log = timestamps = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = []
        predicate = ->
          timestamps.push Date.now()
          false
        action = (trierDone) ->
          setTimeout trierDone, 64
        timestamps.push Date.now()
        trier.attempt { until: predicate, action, fail: done, interval: 0, limit: 3 }

      teardown ->
        log = timestamps = predicate = action = fail = undefined

      test 'four timestamps were recorded', ->
        assert.lengthOf timestamps, 4

      test 'first interval is about 64 ms', ->
        assert.isTrue timestamps[1] > timestamps[0] + 48
        assert.isTrue timestamps[1] < timestamps[0] + 80

      test 'second interval is about 64 ms', ->
        assert.isTrue timestamps[2] > timestamps[1] + 48
        assert.isTrue timestamps[2] < timestamps[1] + 80

      test 'third interval is about 64 ms', ->
        assert.isTrue timestamps[3] > timestamps[2] + 48
        assert.isTrue timestamps[3] < timestamps[2] + 80

