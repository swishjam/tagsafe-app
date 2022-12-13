import puppeteer from 'puppeteer';
import { PuppeteerScreenRecorder } from '../lib/PuppeteerScreenRecorder';
/**
 * @ignore
 */
async function executeSample(format) {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    const recorder = new PuppeteerScreenRecorder(page);
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
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXguanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi8uLi8uLi9zcmMvZXhhbXBsZS9pbmRleC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQSxPQUFPLFNBQVMsTUFBTSxXQUFXLENBQUM7QUFFbEMsT0FBTyxFQUFFLHVCQUF1QixFQUFFLE1BQU0sZ0NBQWdDLENBQUM7QUFFekU7O0dBRUc7QUFDSCxLQUFLLFVBQVUsYUFBYSxDQUFDLE1BQU07SUFDakMsTUFBTSxPQUFPLEdBQUcsTUFBTSxTQUFTLENBQUMsTUFBTSxFQUFFLENBQUM7SUFDekMsTUFBTSxJQUFJLEdBQUcsTUFBTSxPQUFPLENBQUMsT0FBTyxFQUFFLENBQUM7SUFDckMsTUFBTSxRQUFRLEdBQUcsSUFBSSx1QkFBdUIsQ0FBQyxJQUFJLENBQUMsQ0FBQztJQUNuRCxNQUFNLFFBQVEsQ0FBQyxLQUFLLENBQUMsTUFBTSxDQUFDLENBQUM7SUFDN0IsTUFBTSxJQUFJLENBQUMsSUFBSSxDQUFDLG1CQUFtQixDQUFDLENBQUM7SUFFckMsTUFBTSxJQUFJLENBQUMsSUFBSSxDQUFDLG9CQUFvQixDQUFDLENBQUM7SUFDdEMsTUFBTSxRQUFRLENBQUMsSUFBSSxFQUFFLENBQUM7SUFDdEIsTUFBTSxPQUFPLENBQUMsS0FBSyxFQUFFLENBQUM7QUFDeEIsQ0FBQztBQUVELGFBQWEsQ0FBQyw0QkFBNEIsQ0FBQyxDQUFDO0FBQzVDLGFBQWEsQ0FBQyw0QkFBNEIsQ0FBQyxDQUFDO0FBQzVDLGFBQWEsQ0FBQyw0QkFBNEIsQ0FBQyxDQUFDO0FBQzVDLGFBQWEsQ0FBQyw2QkFBNkIsQ0FBQyxDQUFDIn0=