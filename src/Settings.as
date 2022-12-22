[Setting hidden]
float Setting_FontSize = 20;

[Setting hidden]
bool Setting_HideSortSettings = false;

[Setting hidden]
bool Setting_ShowWhenOverlayOff = false;

[Setting hidden]
bool Setting_HighlightLocalPlayersName = true;

[Setting hidden]
bool S_ShowPercentAfterCP = false;

[Setting hidden]
bool S_ShowLapNumber = true;

[Setting hidden]
bool S_EnableCustomLapCount = false;

[Setting hidden]
int S_CustomLapCount = 26;

[SettingsTab name="General" icon="Cogs" order="1"]
void RenderSettings_General() {

    Setting_ShowWhenOverlayOff = UI::Checkbox("Show the main window when the overlay is off?", Setting_ShowWhenOverlayOff);

    DrawSortAndBestTimesSettings();

    Setting_HideSortSettings = UI::Checkbox("Hide sort setting / best time checkbox in main window?", Setting_HideSortSettings);
    S_ShowPercentAfterCP = UI::Checkbox("Show % after CP number?", S_ShowPercentAfterCP);
    S_ShowLapNumber = UI::Checkbox("Show Lap number column?", S_ShowLapNumber);

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("Override Lap Count (required for some game modes)");
    S_EnableCustomLapCount = UI::Checkbox("##lap-count-override", S_EnableCustomLapCount);
    UI::SameLine();
    UI::BeginDisabled(!S_EnableCustomLapCount);
    S_CustomLapCount = UI::InputInt("Lap Count", S_CustomLapCount, 1);
    S_CustomLapCount = Math::Clamp(S_CustomLapCount, 1, 100);
    UI::EndDisabled();

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("Font Size");

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
        vec2 pos = UI::GetCursorPos();
        UI::TextWrapped("\\$fe1 " + Icons::ExclamationTriangle + "  Warning! Doing this too much can crash the game. Settings only save if the game exits cleanly, and the safest time to load fonts is at startup. Once you find the right font size, you should restart the game so that the setting persists properly. (Note: this setting will save even if you don't click 'Reload font'.)");
        vec2 pos2 = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos.x, pos2.y));
        UI::Markdown("[Logged as Openplanet Github Issue #39](https://github.com/openplanet-nl/issues/issues/39)");
    }

    UI::Separator();
    PushMainFont();
    UI::Text("Font demo");
    UI::TextWrapped("Spectate a player by clicking their name in the main Race Stats window.");
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
    float xStep = UI::GetWindowContentRegionWidth() / 5.;
    Setting_ShowTimeDeltaToFirst = UI::Checkbox("+- to 1st?", Setting_ShowTimeDeltaToFirst);
    pos.x += xStep;
    UI::SetCursorPos(pos);
    Setting_ShowTimeDeltaToAbove = UI::Checkbox("+- to next?", Setting_ShowTimeDeltaToAbove);
    pos.x += xStep;
    UI::SetCursorPos(pos);
    Setting_ShowCpPositionDelta = UI::Checkbox("Pos. +-?", Setting_ShowCpPositionDelta);
    pos.x += xStep;
    UI::SetCursorPos(pos);
    Setting_ShowBestLapTimeCol = UI::Checkbox("B Lap?", Setting_ShowBestLapTimeCol);
    pos.x += xStep;
    UI::SetCursorPos(pos);
    Setting_ShowBestTimeCol = UI::Checkbox("B Time?", Setting_ShowBestTimeCol);
}

[SettingsTab name="Colors" icon="PaintBrush" order="10"]
void RenderSettings_Colors() {
    finishColor = UI::InputColor4("Finished Color", finishColor);
    blueColor = UI::InputColor4("CP Gain Position Color", blueColor);
    redColor = UI::InputColor4("CP Lose Position Color", redColor);

    Setting_HighlightLocalPlayersName = UI::Checkbox("Highlight your name in the race stats?", Setting_HighlightLocalPlayersName);
}
