import videoScriptJson from './video-script.json';

export type PromoSceneType =
  | 'hook'
  | 'problem'
  | 'solution'
  | 'feature'
  | 'emotion'
  | 'call_to_action';

export type PromoScriptScene = {
  time_start: number;
  time_end: number;
  voiceover: string;
  on_screen_text: string;
  scene_type: PromoSceneType;
};

export type PromoVideoScript = {
  video_duration_seconds: number;
  scenes: PromoScriptScene[];
};

export const promoVideoScript = videoScriptJson as PromoVideoScript;

export const getScenesByType = (
  sceneType: PromoSceneType | PromoSceneType[]
): PromoScriptScene[] => {
  const sceneTypes = Array.isArray(sceneType) ? sceneType : [sceneType];

  return promoVideoScript.scenes.filter((scene) => sceneTypes.includes(scene.scene_type));
};

export const getActiveSceneByType = (
  timeInSeconds: number,
  sceneType: PromoSceneType | PromoSceneType[]
): PromoScriptScene => {
  const scopedScenes = getScenesByType(sceneType);

  return (
    scopedScenes.find(
      (scene) => timeInSeconds >= scene.time_start && timeInSeconds < scene.time_end
    ) ?? scopedScenes[scopedScenes.length - 1]
  );
};
