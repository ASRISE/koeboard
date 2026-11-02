import React from "react";
import { useTranslation } from "react-i18next";
import { ToggleSwitch } from "../ui/ToggleSwitch";
import { useSettings } from "../../hooks/useSettings";

interface PostProcessOnDictationProps {
  descriptionMode?: "inline" | "tooltip";
  grouped?: boolean;
}

/** Koeboard: clean up with the AI on the main dictation shortcut too. */
export const PostProcessOnDictation: React.FC<PostProcessOnDictationProps> =
  React.memo(({ descriptionMode = "tooltip", grouped = false }) => {
    const { t } = useTranslation();
    const { getSetting, updateSetting, isUpdating } = useSettings();

    const enabled = getSetting("post_process_on_dictation") ?? true;

    return (
      <ToggleSwitch
        checked={enabled}
        onChange={(value) => updateSetting("post_process_on_dictation", value)}
        isUpdating={isUpdating("post_process_on_dictation")}
        label={t("settings.postProcessing.onDictation.label")}
        description={t("settings.postProcessing.onDictation.description")}
        descriptionMode={descriptionMode}
        grouped={grouped}
      />
    );
  });
