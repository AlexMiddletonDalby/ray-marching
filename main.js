const canvasSketch = require("canvas-sketch");
const createShader = require("canvas-sketch-util/shader");

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
      time: ({ time }) => time,
      resolution: ({ width, height }) => [width, height],
    },
  });
};

canvasSketch(sketch, settings);
