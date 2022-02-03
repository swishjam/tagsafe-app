const Tracium = require('tracium'),
        fs = require('fs');

const args = process.argv.slice(2);
// const pageTraceJSON = args[0];
const jsonPath = args[0]
const outputFilePath = args[1];

console.log(`Parsing trace JSON from ${jsonPath} to ${outputFilePath}....`);
fs.readFile(jsonPath, 'utf8', function (err, data) {
  if(err) {
    throw err;
  }
  console.log(`Tracium computing with JSON data`);
  const parsedTraceJson = Tracium.computeMainThreadTasks(JSON.parse(data));
  fs.writeFile(outputFilePath, parsedTraceJson);
  console.log(`Trace JSON parsed and written to ${outputFilePath}`);
})