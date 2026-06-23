import { beforeEach, describe, expect, it } from 'vitest';

import {
  DEFAULT_SUBTITLE_PREFERENCES,
  getSubtitlePreferenceStyle,
  loadSubtitlePreferences,
  saveSubtitlePreferences,
} from './subtitle-preferences';

describe('subtitle preferences', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('loads defaults when no preference is stored', () => {
    expect(loadSubtitlePreferences()).toEqual(DEFAULT_SUBTITLE_PREFERENCES);
  });

  it('persists normalized subtitle preferences', () => {
    saveSubtitlePreferences({
      size: 'large',
      color: 'yellow',
      backgroundOpacity: 110,
      position: 'high',
    });

    expect(loadSubtitlePreferences()).toEqual({
      size: 'large',
      color: 'yellow',
      backgroundOpacity: 100,
      position: 'high',
    });
  });

  it('maps preferences to caption CSS variables', () => {
    expect(getSubtitlePreferenceStyle({
      size: 'xlarge',
      color: 'cyan',
      backgroundOpacity: 25,
      position: 'medium',
    })).toMatchObject({
      '--moonlit-subtitle-font-size': '38px',
      '--moonlit-subtitle-color': '#a5f3fc',
      '--moonlit-subtitle-bg': 'rgba(0, 0, 0, 0.25)',
      '--moonlit-subtitle-bottom': '168px',
    });
  });
});
