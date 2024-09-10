const canvasSketch = require("canvas-sketch");
const createShader = require("canvas-sketch-util/shader");

// Setup our sketch
const settings = {
  dimensions: [512, 512],
  context: "webgl",
  animate: true,
};

// Your glsl code
const vert = require("./vert.glsl");
const frag = require("./frag.glsl");

const sketch = ({ gl }) => {
  // Create the shader and return it. It will be rendered by regl.
  return createShader({
    gl,
    frag,
    vert,
    uniforms: {
      time: ({ time }) => time,
    },
  });
};

canvasSketch(sketch, settings);
