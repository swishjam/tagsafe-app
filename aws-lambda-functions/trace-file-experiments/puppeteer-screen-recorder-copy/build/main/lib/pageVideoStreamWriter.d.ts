/// <reference types="node" />
import { EventEmitter } from 'events';
import { Writable } from 'stream';
import { pageScreenFrame, VideoOptions } from './pageVideoStreamTypes';
/**
 * @ignore
 */
export default class PageVideoStreamWriter extends EventEmitter {
    private readonly screenLimit;
    private screenCastFrames;
    private lastProcessedFrame;
    duration: string;
    private status;
    private options;
    private videoMediatorStream;
    private writerPromise;
    constructor(destinationSource: string | Writable, options?: VideoOptions);
    private get videoFrameSize();
    private getFfmpegPath;
    private getDestinationPathExtension;
    private configureFFmPegPath;
    private isWritableStream;
    private configureVideoFile;
    private configureVideoWritableStream;
    private getDestinationStream;
    private handleWriteStreamError;
    private findSlot;
    insert(frame: pageScreenFrame): void;
    private trimFrame;
    private processFrameBeforeWrite;
    write(data: Buffer, durationSeconds?: number): void;
    private drainFrames;
    stop(stoppedTime?: number): Promise<boolean>;
}
