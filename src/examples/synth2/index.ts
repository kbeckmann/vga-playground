import attenuation_v from './attenuation.v?raw';
import envelope_v from './envelope.v?raw';
import noise_v from './noise.v?raw';
import project_v from './project.v?raw';
import scale_rom_v from './scale_rom.v?raw';
import signal_edge_v from './signal_edge.v?raw';
import tone_v from './tone.v?raw';

export const synth2 = {
  name: 'Synth2',
  author: 'kbeckmann',
  topModule: 'tt_audio_example',
  sources: {
    'attenuation.v': attenuation_v,
    'envelope.v': envelope_v,
    'noise.v': noise_v,
    'project.v': project_v,
    'scale_rom.v': scale_rom_v,
    'signal_edge.v': signal_edge_v,
    'tone.v': tone_v,
  },
};
