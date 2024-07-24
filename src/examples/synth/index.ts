import project_v from './project.v?raw';

import blockram_v from './blockram.v?raw';
import divider_v from './divider.v?raw';
import fifo_4k_v from './fifo_4k.v?raw';
import mos6581_buffered_player_v from './mos6581_buffered_player.v?raw';
import mos6581_v from './mos6581.v?raw';
import voice_v from './voice.v?raw';

export const synth = {
  name: 'Synth',
  author: 'kbeckmann',
  topModule: 'tt_audio_example',
  sources: {
    'project.v': project_v,
    // 'blockram.v': blockram_v,
    // 'divider.v': divider_v,
    // 'fifo_4k.v': fifo_4k_v,
    // 'mos6581_buffered_player.v': mos6581_buffered_player_v,
    // 'mos6581.v': mos6581_v,
    'voice.v': voice_v,
  },
};
