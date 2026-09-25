// Real browser playthroughs; run after build_web.sh with serve.py running.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {chromium} = require('playwright');
const url = process.env.GCOPY_URL || 'http://localhost:8000';
const output = 'screenshots/audit-web';
fs.mkdirSync(output, {recursive:true});

async function main() {
  const browser = await chromium.launch({headless:true});
  try {
    for (const config of [
      {name:'desktop', viewport:{width:1440,height:900}, deviceScaleFactor:1},
      {name:'mobile-landscape', viewport:{width:844,height:390}, deviceScaleFactor:2, isMobile:true, hasTouch:true},
      {name:'mobile-portrait', viewport:{width:390,height:844}, deviceScaleFactor:2, isMobile:true, hasTouch:true},
    ]) {
      const {name, ...options} = config;
      if (process.env.GCOPY_VIEWPORT && name !== process.env.GCOPY_VIEWPORT) continue;
      const context = await browser.newContext(options);
      const page = await context.newPage();
      const errors = [], dialogs = [];
      page.on('pageerror', error => errors.push(error.message));
      page.on('dialog', async dialog => {dialogs.push(dialog.message()); await dialog.dismiss();});
      async function shot(scene) { await page.screenshot({path:`${output}/${name}-${scene}.png`}); }
      async function ready() {
        await page.waitForFunction(() => document.querySelector('#statusText').textContent === 'ACTIVE');
        await page.waitForTimeout(600);
      }
      async function tap(x,y,panel=false) {
        const box = await page.locator('#canvas').boundingBox();
        const height = panel ? 544 : 406;
        const scale = Math.min(box.width/640,box.height/height);
        const point = {x:box.x+(box.width-640*scale)/2+(x-58)*scale,
          y:box.y+(box.height-height*scale)/2+(y-30)*scale};
        if (options.hasTouch) await page.touchscreen.tap(point.x,point.y);
        else await page.mouse.click(point.x,point.y);
        await page.waitForTimeout(150);
      }
      async function layout() {
        const data = await page.evaluate(() => {
          const canvas=document.querySelector('#canvas');
          return {box:canvas.getBoundingClientRect().toJSON(), width:innerWidth,height:innerHeight,
            scrollWidth:document.documentElement.scrollWidth,
            stageBottom:document.querySelector('.game-wrapper').getBoundingClientRect().bottom+scrollY,
            backing:[canvas.width,canvas.height],dpr:devicePixelRatio};
        });
        assert(data.box.x>=0 && data.box.y>=0 && data.box.right<=data.width+1 && data.box.bottom<=data.height+1, 'canvas fits viewport');
        // The about text below the game may scroll; the game itself must fill only the first screen.
        assert(data.scrollWidth<=data.width+1 && data.stageBottom<=data.height+1, 'game fits the first screen, no sideways scroll');
        assert(Math.abs(data.backing[0]-data.box.width*data.dpr)<2, 'backing pixels follow DPR');
        console.log(name, 'layout', data.backing, data.box.width, data.box.height);
      }
      try {
        await page.goto(url);
        await ready(); await layout(); await shot('market');
        await tap(186,502,true); await shot('market-page-2');
        await tap(99,502,true);
        await tap(220,298,true); await shot('info');
        await tap(520,500,true); // close info, return to desk
        await shot('desk');
        await tap(98,358); // COPY -> automatic V
        await tap(118,204); // start
        await shot('reading');
        for (let swap=1;swap<=3;swap++) {
          await page.waitForTimeout(5400);
          await shot(`swap-${swap}`);
          await tap(388,352);
        }
        await page.waitForTimeout(8500);
        await shot('verified');
        await tap(380,418); // deliver verified batch
        await page.waitForFunction(() => /(?:^|\n)completed=1\n/.test(localStorage.getItem('g-copy_business.dat')||''));
        const save=await page.evaluate(()=>localStorage.getItem('g-copy_business.dat'));
        assert.match(save, /(?:^|\n)money=100\n/);
        assert.match(save, /(?:^|\n)blanks=2\n/);
        await shot('delivered');
        await page.reload(); await ready();
        assert.equal(await page.evaluate(()=>localStorage.getItem('g-copy_business.dat')), save);
        await tap(375,418); await shot('reloaded-status');
        await page.keyboard.press('m');
        await page.waitForFunction(() => /(?:^|\n)music=0\n/.test(localStorage.getItem('g-copy_business.dat')||''));
        const resaved = await page.evaluate(()=>localStorage.getItem('g-copy_business.dat'));
        assert.match(resaved, /(?:^|\n)money=100\n/);
        assert.match(resaved, /(?:^|\n)completed=1\n/);
        if (name==='desktop') {
          await page.keyboard.press('Escape');
          await page.locator('.toolbar button').click();
          await page.waitForFunction(()=>!!document.fullscreenElement);
          await page.waitForTimeout(400); await layout(); await shot('fullscreen');
          await page.keyboard.press('F11');
          await page.waitForFunction(()=>!document.fullscreenElement);
          for (const viewport of [{width:2805,height:1854},{width:1024,height:768},{width:320,height:568}]) {
            await page.setViewportSize(viewport); await page.waitForTimeout(500); await layout();
            await shot(`resize-${viewport.width}`);
          }
        }
        assert.deepEqual(dialogs, [], 'no compatibility alert');
        assert.deepEqual(errors, [], 'no JavaScript errors');
        console.log(`PASS ${name}: full copy, three media swaps, auto verification, payment, persistence, layout`);
      } catch (error) {
        await shot('FAIL');
        console.error({name,errors,dialogs});
        throw error;
      } finally { await context.close(); }
    }
    const recovery = await browser.newContext();
    await recovery.addInitScript(() => {
      localStorage.setItem('g-copy_business.dat', 'version=2\nmoney=170\ncompleted=2\nowned_moon=1\nselected=moon\n');
      IDBFactory.prototype.open = function() { throw new Error('IndexedDB blocked for recovery test'); };
    });
    const page = await recovery.newPage();
    await page.goto(url);
    await page.waitForFunction(() => document.querySelector('#statusText').textContent === 'ACTIVE');
    await page.waitForTimeout(600);
    await page.keyboard.press('m');
    await page.waitForFunction(() => /(?:^|\n)music=0\n/.test(localStorage.getItem('g-copy_business.dat')||''));
    const recovered = await page.evaluate(()=>localStorage.getItem('g-copy_business.dat'));
    assert.match(recovered, /(?:^|\n)money=170\n/);
    assert.match(recovered, /(?:^|\n)completed=2\n/);
    await recovery.close();
    console.log('PASS boot and progress recovery when IndexedDB fails');
  } finally { await browser.close(); }
}
main().catch(error=>{console.error(error);process.exitCode=1;});
