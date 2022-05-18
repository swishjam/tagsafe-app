"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pageVideoStreamCollector = void 0;
const events_1 = require("events");
/**
 * @ignore
 */
class pageVideoStreamCollector extends events_1.EventEmitter {
    constructor(page, options) {
        super();
        this.sessionsStack = [];
        this.isStreamingEnded = false;
        this.page = page;
        this.options = options;
    }
    get shouldFollowPopupWindow() {
        return this.options.followNewTab;
    }
    async getPageSession(page) {
        try {
            const context = page.target();
            return await context.createCDPSession();
        }
        catch (error) {
            console.log('Failed to create CDP Session', error);
            return null;
        }
    }
    getCurrentSession() {
        return this.sessionsStack[this.sessionsStack.length - 1];
    }
    addListenerOnTabOpens(page) {
        page.on('popup', () => this.registerTabListener(page));
    }
    removeListenerOnTabClose(page) {
        page.off('popup', () => this.registerTabListener(page));
    }
    async registerTabListener(newPage) {
        await this.startSession(newPage);
        newPage.once('close', async () => await this.endSession());
    }
    async startScreenCast(shouldDeleteSessionOnFailure = false) {
        const currentSession = this.getCurrentSession();
        try {
            await currentSession.send('Page.startScreencast', {
                everyNthFrame: 1,
            });
        }
        catch (e) {
            if (shouldDeleteSessionOnFailure) {
                this.endSession();
            }
        }
    }
    async stopScreenCast() {
        const currentSession = this.getCurrentSession();
        if (!currentSession) {
            return;
        }
        await currentSession.send('Page.stopScreencast');
    }
    async startSession(page) {
        const pageSession = await this.getPageSession(page);
        if (!pageSession) {
            return;
        }
        await this.stopScreenCast();
        this.sessionsStack.push(pageSession);
        this.handleScreenCastFrame(pageSession);
        await this.startScreenCast(true);
    }
    async handleScreenCastFrame(session) {
        this.isFrameAckReceived = new Promise((resolve) => {
            session.on('Page.screencastFrame', async ({ metadata, data, sessionId }) => {
                if (!metadata.timestamp || this.isStreamingEnded) {
                    return resolve();
                }
                const ackPromise = session.send('Page.screencastFrameAck', {
                    sessionId: sessionId,
                });
                this.emit('pageScreenFrame', {
                    blob: Buffer.from(data, 'base64'),
                    timestamp: metadata.timestamp,
                });
                try {
                    await ackPromise;
                }
                catch (error) {
                    console.error('Error in sending Acknowledgment for PageScreenCast', error.message);
                }
            });
        });
    }
    async endSession() {
        this.sessionsStack.pop();
        await this.startScreenCast();
    }
    async start() {
        await this.startSession(this.page);
        if (this.shouldFollowPopupWindow) {
            this.addListenerOnTabOpens(this.page);
        }
    }
    async stop() {
        if (this.isStreamingEnded) {
            return this.isStreamingEnded;
        }
        if (this.shouldFollowPopupWindow) {
            this.removeListenerOnTabClose(this.page);
        }
        await Promise.race([
            this.isFrameAckReceived,
            new Promise((resolve) => setTimeout(resolve, 1000)),
        ]);
        this.isStreamingEnded = true;
        try {
            for (const currentSession of this.sessionsStack) {
                await currentSession.detach();
            }
        }
        catch (e) {
            console.warn('Error detaching session', e.message);
        }
        return true;
    }
}
exports.pageVideoStreamCollector = pageVideoStreamCollector;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicGFnZVZpZGVvU3RyZWFtQ29sbGVjdG9yLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vc3JjL2xpYi9wYWdlVmlkZW9TdHJlYW1Db2xsZWN0b3IudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6Ijs7O0FBQUEsbUNBQXNDO0FBTXRDOztHQUVHO0FBQ0gsTUFBYSx3QkFBeUIsU0FBUSxxQkFBWTtJQVF4RCxZQUFZLElBQVUsRUFBRSxPQUF1QztRQUM3RCxLQUFLLEVBQUUsQ0FBQztRQU5GLGtCQUFhLEdBQWtCLEVBQUUsQ0FBQztRQUNsQyxxQkFBZ0IsR0FBRyxLQUFLLENBQUM7UUFNL0IsSUFBSSxDQUFDLElBQUksR0FBRyxJQUFJLENBQUM7UUFDakIsSUFBSSxDQUFDLE9BQU8sR0FBRyxPQUFPLENBQUM7SUFDekIsQ0FBQztJQUVELElBQVksdUJBQXVCO1FBQ2pDLE9BQU8sSUFBSSxDQUFDLE9BQU8sQ0FBQyxZQUFZLENBQUM7SUFDbkMsQ0FBQztJQUVPLEtBQUssQ0FBQyxjQUFjLENBQUMsSUFBVTtRQUNyQyxJQUFJO1lBQ0YsTUFBTSxPQUFPLEdBQUcsSUFBSSxDQUFDLE1BQU0sRUFBRSxDQUFDO1lBQzlCLE9BQU8sTUFBTSxPQUFPLENBQUMsZ0JBQWdCLEVBQUUsQ0FBQztTQUN6QztRQUFDLE9BQU8sS0FBSyxFQUFFO1lBQ2QsT0FBTyxDQUFDLEdBQUcsQ0FBQyw4QkFBOEIsRUFBRSxLQUFLLENBQUMsQ0FBQztZQUNuRCxPQUFPLElBQUksQ0FBQztTQUNiO0lBQ0gsQ0FBQztJQUVPLGlCQUFpQjtRQUN2QixPQUFPLElBQUksQ0FBQyxhQUFhLENBQUMsSUFBSSxDQUFDLGFBQWEsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUM7SUFDM0QsQ0FBQztJQUVPLHFCQUFxQixDQUFDLElBQVU7UUFDdEMsSUFBSSxDQUFDLEVBQUUsQ0FBQyxPQUFPLEVBQUUsR0FBRyxFQUFFLENBQUMsSUFBSSxDQUFDLG1CQUFtQixDQUFDLElBQUks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