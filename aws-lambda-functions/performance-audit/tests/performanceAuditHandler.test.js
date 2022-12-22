const handler = require('../performanceAuditHandler'),
        mockEvent = require('./mockEvent'),
        AuditRunner = require('../src/auditRunner'),
        PuppeteerModerator = require('../src/puppeteerModerator'),
        PageEventHandler = require('../src/pageEventHandler');

beforeEach(() => {
  jest.spyOn(AuditRunner.prototype, 'runPerformanceAudit').mockImplementation(() => console.log('`AuditRunner` `.runPerformanceAudit()` method stubbed!'));
  jest.spyOn(PuppeteerModerator.prototype, 'launch').mockImplementation(() => console.log('`PuppeteerModerator` `.launch()` method stubbed!'));
  jest.spyOn(PuppeteerModerator.prototype, 'shutdown').mockImplementation(() => console.log('`PuppeteerModerator` `.shutdown()` method stubbed!'));
  jest.spyOn(PageEventHandler.prototype, '_listenForTagsafeLogEvents').mockImplementation(() => console.log('`PageEventHandler` `.listenForTagsafeLogEvents()` method stubbed!'));
});

afterEach(() => {
  jest.restoreAllMocks();
});

test('performanceAuditHandler calls runPerformanceAudit on AuditRunner', async () => {
  await handler.runPerformanceAudit(mockEvent, {});
  expect(AuditRunner.prototype.runPerformanceAudit).toHaveBeenCalledTimes(1);
})

test('performanceAuditHandler calls launch on PuppeteerModerator', async () => {
  await handler.runPerformanceAudit(mockEvent, {});
  expect(PuppeteerModerator.prototype.launch).toHaveBeenCalledTimes(1);
})

test('performanceAuditHandler calls shutdown on PuppeteerModerator', async () => {
  await handler.runPerformanceAudit(mockEvent, {});
  expect(PuppeteerModerator.prototype.shutdown).toHaveBeenCalledTimes(1);
})

test('returns the correctly structured results', async () => {
  const results = await handler.runPerformanceAudit(mockEvent, {});

  expect(results.hasOwnProperty('execution_time_ms'));
  expect(results.hasOwnProperty('results'));
  expect(results.hasOwnProperty('screen_recording'));
  expect(results.screen_recording.hasOwnProperty('s3_url'));
  expect(results.screen_recording.hasOwnProperty('ms_to_stop_recording'));
  expect(results.hasOwnProperty('tracing_results_s3_url'));
  expect(results.hasOwnProperty('blocked_resources'));
  expect(results.hasOwnProperty('cached_requests'));
  expect(results.hasOwnProperty('not_cached_requests'));
  expect(results.hasOwnProperty('potential_errors'));
  expect(results.potential_errors.hasOwnProperty('uncaught_errors'));
  expect(results.potential_errors.hasOwnProperty('failed_network_requests'));
  expect(results.potential_errors.hasOwnProperty('console_errors'));
  expect(results.potential_errors.hasOwnProperty('aws_request_id'));
  expect(results.potential_errors.hasOwnProperty('aws_log_group_name'));
  expect(results.potential_errors.hasOwnProperty('aws_log_stream_name'));
  expect(results.potential_errors.hasOwnProperty('aws_trace_id'));
  expect(results.potential_errors.hasOwnProperty('aws_estimated_lambda_cost'));
});