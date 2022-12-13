"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const puppeteer_1 = __importDefault(require("puppeteer"));
const PuppeteerScreenRecorder_1 = require("../lib/PuppeteerScreenRecorder");
/**
 * @ignore
 */
async function executeSample(format) {
    const browser = await puppeteer_1.default.launch();
    const page = await browser.newPage();
    const recorder = new PuppeteerScreenRecorder_1.PuppeteerScreenRecorder(page);
    await recorder.start(format);
    await page.goto('https://yahoo.com');
    await page.goto('https://google.com');
    await recorder.stop();
    await browser.close();
}
executeSample('./report/video/simple1.mp4');
executeSample('./report/video/simple1.mov');
executeSample('./report/video/simple1.avi');
executeSample('./report/video/simple1.webm');
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXguanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi9zcmMvZXhhbXBsZS9pbmRleC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOzs7OztBQUFBLDBEQUFrQztBQUVsQyw0RUFBeUU7QUFFekU7O0dBRUc7QUFDSCxLQUFLLFVBQVUsYUFBYSxDQUFDLE1BQU07SUFDakMsTUFBTSxPQUFPLEdBQUcsTUFBTSxtQkFBUyxDQUFDLE1BQU0sRUFBRSxDQUFDO0lBQ3pDLE1BQU0sSUFBSSxHQUFHLE1BQU0sT0FBTyxDQUFDLE9BQU8sRUFBRSxDQUFDO0lBQ3JDLE1BQU0sUUFBUSxHQUFHLElBQUksaURBQXVCLENBQUMsSUFBSSxDQUFDLENBQUM7SUFDbkQsTUFBTSxRQUFRLENBQUMsS0FBSyxDQUFDLE1BQU0sQ0FBQyxDQUFDO0lBQzdCLE1BQU0sSUFBSSxDQUFDLElBQUksQ0FBQyxtQkFBbUIsQ0FBQyxDQUFDO0lBRXJDLE1BQU0sSUFBSSxDQUFDLElBQUksQ0FBQyxvQkFBb0IsQ0FBQyxDQUFDO0lBQ3RDLE1BQU0sUUFBUSxDQUFDLElBQUksRUFBRSxDQUFDO0lBQ3RCLE1BQU0sT0FBTyxDQUFDLEtBQUssRUFBRSxDQUFDO0FBQ3hCLENBQUM7QUFFRCxhQUFhLENBQUMsNEJBQTRCLENBQUMsQ0FBQztBQUM1QyxhQUFhLENBQUMsNEJBQTRCLENBQUMsQ0FBQztBQUM1QyxhQUFhLENBQUMsNEJBQTRCLENBQUMsQ0FBQztBQUM1QyxhQUFhLENBQUMsNkJBQTZCLENBQUMsQ0FBQyJ9