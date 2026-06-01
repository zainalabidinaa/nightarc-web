'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import {
  MediaPlayer, MediaProvider, Track,
  PlayButton, MuteButton, FullscreenButton, SeekButton, CaptionButton,
  TimeSlider, Captions,
  Time, Gesture, useMediaState,
  isHLSProvider,
  type MediaPlayerInstance, type MediaProviderAdapter,
} from '@vidstack/react';
import '@vidstack/react/player/styles/base.css';
import { SFSymbol } from '@/components/SFSymbol';
import { StreamItem } from '@/lib/types';
import { SubtitleItem } from '@/lib/stremio';
import { updateWatchProgress } from '@/lib/services/api';
import { useAuth } from '@/app/AuthProvider';

interface PlayerProps {
  streamUrl: string;
  streams: StreamItem[];
  currentStream: StreamItem;
  title: string;
  poster?: string;
  mediaId: string;
  mediaType: string;
  startPosition?: number;
  subtitles?: SubtitleItem[];
  onSwitchStream: (stream: StreamItem) => void;
  onBack: () => void;
}

function parseQuality(s: StreamItem): { label: string; color: string } {
  const t = `${s.name ?? ''} ${s.title ?? ''} ${s.description ?? ''}`.toLowerCase();
  if (t.includes('2160') || t.includes('4k') || t.includes('uhd')) return { label: '4K', color: 'text-yellow-400 bg-yellow-400/10' };
  if (t.includes('1080')) return { label: '1080p', color: 'text-blue-400 bg-blue-400/10' };
  if (t.includes('720')) return { label: '720p', color: 'text-slate-400 bg-slate-400/10' };
  return { label: 'SD', color: 'text-slate-500 bg-slate-500/10' };
}

const BAD_AUDIO_CODECS = ['dts', 'truehd', 'atmos', 'remux', 'blu-ray', 'bluray'];
function isWebCompatAudio(s: StreamItem): boolean {
  const t = `${s.name ?? ''} ${s.title ?? ''} ${s.description ?? ''}`.toLowerCase();
  return !BAD_AUDIO_CODECS.some(k => t.includes(k));
}

