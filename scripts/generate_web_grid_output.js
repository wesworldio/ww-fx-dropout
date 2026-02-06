const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const FILTERS = [
  'bulge_eyes',
  'funhouse_mirror',
  'funny_squash',
  'pinch_cheeks',
  'pincushion',
  'radial_wobble',
  'ultimate_distortion',
  'water_ripple',
  'wobble_face',
  'complex_ripple',
  'complex_ripple_v1',
  'elastic_face',
  'elastic_stretch',
  'elastic_stretch_v1',
  'funny_stretch',
  'funny_stretch_v1',
  'gentle_ripple',
  'lens_distortion',
  'lens_distortion_v1',
  'multi_ripple',
  'multi_ripple_v1',
  'radial_squeeze',
  'radial_squeeze_v1',
  'smush_face',
  'squeeze_horizontal',
  'squeeze_horizontal_v1',
  'squeeze_vertical',
  'squeeze_vertical_v1',
  'squish_face',
  'squish_face_v1',
  'stretch_face',
  'stretch_face_v1',
  'upside_down',
  'upside_down_v1',
  'warp_face',
  'warp_face_v1',
  'wave_distortion',
  'wave_distortion_v1'
];

const OUTPUT_DIR = path.resolve(__dirname, '..', 'web-filter-grid-test-output');
const HTML_PATH = path.resolve(__dirname, '..', 'web-grid-generator.html');
const FILE_URL = `file://${HTML_PATH}`;

async function ensureDir(dir) {
  await fs.promises.mkdir(dir, { recursive: true });
}

async function writeDataUrlToFile(dataUrl, filePath) {
  const base64 = dataUrl.replace(/^data:image\/png;base64,/, '');
  await fs.promises.writeFile(filePath, base64, 'base64');
}

async function run() {
  await ensureDir(OUTPUT_DIR);

  const browser = await puppeteer.launch({
    headless: 'new'
  });

  try {
    const page = await browser.newPage();
    await page.goto(FILE_URL, { waitUntil: 'load' });

    for (const filter of FILTERS) {
      const dataUrl = await page.evaluate((filterName) => {
        return window.generateGridImage(filterName, 1280, 720);
      }, filter);

      const outPath = path.join(OUTPUT_DIR, `${filter}.png`);
      await writeDataUrlToFile(dataUrl, outPath);
      process.stdout.write(`Generated ${filter}\n`);
    }
  } finally {
    await browser.close();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
