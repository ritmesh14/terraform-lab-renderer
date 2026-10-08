import {Config} from '@remotion/cli/config';

Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);
// 1920x1080 @ 30fps, H.264 + AAC, subtitles are EXTERNAL ONLY (episode.srt).
// Remotion must never receive SRT as visual input (config/render.json policy).
export default Config;