// Inner component — must be inside <MediaPlayer> to call useMediaState
function PlayerUI({
  title, currentStream, streams, subtitles,
  startPosition, mediaId, mediaType,
  onBack, onSwitchStream, playerRef,
}: {
  title: string;
  currentStream: StreamItem;
  streams: StreamItem[];
  subtitles: SubtitleItem[];
  startPosition?: number;
  mediaId: string;
  mediaType: string;
  onBack: () => void;
  onSwitchStream: (s: StreamItem) => void;
  playerRef: React.RefObject<MediaPlayerInstance>;
}) {
  const paused = useMediaState('paused');
  const waiting = useMediaState('waiting');
  const muted = useMediaState('muted');
  const volume = useMediaState('volume');
  const fullscreen = useMediaState('fullscreen');
  const canPlay = useMediaState('canPlay');

  const [showControls, setShowControls] = useState(true);
  const [showSources, setShowSources] = useState(false);
  const [showSpeed, setShowSpeed] = useState(false);
  const hideTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const speeds = [0.5, 0.75, 1, 1.25, 1.5, 2];

  // Auto-hide controls
  const resetHide = useCallback(() => {
    setShowControls(true);
    if (hideTimer.current) clearTimeout(hideTimer.current);
    if (!paused) {
      hideTimer.current = setTimeout(() => {
        if (!showSources && !showSpeed) setShowControls(false);
      }, 3500);
    }
  }, [paused, showSources, showSpeed]);

  useEffect(() => {
    if (paused) { setShowControls(true); if (hideTimer.current) clearTimeout(hideTimer.current); }
    else resetHide();
  }, [paused, resetHide]);

  useEffect(() => () => { if (hideTimer.current) clearTimeout(hideTimer.current); }, []);

  const muteIcon = muted || volume === 0
    ? 'speaker.slash.fill'
    : volume < 0.5 ? 'speaker.1.fill' : 'speaker.3';

  return (
    <>
      {/* Subtitle overlay */}
      <Captions className="vds-captions" />

      {/* Buffering */}
      {waiting && !canPlay && (
        <div className="absolute inset-0 flex items-center justify-center z-20 pointer-events-none">
          <div className="w-12 h-12 rounded-full border-2 border-white/20 border-t-white animate-spin" />
        </div>
      )}

      {/* Controls overlay */}
      <div
        className={`absolute inset-0 z-10 flex flex-col justify-between transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
        onMouseMove={resetHide}
        onMouseLeave={() => { if (!paused) setShowControls(false); }}
      >
        {/* TOP BAR */}
        <div className="px-8 pt-6" style={{ background: 'linear-gradient(to bottom, rgba(0,0,0,0.78) 0%, transparent 100%)' }}>
          <div className="flex items-center justify-between">
            <button
              onClick={onBack}
              className="flex items-center gap-2 text-white/85 hover:text-white text-base font-medium transition-colors"
            >
              <SFSymbol name="chevron.left" size={18} opacity={0.85} />
              Back
            </button>

            <p className="text-base font-semibold text-white/75 truncate max-w-[40%]">{title}</p>

            <button
              onClick={() => setShowSources(true)}
              className="flex items-center gap-2 bg-white/10 hover:bg-white/15 border border-white/10 rounded-xl px-3.5 py-2 transition-colors"
            >
              {!isWebCompatAudio(currentStream) && <span className="text-xs font-bold text-yellow-400">⚠</span>}
              <span className="text-sm font-medium text-white/65">{currentStream.addonName || 'Source'}</span>
            </button>
          </div>
        </div>

        {/* CENTER — skip + play */}
        <div className="flex items-center justify-center gap-16">
          <SeekButton seconds={-15} className="opacity-80 hover:opacity-100 transition-opacity active:scale-95">
            <SFSymbol name="gobackward.15" size={52} />
          </SeekButton>

          <PlayButton className="flex items-center justify-center hover:scale-105 active:scale-95 transition-transform">
            {paused
              ? <SFSymbol name="play.fill" size={72} />
              : <SFSymbol name="pause.fill" size={72} />}
          </PlayButton>

          <SeekButton seconds={15} className="opacity-80 hover:opacity-100 transition-opacity active:scale-95">
            <SFSymbol name="goforward.15" size={52} />
          </SeekButton>
        </div>

        {/* BOTTOM SHELF */}
        <div className="px-8 pb-8" style={{ background: 'linear-gradient(to top, rgba(0,0,0,0.85) 0%, transparent 100%)' }}>
          <p className="text-base font-bold text-white mb-4">{title}</p>

          {/* Scrubber */}
          <TimeSlider.Root className="group relative flex w-full items-center h-5 cursor-pointer mb-3">
            <TimeSlider.Track className="relative h-1 w-full rounded-full bg-white/20 group-hover:h-[5px] transition-all duration-150">
              <TimeSlider.TrackFill className="absolute h-full rounded-full bg-white" style={{ width: 'var(--slider-fill, 0%)' }} />
              <TimeSlider.Progress className="absolute h-full rounded-full bg-white/30" style={{ width: 'var(--slider-progress, 0%)' }} />
            </TimeSlider.Track>
            <TimeSlider.Thumb className="absolute top-1/2 -translate-y-1/2 w-4 h-4 rounded-full bg-white shadow-lg opacity-0 group-hover:opacity-100 transition-opacity -translate-x-1/2" style={{ left: 'var(--slider-fill, 0%)' }} />
            <TimeSlider.Preview className="absolute bottom-full -translate-x-1/2 mb-2 pointer-events-none">
              <TimeSlider.Value className="text-sm text-white bg-black/85 px-2 py-1 rounded-lg font-semibold whitespace-nowrap" type="pointer" format="time" />
            </TimeSlider.Preview>
          </TimeSlider.Root>

          {/* Time + buttons row */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5 text-sm font-medium text-white/50 tabular-nums">
              <Time type="current" />
              <span className="text-white/25">·</span>
              <Time type="duration" />
            </div>

            <div className="flex items-center gap-1">
              <MuteButton className="w-11 h-11 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95">
                <SFSymbol name={muteIcon} size={22} opacity={0.75} />
              </MuteButton>

              <CaptionButton className="w-11 h-11 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95">
                <SFSymbol name="captions.bubble.fill" size={22} opacity={0.75} />
              </CaptionButton>

              {/* Speed */}
              <div className="relative">
                <button
                  onClick={() => setShowSpeed(p => !p)}
                  className="w-11 h-11 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors text-sm font-bold text-white/55 hover:text-white/90"
                >
                  1×
                </button>
                {showSpeed && (
                  <div className="absolute bottom-full right-0 mb-3 bg-[#141414] border border-white/10 rounded-2xl p-1.5 min-w-[130px] z-30 shadow-xl">
                    {speeds.map(s => (
                      <button
                        key={s}
                        onClick={() => { if (playerRef.current) playerRef.current.playbackRate = s; setShowSpeed(false); }}
                        className="w-full text-left px-4 py-2.5 rounded-xl text-sm text-white/65 hover:bg-white/10 hover:text-white transition-colors font-medium"
                      >
                        {s === 1 ? 'Normal' : `${s}×`}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <FullscreenButton className="w-11 h-11 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95">
                {fullscreen
                  ? <SFSymbol name="arrow.down.right.and.arrow.up.left" size={20} opacity={0.75} />
                  : <SFSymbol name="arrow.up.left.and.arrow.down.right" size={20} opacity={0.75} />}
              </FullscreenButton>
            </div>
          </div>
        </div>
      </div>

      {/* SOURCES PANEL */}
      {showSources && (
        <div className="absolute inset-0 z-40 flex justify-end">
          <div className="absolute inset-0 bg-black/60" onClick={() => setShowSources(false)} />
          <div className="relative w-80 max-w-[85vw] h-full bg-neutral-950 border-l border-white/10 overflow-y-auto">
            <div className="p-4 border-b border-white/10 flex items-center justify-between sticky top-0 bg-neutral-950 z-10">
              <h3 className="text-sm font-semibold text-white">Sources</h3>
              <button onClick={() => setShowSources(false)} className="p-1 rounded-full hover:bg-white/10">
                <SFSymbol name="xmark" size={14} opacity={0.5} />
              </button>
            </div>
            {(() => {
              const compatible = streams.filter(isWebCompatAudio);
              if (compatible.length === 0) return (
                <div className="px-4 py-8 text-center">
                  <p className="text-white/40 text-sm">No web-compatible streams</p>
                  <p className="text-white/25 text-xs mt-1">All streams have DTS/TrueHD audio</p>
                </div>
              );
              const grp: Record<string, StreamItem[]> = {};
              for (const s of compatible) { const k = s.addonName || 'Unknown'; (grp[k] ??= []).push(s); }
              return Object.entries(grp).map(([name, items]) => (
                <div key={name} className="border-b border-white/5 last:border-b-0">
                  <div className="px-4 pt-3 pb-1">
                    <p className="text-[10px] font-semibold text-white/25 uppercase tracking-wider">{name}</p>
                  </div>
                  {items.map((s, i) => {
                    const isActive = s.url === currentStream.url;
                    const q = parseQuality(s);
                    const info = s.description?.replace(/\[.*?\]/g, '').trim() || s.title || s.name || 'Unknown';
                    return (
                      <button
                        key={s.url || `${name}-${i}`}
                        onClick={() => { setShowSources(false); onSwitchStream(s); }}
                        className={`w-full text-left px-4 py-3 hover:bg-white/5 flex items-center gap-3 transition-colors ${isActive ? 'border-l-2 border-white bg-white/5' : ''}`}
                      >
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded flex-shrink-0 ${q.color}`}>{q.label}</span>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm text-white/85 truncate">{info}</p>
                          {s.description && <p className="text-xs text-white/30 mt-0.5 truncate">{s.description}</p>}
                        </div>
                        {isActive && <div className="w-1.5 h-1.5 rounded-full bg-white flex-shrink-0" />}
                      </button>
                    );
                  })}
                </div>
              ));
            })()}
          </div>
        </div>
      )}
    </>
  );
}

