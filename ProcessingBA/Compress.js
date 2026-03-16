import { spawnSync } from 'child_process';
import path from 'path';
import fs from 'fs';
import sharp from 'sharp';
import ffmpegPath from 'ffmpeg-static';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname  = path.dirname(__filename);

const FPS = 60;
const SECONDS = 127;
const WIDTH = 256;
const HEIGHT = 256;

const INPUT = path.join(__dirname, 'Media', 'BA.mp4');
const TMPDIR = path.join(__dirname, 'Media', 'tmp_frames');
const OUTFILE = path.join(__dirname, 'data', 'media.txt');


if (fs.existsSync(TMPDIR))
  fs.rmSync(TMPDIR, { recursive: true });

fs.mkdirSync(TMPDIR, { recursive: true });


console.log('Extracting frames…');

const pattern = path.join(TMPDIR, 'f_%04d.png');

spawnSync(
  ffmpegPath,
  [
    '-y',
    '-hide_banner',

    '-ss','0',
    '-t', String(SECONDS),

    '-i', INPUT,

    '-vf',
    [
      `scale=${WIDTH}:${HEIGHT}:flags=lanczos`,
      'format=gray',
      "lut=y='if(gte(val,128),255,0)'",
      `fps=${FPS}`
    ].join(','),

    pattern
  ],
  { stdio: 'inherit' }
);


function RLERows(Buffer, Width, Height, Channels)
{
  const Rectangles = [];

  function PixelIndex(X, Y)
  {
    return (Y * Width + X) * Channels;
  }

  for (let Y = 0; Y < Height; Y++)
  {
    let X = 0;

    while (X < Width)
    {
      const PixelValue = Buffer[PixelIndex(X, Y)];

      let RunLength = 1;

      while (
        X + RunLength < Width &&
        Buffer[PixelIndex(X + RunLength, Y)] === PixelValue
      )
      {
        RunLength++;
      }

      if (PixelValue === 255)
      {
        Rectangles.push({
          x: X,
          y: Y,
          w: RunLength,
          h: 1
        });
      }

      X += RunLength;
    }
  }

  return Rectangles;
}


function encodeRect(r)
{
  const buf = Buffer.alloc(8);

  buf.writeUInt16BE(r.x, 0);
  buf.writeUInt16BE(r.y, 2);
  buf.writeUInt16BE(r.w, 4);
  buf.writeUInt16BE(r.h, 6);

  return buf.toString('base64');
}


console.log('Compressing frames…');

const files = fs
  .readdirSync(TMPDIR)
  .filter(f => f.endsWith('.png'))
  .sort();

const FrameStrings = [];

for (const fname of files)
{
  const PNGPath = path.join(TMPDIR, fname);

  const { data, info } = await sharp(PNGPath)
    .raw()
    .toBuffer({ resolveWithObject: true });

  const rects = RLERows(data, info.width, info.height, info.channels);

  const encodedRects = rects
    .map(encodeRect)
    .join(',');

  FrameStrings.push(encodedRects);

  fs.unlinkSync(PNGPath);
}


fs.rmSync(TMPDIR, { recursive: true });


const finalString = FrameStrings.join('|');

const header = `${WIDTH},${HEIGHT},${FPS}\n`;

fs.writeFileSync(
  OUTFILE,
  header + finalString
);

console.log('done');