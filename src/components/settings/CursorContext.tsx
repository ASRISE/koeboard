import React from "react";
import { useTranslation } from "react-i18next";
import { ToggleSwitch } from "../ui/ToggleSwitch";
import { useSettings } from "../../hooks/useSettings";

interface CursorContextProps {
  descriptionMode?: "inline" | "tooltip";
  grouped?: boolean;
}

/** Koeboard: use the text before the cursor as context. */
export const CursorContext: React.FC<CursorContextProps> = React.memo(
  ({ descriptionMode = "tooltip", grouped = false }) => {
    const { t } = useTranslation();
    const { getSetting, updateSetting, isUpdating } = useSettings();

    const enabled = getSetting("use_cursor_context") ?? true;

    return (
      <ToggleSwitch
        checked={enabled}
        onChange={(value) => updateSetting("use_cursor_context", value)}
        isUpdating={isUpdating("use_cursor_context")}
        label={t("settings.advanced.cursorContext.label")}
        description={t("settings.advanced.cursorContext.description")}
        descriptionMode={descriptionMode}
        grouped={grouped}
      />
    );
  },
);