export default function Player({
  streamUrl, streams, currentStream, title,
  mediaId, mediaType, startPosition, subtitles = [],
  onSwitchStream, onBack,
}: PlayerProps) {
  const playerRef = useRef<MediaPlayerInstance>(null);
  const { currentProfile } = useAuth();

  const onProviderChange = useCallback((provider: MediaProviderAdapter | null) => {
    if (isHLSProvider(provider)) {
      const headers = currentStream.behaviorHints?.proxyHeaders?.request;
      provider.config = {
        renderTextTracksNatively: false,
        startLevel: -1,
        ...(headers && {
          xhrSetup: (xhr: XMLHttpRequest) => {
            for (const [k, v] of Object.entries(headers)) xhr.setRequestHeader(k, v);
          },
        }),
      };
    }
  }, [currentStream]);

  useEffect(() => {
    if (!currentProfile) return;
    const interval = setInterval(() => {
      const p = playerRef.current;
      if (p && p.currentTime > 0) {
        updateWatchProgress(currentProfile.id, mediaId, mediaType, p.currentTime, p.duration || 0, false);
      }
    }, 10000);
    return () => clearInterval(interval);
  }, [currentProfile, mediaId, mediaType]);

  const onEnded = useCallback(() => {
    const p = playerRef.current;
    if (!currentProfile || !p) return;
    updateWatchProgress(currentProfile.id, mediaId, mediaType, p.currentTime, p.duration || 0, true);
  }, [currentProfile, mediaId, mediaType]);

  const onCanPlay = useCallback(() => {
    if (startPosition && startPosition > 0 && playerRef.current) {
      playerRef.current.currentTime = startPosition;
    }
  }, [startPosition]);

  return (
    <div className="fixed inset-0 bg-black z-50">
      <MediaPlayer
        ref={playerRef}
        src={streamUrl}
        autoPlay
        style={{ width: '100%', height: '100%', position: 'absolute', inset: 0 }}
        onProviderChange={onProviderChange}
        onEnded={onEnded}
        onCanPlay={onCanPlay}
        title={title}
        keyShortcuts={{
          togglePaused: 'k Space',
          toggleMuted: 'm',
          toggleFullscreen: 'f',
          seekBackward: 'ArrowLeft',
          seekForward: 'ArrowRight',
          volumeUp: 'ArrowUp',
          volumeDown: 'ArrowDown',
        }}
      >
        <MediaProvider style={{ width: '100%', height: '100%' }} />

        {subtitles.map(sub => (
          <Track key={sub.id} src={sub.url} kind="subtitles" label={sub.name || sub.lang} language={sub.lang} />
        ))}

        <PlayerUI
          title={title}
          currentStream={currentStream}
          streams={streams}
          subtitles={subtitles}
          startPosition={startPosition}
          mediaId={mediaId}
          mediaType={mediaType}
          onBack={onBack}
          onSwitchStream={onSwitchStream}
          playerRef={playerRef}
        />
      </MediaPlayer>
    </div>
  );
}
