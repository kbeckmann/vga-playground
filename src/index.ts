import * as monaco from 'monaco-editor';
import { FPSCounter } from './FPSCounter';
import { examples } from './examples';
import { exportProject } from './exportProject';
import { HDLModuleWASM } from './sim/hdlwasm';
import { compileVerilator } from './verilator/compile';


let currentProject = null;

const hash = window.location.href.split('#')[1];

if (hash) {
  const jsonData = JSON.parse(atob(hash));
  currentProject = jsonData;
} else {
  // Load default project
  currentProject = structuredClone(examples[0]);
}

const inputButtons = Array.from(document.querySelectorAll('#input-values button'));

const codeEditorDiv = document.getElementById('code-editor');
const editor = monaco.editor.create(codeEditorDiv!, {
  value: currentProject.sources['project.v'],
  language: 'systemverilog',
  scrollBeyondLastLine: false,
  minimap: {
    enabled: false,
  },
});

const res = await compileVerilator({
  topModule: currentProject.topModule,
  sources: currentProject.sources,
});
if (!res.output) {
  console.log(res.errors);
  throw new Error('Compile error');
}

let jmod = new HDLModuleWASM(res.output.modules['TOP'], res.output.modules['@CONST-POOL@']);
//let jmod = new HDLModuleJS(res.output.modules['TOP'], res.output.modules['@CONST-POOL@']);
await jmod.init();

function reset() {
  const ui_in = jmod.state.ui_in;
  jmod.powercycle();
  jmod.state.ena = 1;
  jmod.state.rst_n = 0;
  jmod.state.ui_in = ui_in;
  jmod.tick2(10);
  jmod.state.rst_n = 1;
}
reset();

function getVGASignals() {
  const uo_out = jmod.state.uo_out as number;
  return {
    hsync: !!(uo_out & 0b10000000),
    vsync: !!(uo_out & 0b00001000),
    r: ((uo_out & 0b00000001) << 1) | ((uo_out & 0b00010000) >> 4),
    g: ((uo_out & 0b00000010) << 0) | ((uo_out & 0b00100000) >> 5),
    b: ((uo_out & 0b00000100) >> 1) | ((uo_out & 0b01000000) >> 6),
  };
}

let stopped = false;
const fpsCounter = new FPSCounter();

editor.onDidChangeModelContent(async () => {
  stopped = true;
  currentProject.sources = {
    ...currentProject.sources,
    'project.v': editor.getValue(),
  };
  const res = await compileVerilator({
    topModule: currentProject.topModule,
    sources: currentProject.sources,
  });
  monaco.editor.setModelMarkers(
    editor.getModel()!,
    'error',
    res.errors.map((e) => ({
      startLineNumber: e.line,
      endLineNumber: e.line,
      startColumn: e.column,
      endColumn: e.endColumn ?? 999,
      message: e.message,
      severity: e.type === 'error' ? monaco.MarkerSeverity.Error : monaco.MarkerSeverity.Warning,
    }))
  );
  if (!res.output) {
    return;
  }
  if (jmod) {
    jmod.dispose();
  }
  inputButtons.map((b) => b.classList.remove('active'));
  jmod = new HDLModuleWASM(res.output.modules['TOP'], res.output.modules['@CONST-POOL@']);
  await jmod.init();
  reset();
  fpsCounter.reset();
  stopped = false;
});

const canvas = document.querySelector<HTMLCanvasElement>('#vga-canvas');
const ctx = canvas?.getContext('2d');
const imageData = ctx?.createImageData(736, 520);
const fpsDisplay = document.querySelector('#fps-count');

function waitFor(condition: () => boolean, timeout = 10000) {
  let counter = 0;
  while (!condition() && counter < timeout) {
    jmod.tick2(1);
    counter++;
  }
}
const audioContext = new (window.AudioContext || window.webkitAudioContext)();
let isPlaying = false;

// Create small buffers with sine wave data
function createBuffer(frequency, duration) {
    const buffer = audioContext.createBuffer(1, audioContext.sampleRate * duration, audioContext.sampleRate);
    const data = buffer.getChannelData(0);
    const phaseIncrement = 2 * Math.PI * frequency / audioContext.sampleRate;
    let phase = 0;

    for (let i = 0; i < data.length; i++) {
        data[i] = Math.sin(phase);
        phase += phaseIncrement;
        if (phase >= 2 * Math.PI) phase -= 2 * Math.PI;
    }

    return buffer;
}

