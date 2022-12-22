const speedline = require('speedline-core'),
        fs = require('fs');

// speedline('./timeline.json').then(results => {
//   console.log(`Evaluating ${results.frames.length} frames`);
//   const baseTs = results.frames[0].getTimeStamp();
//   const visualProgressFormattedForChart = [];
//   results.frames.forEach(frame => {
//     // console.log(`Histo: ${frame.getHistogram()}`)
//     console.log(`getPerceptualProgress: ${frame.getPerceptualProgress()}`)
//     visualProgressFormattedForChart.push([ frame.getTimeStamp() - baseTs, frame.getPerceptualProgress() ]);
//     const buffer = Buffer.from(frame.getImage());
//     fs.writeFileSync(`./frames/${frame.getProgress()}.png`, buffer, (err) => { if(err) throw new Error(err) });
//   });
//   console.log(visualProgressFormattedForChart);
// });

gatherSpeedIndexResults = async () => {
  const speedlineResult = await _calculateSpeedIndexFromTraceFile();
  const res = {
    speed_index: speedlineResult.speedIndex,
    perceptual_speed_index: speedlineResult.perceptualSpeedIndex,
    recording_start_ts: speedlineResult.beginning,
    recording_end_ts: speedlineResult.end,
    ms_before_first_visual_change: speedlineResult.first,
    ms_before_last_visual_change: speedlineResult.last,
    total_recording_duration_ms: speedlineResult.duration,
    total_frames: speedlineResult.frames.length,
    visual_progress_chart_data: _formatVisualProgressChartData(speedlineResult),
    frame_screenshots: await _formatAndUploadFrameScreenshotsToS3(speedlineResult)
  }
  // console.log(res)
  return res;
}

_calculateSpeedIndexFromTraceFile = async () => {
  // console.log(`Calculating speed index, reading from Trace file ${this.localFilePath}`);
  return new Promise(resolve => {
    speedline('./timeline.json').then(resolve);
  })
}

_formatAndUploadFrameScreenshotsToS3 = async speedlineResult => {
  const formattedFrameScreenshots = [];
  const baseTs = speedlineResult.frames[0].getTimeStamp();
  for(let i = 0; i < speedlineResult.frames.length; i++) {
    const frame = speedlineResult.frames[i];
    const buffer = Buffer.from(frame.getImage());
    // const s3Url = await uploadToS3({ Body: buffer, Key: `${this.uniqueFilename}-frame-${i}`});
    const s3Url = `unique-s3-key-frame-${i}`;
    formattedFrameScreenshots.push({
      ms_from_start: frame.getTimeStamp() - baseTs,
      ts: frame.getTimeStamp(),
      progress: frame.getProgress(),
      perceptual_progress: frame.getPerceptualProgress(),
      s3_url: s3Url
    })
  }
  return formattedFrameScreenshots;
}

_formatVisualProgressChartData = speedlineResult => {
  const baseTs = speedlineResult.frames[0].getTimeStamp();
  return speedlineResult.frames.map(frame => [ frame.getTimeStamp() - baseTs, frame.getPerceptualProgress() ]);
}

gatherSpeedIndexResults().then(console.log);