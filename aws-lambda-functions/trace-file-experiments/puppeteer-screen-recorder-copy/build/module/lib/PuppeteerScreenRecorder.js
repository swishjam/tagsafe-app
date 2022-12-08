import fs from 'fs';
import { dirname } from 'path';
import { pageVideoStreamCollector } from './pageVideoStreamCollector';
import PageVideoStreamWriter from './pageVideoStreamWriter';
/**
 * @ignore
 * @default
 * @description This will be option passed to the puppeteer screen recorder
 */
const defaultPuppeteerScreenRecorderOptions = {
    followNewTab: true,
    fps: 25,
    ffmpeg_Path: null,
    videoFrame: {
        width: null,
        height: null,
    },
    aspectRatio: '4:3',
};
/**
 * PuppeteerScreenRecorder class is responsible for managing the video
 *
 * ```typescript
 * const screenRecorderOptions = {
 *  followNewTab: true,
 *  fps: 25,
 * }
 * const savePath = "./test/demo.mp4";
 * const screenRecorder = new PuppeteerScreenRecorder(page, screenRecorderOptions);
 * await screenRecorder.start(savePath);
 *  // some puppeteer action or test
 * await screenRecorder.stop()
 * ```
 */
export class PuppeteerScreenRecorder {
    constructor(page, options = {}) {
        this.isScreenCaptureEnded = null;
        this.options = Object.assign({}, defaultPuppeteerScreenRecorderOptions, options);
        this.streamReader = new pageVideoStreamCollector(page, this.options);
        this.page = page;
    }
    /**
     * @ignore
     */
    setupListeners() {
        this.page.on('close', async () => await this.stop());
        this.streamReader.on('pageScreenFrame', (pageScreenFrame) => {
            this.streamWriter.insert(pageScreenFrame);
        });
        this.streamWriter.on('videoStreamWriterError', () => this.stop());
    }
    /**
     * @ignore
     */
    async ensureDirectoryExist(dirPath) {
        return new Promise((resolve, reject) => {
            try {
                fs.mkdirSync(dirPath, { recursive: true });
                return resolve(dirPath);
            }
            catch (error) {
                reject(error);
            }
        });
    }
    /**
     * @ignore
     * @private
     * @method startStreamReader
     * @description start listening for video stream from the page.
     * @returns PuppeteerScreenRecorder
     */
    async startStreamReader() {
        this.setupListeners();
        await this.streamReader.start();
        return this;
    }
    /**
     * @public
     * @method getRecordDuration
     * @description return the total duration of the video recorded,
     *  1. if this method is called before calling the stop method, it would be return the time till it has recorded.
     *  2. if this method is called after stop method, it would give the total time for recording
     * @returns total duration of video
     */
    getRecordDuration() {
        if (!this.streamWriter) {
            return '00:00:00:00';
        }
        return this.streamWriter.duration;
    }
    /**
     *
     * @public
     * @method start
     * @param savePath accepts a path string to store the video
     * @description Start the video capturing session
     * @returns PuppeteerScreenRecorder
     * @example
     * ```
     *  const savePath = './test/demo.mp4'; //.mp4 is required
     *  await recorder.start(savePath);
     * ```
     */
    async start(savePath) {
        await this.ensureDirectoryExist(dirname(savePath));
        this.streamWriter = new PageVideoStreamWriter(savePath, this.options);
        return this.startStreamReader();
    }
    /**
     *
     * @public
     * @method startStream
     * @description Start the video capturing session in a stream
     * @returns {PuppeteerScreenRecorder}
     * @example
     * ```
     *  const stream = new PassThrough();
     *  await recorder.startStream(stream);
     * ```
     */
    async startStream(stream) {
        this.streamWriter = new PageVideoStreamWriter(stream, this.options);
        return this.startStreamReader();
    }
    /**
     * @public
     * @method stop
     * @description stop the video capturing session
     * @returns indicate whether stop is completed correct or not, if true without any error else false.
     */
    async stop() {
        if (this.isScreenCaptureEnded !== null) {
            return this.isScreenCaptureEnded;
        }
        await this.streamReader.stop();
        this.isScreenCaptureEnded = await this.streamWriter.stop();
        return this.isScreenCaptureEnded;
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiUHVwcGV0ZWVyU2NyZWVuUmVjb3JkZXIuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi9zcmMvbGliL1B1cHBldGVlclNjcmVlblJlY29yZGVyLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBLE9BQU8sRUFBRSxNQUFNLElBQUksQ0FBQztBQUNwQixPQUFPLEVBQUUsT0FBTyxFQUFFLE1BQU0sTUFBTSxDQUFDO0FBSy9CLE9BQU8sRUFBRSx3QkFBd0IsRUFBRSxNQUFNLDRCQUE0QixDQUFDO0FBRXRFLE9BQU8scUJBQXFCLE1BQU0seUJBQXlCLENBQUM7QUFFNUQ7Ozs7R0FJRztBQUNILE1BQU0scUNBQXFDLEdBQW1DO0lBQzVFLFlBQVksRUFBRSxJQUFJO0lBQ2xCLEdBQUcsRUFBRSxFQUFFO0lBQ1AsV0FBVyxFQUFFLElBQUk7SUFDakIsVUFBVSxFQUFFO1FBQ1YsS0FBSyxFQUFFLElBQUk7UUFDWCxNQUFNLEVBQUUsSUFBSTtLQUNiO0lBQ0QsV0FBVyxFQUFFLEtBQUs7Q0FDbkIsQ0FBQztBQUVGOzs7Ozs7Ozs7Ozs7OztHQWNHO0FBQ0gsTUFBTSxPQUFPLHVCQUF1QjtJQU9sQyxZQUFZLElBQVUsRUFBRSxPQUFPLEdBQUcsRUFBRTtRQUY1Qix5QkFBb0IsR0FBbUIsSUFBSSxDQUFDO1FBR2xELElBQUksQ0FBQyxPQUFPLEdBQUcsTUFBTSxDQUFDLE1BQU0sQ0FDMUIsRUFBRSxFQUNGLHFDQUFxQyxFQUNyQyxPQUFPLENBQ1IsQ0FBQztRQUNGLElBQUksQ0FBQyxZQUFZLEdBQUcsSUFBSSx3QkFBd0IsQ0FBQyxJQUFJLEVBQUUsSUFBSSxDQUFDLE9BQU8sQ0FBQyxDQUFDO1FBQ3JFLElBQUksQ0FBQyxJQUFJLEdBQUcsSUFBSSxDQUFDO0lBQ25CLENBQUM7SUFFRDs7T0FFRztJQUNLLGNBQWM7UUFDcEIsSUFBSSxDQUFDLElBQUksQ0FBQyxFQUFFLENBQUMsT0FBTyxFQUFFLEtBQUssSUFBSSxFQUFFLENBQUMsTUFBTSxJ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