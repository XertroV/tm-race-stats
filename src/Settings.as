[Setting hidden]
float Setting_FontSize = 18;

[Setting hidden]
bool Setting_HideSortSettings = false;

[Setting hidden]
bool Setting_HighlightLocalPlayersName = true;

[Setting hidden]
bool S_ShowPercentAfterCP = false;

[Setting hidden]
bool S_ShowLapNumber = true;

[SettingsTab name="General" icon="Cogs" order="1"]
void RenderSettings_General() {
    PushMainFont();

    DrawSortAndBestTimesSettings();

    Setting_HideSortSettings = UI::Checkbox("Hide sort setting / best time checkbox in main window?", Setting_HideSortSettings);
    S_ShowPercentAfterCP = UI::Checkbox("Show % after CP number?", S_ShowPercentAfterCP);
    S_ShowLapNumber = UI::Checkbox("Show Lap number column?", S_ShowLapNumber);

    UI::Separator();

    Setting_FontSize = UI::SliderFloat("Font Size", Setting_FontSize, 14., 32., "%.1f");
    AddSimpleTooltip("Ctrl+click to input exact value.");

    bool disabled = g_LoadedFontSize == Setting_FontSize;
    UI::BeginDisabled(disabled);
    if (UI::Button("Reload Font")) {
        startnew(LoadFont);
    }
    UI::EndDisabled();
    if (!disabled) {
        UI::SameLine();
        UI::TextWrapped("\\$fe1 " + Icons::ExclamationTriangle + "  Warning! Doing this too much can crash the game. Settings only save if the game exits cleanly, and the safest time to load fonts is at startup. Once you find the right font size, you should restart the game so that the setting persists properly. (Note: this setting will save even if you don't click 'Reload font'.)");
    }

    UI::Separator();

    UI::TextWrapped("Spectate a player by shift clicking their name in the main Race Stats window.");

    PopMainFont();
}

void DrawSortAndBestTimesSettings() {
    if (UI::BeginCombo("Sort Method", tostring(g_sortMethod))) {
        for (uint i = 0; i < AllSortMethods.Length; i++) {
            auto item = AllSortMethods[i];
            if (UI::Selectable(tostring(item), item == g_sortMethod)) {
                g_sortMethod = item;
            }
        }
        UI::EndCombo();
    }
    UI::SameLine();
    UI::Text("\\$999"+Icons::QuestionCircle);
    AddSimpleTooltip("Race:                    Sort by most CPs, then lowest CP time.\nRace_Respawns: Like 'Race' but updates immediately if a player respawns.\nTimeAttack:         Sort by best time set on this server.");

    auto pos = UI::GetCursorPos();
    Setting_ShowBestTimeCol = UI::Checkbox("Show Best Times?", Setting_ShowBestTimeCol);
    pos.x += UI::GetWindowContentRegionWidth() / 2.;
    UI::SetCursorPos(pos);
    Setting_ShowCpPositionDelta = UI::Checkbox("Show CP pos. gain/loss?", Setting_ShowCpPositionDelta);
}

[SettingsTab name="Colors" icon="PaintBrush" order="10"]
void RenderSettings_Colors() {
    PushMainFont();

    finishColor = UI::InputColor4("Finished Color", finishColor);
    blueColor = UI::InputColor4("CP Gain Position Color", blueColor);
    redColor = UI::InputColor4("CP Lose Position Color", redColor);

    Setting_HighlightLocalPlayersName = UI::Checkbox("Highlight your name in the race stats?", Setting_HighlightLocalPlayersName);

    PopMainFont();
}