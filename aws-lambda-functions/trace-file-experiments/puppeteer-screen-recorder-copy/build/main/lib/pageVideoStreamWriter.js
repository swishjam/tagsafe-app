"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const events_1 = require("events");
const os_1 = __importDefault(require("os"));
const path_1 = require("path");
const stream_1 = require("stream");
const fluent_ffmpeg_1 = __importStar(require("fluent-ffmpeg"));
const pageVideoStreamTypes_1 = require("./pageVideoStreamTypes");
/**
 * @ignore
 */
const SUPPORTED_FILE_FORMATS = [
    pageVideoStreamTypes_1.SupportedFileFormats.MP4,
    pageVideoStreamTypes_1.SupportedFileFormats.AVI,
    pageVideoStreamTypes_1.SupportedFileFormats.MOV,
    pageVideoStreamTypes_1.SupportedFileFormats.WEBM,
];
/**
 * @ignore
 */
class PageVideoStreamWriter extends events_1.EventEmitter {
    constructor(destinationSource, options) {
        super();
        this.screenLimit = 40;
        this.screenCastFrames = [];
        this.duration = '00:00:00:00';
        this.status = pageVideoStreamTypes_1.VIDEO_WRITE_STATUS.NOT_STARTED;
        this.videoMediatorStream = new stream_1.PassThrough();
        if (options) {
            this.options = options;
        }
        const isWritable = this.isWritableStream(destinationSource);
        this.configureFFmPegPath();
        if (isWritable) {
            this.configureVideoWritableStream(destinationSource);
        }
        else {
            this.configureVideoFile(destinationSource);
        }
    }
    get videoFrameSize() {
        const { width, height } = this.options.videoFrame;
        return width !== null && height !== null ? `${width}x${height}` : '100%';
    }
    getFfmpegPath() {
        if (this.options.ffmpeg_Path) {
            return this.options.ffmpeg_Path;
        }
        try {
            // eslint-disable-next-line @typescript-eslint/no-var-requires
            const ffmpeg = require('@ffmpeg-installer/ffmpeg');
            if (ffmpeg.path) {
                return ffmpeg.path;
            }
            return null;
        }
        catch (e) {
            return null;
        }
    }
    getDestinationPathExtension(destinationFile) {
        const fileExtension = path_1.extname(destinationFile);
        return fileExtension.includes('.')
            ? fileExtension.replace('.', '')
            : fileExtension;
    }
    configureFFmPegPath() {
        const ffmpegPath = this.getFfmpegPath();
        if (!ffmpegPath) {
            throw new Error('FFmpeg path is missing, \n Set the FFMPEG_PATH env variable');
        }
        fluent_ffmpeg_1.setFfmpegPath(ffmpegPath);
    }
    isWritableStream(destinationSource) {
        if (destinationSource && typeof destinationSource !== 'string') {
            if (!(destinationSource instanceof stream_1.Writable) ||
                !('writable' in destinationSource) ||
                !destinationSource.writable) {
                throw new Error('Output should be a writable stream');
            }
            return true;
        }
        return false;
    }
    configureVideoFile(destinationPath) {
        const fileExt = this.getDestinationPathExtension(destinationPath);
        if (!SUPPORTED_FILE_FORMATS.includes(fileExt)) {
            throw new Error('File format is not supported');
        }
        this.writerPromise = new Promise((resolve) => {
            const outputStream = this.getDestinationStream();
            outputStream
                .on('error', (e) => {
                this.handleWriteStreamError(e.message);
                resolve(false);
            })
                .on('end', () => resolve(true))
                .save(destinationPath);
            if (fileExt == pageVideoStreamTypes_1.SupportedFileFormats.WEBM) {
                outputStream
                    .videoCodec('libvpx')
                    .videoBitrate(1000, true)
                    .outputOptions('-flags', '+global_header', '-psnr');
            }
        });
    }
    configureVideoWritableStream(writableStream) {
        this.writerPromise = new Promise((resolve) => {
            const outputStream = this.getDestinationStream();
            outputStream
                .on('error', (e) => {
                writableStream.emit('error', e);
                resolve(false);
            })
                .on('end', () => {
                writableStream.end();
                resolve(true);
            });
            outputStream.toFormat('mp4');
            outputStream.addOutputOptions('-movflags +frag_keyframe+separate_moof+omit_tfhd_offset+empty_moov');
            outputStream.pipe(writableStream);
        });
    }
    getDestinationStream() {
        const cpu = Math.min(1, os_1.default.cpus().length);
        const outputStream = fluent_ffmpeg_1.default({
            source: this.videoMediatorStream,
            priority: 20,
        })
            .videoCodec('libx264')
            .size(this.videoFrameSize)
            .aspect(this.options.aspectRatio || '4:3')
            .inputFormat('image2pipe')
            .inputFPS(this.options.fps)
            .outputOptions('-preset ultrafast')
            .outputOptions('-pix_fmt yuv420p')
            .outputOptions('-minrate 1000')
            .outputOptions('-maxrate 1000')
            .outputOptions(`-threads ${cpu}`)
            .on('progress', (progressDetails) => {
            this.duration = progressDetails.timemark;
        });
        if (this.options.recordDurationLimit) {
            outputStream.duration(this.options.recordDurationLimit);
        }
        return outputStream;
    }
    handleWriteStreamError(errorMessage) {
        this.emit('videoStreamWriterError', errorMessage);
        if (this.status !== pageVideoStreamTypes_1.VIDEO_WRITE_STATUS.IN_PROGRESS &&
            errorMessage.includes('pipe:0: End of file')) {
            return;
        }
        return console.error(`Error unable to capture video stream: ${errorMessage}`);
    }
    findSlot(timestamp) {
        if (this.screenCastFrames.length === 0) {
            return 0;
        }
        let i;
        let frame;
        for (i = this.screenCastFrames.length - 1; i >= 0; i--) {
            frame = this.screenCastFrames[i];
            if (timestamp > frame.timestamp) {
                break;
            }
        }
        return i + 1;
    }
    insert(frame) {
        // reduce the queue into half when it is full
        if (this.screenCastFrames.length === this.screenLimit) {
            const numberOfFramesToSplice = Math.floor(this.screenLimit / 2);
            const framesToProcess = this.screenCastFrames.splice(0, numberOfFramesToSplice);
            this.processFrameBeforeWrite(framesToProcess);
        }
        const insertionIndex = this.findSlot(frame.timestamp);
        if (insertionIndex === this.screenCastFrames.length) {
            this.screenCastFrames.push(frame);
        }
        else {
            this.screenCastFrames.splice(insertionIndex, 0, frame);
        }
    }
    trimFrame(fameList) {
        if (!this.lastProcessedFrame) {
            this.lastProcessedFrame = fameList[0];
        }
        return fameList.map((currentFrame) => {
            const duration = currentFrame.timestamp - this.lastProcessedFrame.timestamp;
            this.lastProcessedFrame = currentFrame;
            return Object.assign(Object.assign({}, currentFrame), { duration });
        });
    }
    processFrameBeforeWrite(frames) {
        const processedFrames = this.trimFrame(frames);
        processedFrames.forEach(({ blob, duration }) => {
            this.write(blob, duration);
        });
    }
    write(data, durationSeconds = 1) {
        this.status = pageVideoStreamTypes_1.VIDEO_WRITE_STATUS.IN_PROGRESS;
        const NUMBER_OF_FPS = Math.max(Math.floor(durationSeconds * this.options.fps), 1);
        for (let i = 0; i < NUMBER_OF_FPS; i++) {
            this.videoMediatorStream.write(data);
        }
    }
    drainFrames(stoppedTime) {
        this.processFrameBeforeWrite(this.screenCastFrames);
        this.screenCastFrames = [];
        if (!this.lastProcessedFrame)
            return;
        const durationSeconds = stoppedTime - this.lastProcessedFrame.timestamp;
        this.write(this.lastProcessedFrame.blob, durationSeconds);
    }
    stop(stoppedTime = Date.now() / 1000) {
        if (this.status === pageVideoStreamTypes_1.VIDEO_WRITE_STATUS.COMPLETED) {
            return this.writerPromise;
        }
        this.drainFrames(stoppedTime);
        this.videoMediatorStream.end();
        this.status = pageVideoStreamTypes_1.VIDEO_WRITE_STATUS.COMPLETED;
        return this.writerPromise;
    }
}
exports.default = PageVideoStreamWriter;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicGFnZVZpZGVvU3RyZWFtV3JpdGVyLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vc3JjL2xpYi9wYWdlVmlkZW9TdHJlYW1Xcml0ZXIudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6Ijs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBQUEsbUNBQXNDO0FBQ3RDLDRDQUFvQjtBQUNwQiwrQkFBK0I7QUFDL0IsbUNBQStDO0FBRS9DLCtEQUFzRDtBQUV0RCxpRUFLZ0M7QUFFaEM7O0dBRUc7QUFDSCxNQUFNLHNCQUFzQixHQUFHO0lBQzdCLDJDQUFvQixDQUFDLEdBQUc7SUFDeEIsMkNBQW9CLENBQUMsR0FBRztJQUN4QiwyQ0FBb0IsQ0FBQyxHQUFHO0lBQ3hCLDJDQUFvQixDQUFDLElBQUk7Q0FDMUIsQ0FBQztBQUVGOztHQUVHO0FBQ0gsTUFBcUIscUJBQXNCLFNBQVEscUJBQVk7SUFZN0QsWUFBWSxpQkFBb0MsRUFBRSxPQUFzQjtRQUN0RSxLQUFLLEVBQUUsQ0FBQztRQVpPLGdCQUFXLEdBQUcsRUFBRSxDQUFDO1FBQzFCLHFCQUFnQixHQUFHLEVBQUUsQ0FBQztRQUV2QixhQUFRLEdBQUcsYUFBYSxDQUFDO1FBRXhCLFdBQU0sR0FBRyx5Q0FBa0IsQ0FBQyxXQUFXLENBQUM7UUFHeEMsd0JBQW1CLEdBQWdCLElBQUksb0JBQVcsRUFBRSxDQUFDO1FBTTNELElBQUksT0FBTyxFQUFFO1lBQ1gsSUFBSSxDQUFDLE9BQU8sR0FBRyxPQUFPLENBQUM7U0FDeEI7UUFFRCxNQUFNLFVBQVUsR0FBRyxJQUFJLENBQUMsZ0JBQWdCLENBQUMsaUJBQWlCLENBQUMsQ0FBQztRQUM1RCxJQUFJLENBQUMsbUJBQW1CLEVBQUUsQ0FBQztRQUMzQixJQUFJLFVBQVUsRUFBRTtZQUNkLElBQUksQ0FBQyw0QkFBNEIsQ0FBQyxpQkFBNkIsQ0FBQyxDQUFDO1NBQ2xFO2FBQU07WUFDTCxJQUFJLENBQUMsa0JBQWtCLENBQUMsaUJBQTJCLENBQUMsQ0FB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