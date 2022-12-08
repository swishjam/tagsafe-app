module.exports = executionMs => {
  const costPerGigabyteMs = 0.0000166667 / 1_000;
  const allocatedGigabytes = parseInt(process.env.AWS_LAMBDA_FUNCTION_MEMORY_SIZE) / 1_000;
  return costPerGigabyteMs * allocatedGigabytes * executionMs;
}