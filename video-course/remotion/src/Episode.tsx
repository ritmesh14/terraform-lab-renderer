import React from 'react';
import {AbsoluteFill, Audio, Series, staticFile} from 'remotion';
import {TitleScene} from './components/TitleScene';
import {CodeScene} from './components/CodeScene';
import {TerminalScene} from './components/TerminalScene';
import {DiagramScene} from './components/DiagramScene';
import {ConceptScene} from './components/ConceptScene';
import {PortalScene} from './components/PortalScene';
import {RecapScene} from './components/RecapScene';
import {NextEpisodeScene} from './components/NextEpisodeScene';
import {IterationExpansionScene} from './components/IterationExpansionScene';
import {StateAddressScene} from './components/StateAddressScene';
import {ForEachMapScene} from './components/ForEachMapScene';
import {DynamicBlockScene} from './components/DynamicBlockScene';

export type TimedScene = {
  id: string;
  type?: string;
  total_frames: number;
  scene_start_frame: number;
  starts_at_frame: number;
  // narration-synced diagram scenes: per-step highlight windows, RELATIVE to
  // the scene's first frame (calculated from measured step-audio durations)
  step_frames?: {key: string; start: number; end: number}[];
};

export type EpisodeProps = {
  episodeDir: string;
  publicLabUrl: string;
  title: string;
  lessonLabel: string;
  // injected by generate_course.py from timing/timed-scenes.json + writing/scenes.json:
  timedScenes?: TimedScene[];
  scenes?: Record<string, unknown>[];
  totalDurationFrames?: number;
};

const sceneComponent: Record<string, React.FC<any>> = {
  TITLE: TitleScene,
  CODE: CodeScene,
  TERMINAL: TerminalScene,
  DIAGRAM: DiagramScene,
  CONCEPT: ConceptScene,
  PORTAL: PortalScene,
  RECAP: RecapScene,
  NEXT: NextEpisodeScene,
  ITERATION_EXPANSION: IterationExpansionScene,
  STATE_ADDRESS: StateAddressScene,
  FOR_EACH_MAP: ForEachMapScene,
  DYNAMIC_BLOCK: DynamicBlockScene,
};

export const Episode: React.FC<EpisodeProps> = (props) => {
  const timed = props.timedScenes ?? [];
  const byId = Object.fromEntries((props.scenes ?? []).map((s: any) => [s.id, s]));
  return (
    <AbsoluteFill style={{backgroundColor: '#0B1120'}}>
      <Series>
        {timed.map((t) => {
          const raw: any = byId[t.id] ?? {};
          // scene assets are stored relative to the episode folder (audio/…, assets/…);
          // prefix with episodeDir once, here, so every scene component can stay simple
          const def: any = raw.asset && props.episodeDir
            && !String(raw.asset).startsWith(props.episodeDir)
            ? {...raw, asset: `${props.episodeDir}/${raw.asset}`} : raw;
          // diagram scenes: step_frames from the timing pipeline drive the
          // narration-synchronized highlighting in DiagramScene
          if (t.step_frames) def.step_frames = t.step_frames;
          const Comp = sceneComponent[def.type ?? t.type ?? 'CONCEPT'] ?? ConceptScene;
          return (
            <Series.Sequence key={t.id} durationInFrames={t.total_frames}>
              <>
                <Comp {...def} publicLabUrl={props.publicLabUrl}
                      title={props.title} lessonLabel={props.lessonLabel} />
                {def.audio ? <Audio src={staticFile(`${props.episodeDir}/${def.audio}`)} /> : null}
              </>
            </Series.Sequence>
          );
        })}
      </Series>
    </AbsoluteFill>
  );
};
