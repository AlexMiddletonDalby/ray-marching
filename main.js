const canvasSketch = require("canvas-sketch");
const createShader = require("canvas-sketch-util/shader");
const Meyda = require("meyda");

let prevTime = 0;

class ValueSmoother {
  constructor(smoothing) {
    this.smoothing = smoothing;
    this.value = 0;
  }

  update(newValue) {
    this.value = this.smoothing * newValue + (1 - this.smoothing) * this.value;
    return this.value;
  }

  get() {
    return this.value;
  }
}

let rms = new ValueSmoother(0.08);

let lows = new ValueSmoother(0.5);
let mids = new ValueSmoother(0.2);
let highs = new ValueSmoother(0.1);

const sampleRate = 44100;

function average(arr) {
  if (arr.length === 0) return 0;
  const sum = arr.reduce((acc, val) => acc + val, 0);
  return sum / arr.length;
}

navigator.mediaDevices.getUserMedia({ audio: true }).then(function (stream) {
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  const source = audioContext.createMediaStreamSource(stream);

  const meyda = Meyda.createMeydaAnalyzer({
    audioContext: audioContext,
    source: source,
    bufferSize: 512,
    featureExtractors: ["rms", "powerSpectrum"],
    sampleRate: sampleRate,
    callback: (features) => {
      rms.update(features.rms);

      const spectrum = features.powerSpectrum;
      const spectrumLength = spectrum.length;
      const halfSampleRate = sampleRate / 2;
      const lowCutoff = 300;
      const midCutoff = 3000;

      const lowIndex = Math.floor(
        (lowCutoff / halfSampleRate) * spectrumLength
      );

      const midIndex = Math.floor(
        (midCutoff / halfSampleRate) * spectrumLength
      );

      lows.update(average(spectrum.slice(0, lowIndex)));
      mids.update(average(spectrum.slice(lowIndex, midIndex)));
      highs.update(average(spectrum.slice(midIndex, spectrumLength)));
    },
  });

  meyda.start();
});

const settings = {
  dimensions: [1024, 576],
  context: "webgl",
  animate: true,
};

const vert = require("./vert.glsl");
const frag = require("./frag.glsl");

const sketch = ({ gl }) => {
  return createShader({
    gl,
    frag,
    vert,
    uniforms: {
      time: ({ time }) => {
        return time;
      },
      audioRunningTime: ({ time }) => {
        if (rms.get() > 0.001) {
          prevTime = time;
          return prevTime;
        } else {
          return prevTime;
        }
      },
      resolution: ({ width, height }) => [width, height],
      rms: () => rms.get(),
      lows: () => lows.get(),
      mids: () => mids.get(),
      highs: () => highs.get(),
    },
  });
};

canvasSketch(sketch, settings);