const buffer1 = createBuffer(440, 0.2); // 440 Hz, 2 seconds
const buffer2 = createBuffer(660, 0.2); // 660 Hz, 2 seconds

// Play a buffer and queue the next one
function playBuffer(buffer) {
  const source = audioContext.createBufferSource();
  source.buffer = buffer;
  source.connect(audioContext.destination);
  source.start();

  let nextBuffer = buffer == buffer1 ? buffer2 : buffer1;
  source.onended = () => {
    playBuffer(nextBuffer);
  };

  const data = buffer.getChannelData(0);


  // Prepare next buffer
  const freq = 25e6; // 25.000 MHz
  const samprate = 48000;
  const cycles = freq / samprate; // cycles to step between fetching a sample

  for (var i = 0; i < data.length; i++) {
    // jmod.tick2(1);
    jmod.tick2(cycles);
    // console.log(cycles);
    data[i] = (jmod.state.audio_out - 32768.0) / 32768.0;

    // const t = i / samprate;
    // const phase = 2 * Math.PI * 1000 * t;
    // data[i] = Math.sin(phase);
  }
}

function startAudio() {
  if (isPlaying) return;

  // Create buffers with different frequencies

  // Chain the buffers to play one after the other
  playBuffer(buffer1, { buffer: buffer2, next: null });

  isPlaying = true;
}

function setupAudio() {
  startAudio();
  console.log("Audio started");
}

function animationFrame(now: number) {
  requestAnimationFrame(animationFrame);

  fpsCounter.update(now);

  if (fpsDisplay) {
    fpsDisplay.textContent = `${fpsCounter.getFPS().toFixed(0)}`;
  }

  if (stopped || !imageData || !ctx) {
    return;
  }

  // Check if audio - switch to audio only in such case
  const audio_out = jmod.state.audio_out as number;
  if (audio_out !== undefined) {

    // if (!audioIsSetup) {
      return;
    // }


    return;
  }


  const data = new Uint8Array(imageData.data.buffer);
  frameLoop: for (let y = 0; y < 520; y++) {
    waitFor(() => !getVGASignals().hsync);
    for (let x = 0; x < 736; x++) {
      const offset = (y * 736 + x) * 4;
      jmod.tick2(1);
      const { hsync, vsync, r, g, b } = getVGASignals();
      if (hsync) {
        break;
      }
      if (vsync) {
        break frameLoop;
      }
      data[offset] = r << 6;
      data[offset + 1] = g << 6;
      data[offset + 2] = b << 6;
      data[offset + 3] = 0xff;
    }
    waitFor(() => getVGASignals().hsync);
  }
  ctx!.putImageData(imageData, 0, 0);
  waitFor(() => getVGASignals().vsync);
  waitFor(() => !getVGASignals().vsync);
}

requestAnimationFrame(animationFrame);

const buttons = document.querySelector('#preset-buttons');
for (const example of examples) {
  const button = document.createElement('button');
  button.textContent = example.name;
  button.addEventListener('click', async () => {
    currentProject = structuredClone(example);
    editor.setValue(currentProject.sources['project.v']);
  });
  buttons?.appendChild(button);
}

window.addEventListener('resize', () => {
  editor.layout();
});

window.addEventListener('visibilitychange', () => {
  const now = performance.now();
  if (document.hidden) {
    fpsCounter.pause(now);
  } else {
    fpsCounter.resume(now);
  }
});

document.querySelector('#download-button')?.addEventListener('click', () => {
  exportProject(currentProject);
});

document.querySelector('#share-button')?.addEventListener('click', () => {
  const url = new URL(window.location.href);
  const urlWithoutHash = url.protocol + "//" + url.host + url.pathname + url.search;

  const newUrl = urlWithoutHash + '#' + btoa(JSON.stringify(currentProject));
  navigator.clipboard.writeText(newUrl);
});

document.querySelector('#audio-button')?.addEventListener('click', () => {
  setupAudio();
});



function toggleButton(index: number) {
  const bit = 1 << index;
  jmod.state.ui_in = jmod.state.ui_in ^ bit;
  if (jmod.state.ui_in & bit) {
    inputButtons[index].classList.add('active');
  } else {
    inputButtons[index].classList.remove('active');
  }
}

document.addEventListener('keydown', (e) => {
  if ('r' === e.key) {
    reset();
  }
  if (['0', '1', '2', '3', '4', '5', '6', '7'].includes(e.key)) {
    toggleButton(parseInt(e.key, 10));
  }
});

inputButtons.forEach((button, index) => {
  button.addEventListener('click', () => toggleButton(index));
});
