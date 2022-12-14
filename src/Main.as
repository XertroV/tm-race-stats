[Setting hidden]
bool g_windowVisible = false;

bool g_FontLoaded = false;
float g_LoadedFontSize = 16.;
UI::Font@ mainFont = null;

const MLFeed::HookRaceStatsEventsBase_V2@ raceData = null;

enum Cmp {Lt = -1, Eq = 0, Gt = 1}

void Main() {
    DepCheck();
    MLHook::RequireVersionApi('0.3.1');
    startnew(InitCoro);
    startnew(LoadFont);
    while (raceData is null) {
        @raceData = MLFeed::GetRaceData_V2();
        yield();
    }
    startnew(WatchPlayerCpCounts);
}

void DepCheck() {
    bool depMLHook = false;
    bool depMLFeed = false;
#if DEPENDENCY_MLHOOK
    depMLHook = true;
#endif
#if DEPENDENCY_MLFEEDRACEDATA
    depMLFeed = true;
#endif
    if (!(depMLFeed && depMLHook)) {
        if (!depMLHook) {
            NotifyDepError("Requires MLHook");
        }
        if (!depMLFeed) {
            NotifyDepError("Requires MLFeed: Race Data");
        }
        while (true) sleep(10000);
    }
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {}

void InitCoro() {}


dictionary playerLastCpCounts;
void WatchPlayerCpCounts() {
    int nbPlayers;
    while (true) {
        yield();
        nbPlayers = raceData.SortedPlayers_Race.Length;
        if (nbPlayers == 0) {
            playerLastCpCounts.DeleteAll();
        }
        if (!g_windowVisible) continue;
        for (uint i = 0; i < raceData.SortedPlayers_Race.Length; i++) {
            auto player = cast<MLFeed::PlayerCpInfo_V3>(raceData.SortedPlayers_Race[i]);
            if (!playerLastCpCounts.Exists(player.name)) {
                playerLastCpCounts.Set(player.name, @PlayerCpTracker(player, i));
            } else {
                auto cpTracker = GetPlayersCpTracker(player.name);
                if (cpTracker is null) {
                    // warn("cp tracker exists but is null?? " + player.name);
                    continue;
                }
                cpTracker.UpdateFrom(player, i);
            }
        }
    }
}

PlayerCpTracker@ GetPlayersCpTracker(const string &in name) {
    PlayerCpTracker@ ret = null;
    if (playerLastCpCounts.Get(name, @ret)) {
        return ret;
    }
    // warn("playerLastCpCounts.Get failed: " + name);
    return null;
    // return cast<PlayerCpTracker>(playerLastCpCounts[name]);
}

class PlayerCpTracker {
    int lastCpCount = 0;
    int lastCpRank = 1;
    int priorCpRank = 1;
    int lastCpRankDelta = 0;
    int bestLapTime = -1;

    PlayerCpTracker(MLFeed::PlayerCpInfo_V3@ player, int rank) {
        lastCpCount = player.CpCount;
        lastCpRank = rank;
        if (player.BestLapTimes !is null && player.BestLapTimes.Length > 0) {
            bestLapTime = int(player.BestLapTimes[player.BestLapTimes.Length-1]);
        }
    }

    void UpdateFrom(MLFeed::PlayerCpInfo_V3@ player, int rank) {
        if (lastCpCount == player.CpCount) return;
        lastCpCount = player.CpCount;
        lastCpRankDelta = rank - lastCpRank;
        priorCpRank = lastCpRank;
        lastCpRank = rank;
        if (player.BestLapTimes !is null && player.BestLapTimes.Length > 0) {
            bestLapTime = int(player.BestLapTimes[player.BestLapTimes.Length-1]);
        }
    }
}



void LoadFont() {
    g_FontLoaded = false;
    yield();
    @mainFont = UI::LoadFont("DroidSans.ttf", Setting_FontSize, -1, -1, true, true);
    yield();
    g_FontLoaded = true;
    g_LoadedFontSize = Setting_FontSize;
}

void PushMainFont() {
    if (!g_FontLoaded) return;
    UI::PushFont(mainFont);
}

void PopMainFont() {
    if (!g_FontLoaded) return;
    UI::PopFont();
}

void Render() {
    if (!Setting_ShowWhenOverlayOff || !g_windowVisible) return;
    if (!UI::IsOverlayShown()) {
        RenderInterface();
    }
}

void RenderInterface() {
    if (!g_windowVisible) return;
    PushMainFont();
    UI::SetNextWindowSize(500, 800, UI::Cond::FirstUseEver);
    if (UI::Begin(Meta::ExecutingPlugin().Name, g_windowVisible, UI::WindowFlags::None)) { // UI::WindowFlags::AlwaysAutoResize |
        DrawMainInterior();
    }
    UI::End();
    PopMainFont();
}

const string MenuLabel = "\\$2f8" + Icons::ListAlt + "\\$z " + Meta::ExecutingPlugin().Name;
void RenderMenu() {
    if (UI::MenuItem(MenuLabel, "", g_windowVisible)) {
        g_windowVisible = !g_windowVisible;
    }
}

enum SortMethod {
    Race, Race_Respawns, TimeAttack
}

/* with race, the winning players unspawn. how to differentiate?
maybe track *when* they unspawned, and group those.
so active racers get grouped with most recent unspawn.
then, when the respawn happens, racers all respawn at the same time,
so we can track the number of respawns
*/

array<SortMethod> AllSortMethods = {Race, Race_Respawns, TimeAttack};

[Setting hidden]
SortMethod g_sortMethod = SortMethod::Race_Respawns;

[Setting hidden]
bool Setting_ShowBestTimeCol = true;

[Setting hidden]
bool Setting_ShowBestLapTimeCol = true;

[Setting hidden]
bool Setting_ShowCpPositionDelta = true;

[Setting hidden]
bool Setting_ShowTimeDeltaToFirst = true;

[Setting hidden]
bool Setting_ShowTimeDeltaToAbove = true;

[Setting hidden]
bool Setting_ShowPastCPs = false;

[Setting hidden]
vec4 finishColor = vec4(.2, 1, .2, 1.0);

[Setting hidden]
vec4 blueColor = vec4(0.395f, 0.773f, 0.965f, 1.000f);

[Setting hidden]
vec4 redColor = vec4(0.952f, 0.730f, 0.044f, 1.0);

vec4 ScaledCpColor(uint cp, uint totalCps) {
    float progress = Math::Clamp(float(cp) / float(totalCps + 1), 0., 1.);
    return finishColor * progress + vec4(1,1,1,1) * (1. - progress);
}

vec4 ScaledCpDeltaColor(int cpd, float increments = 4.) {
    if (cpd == 0) return vec4(.5, .5, .5, .5);
    vec4 col = cpd < 0 ? blueColor : redColor;
    float progress = Math::Clamp(float(Math::Abs(cpd)) / increments, 0.3, 1.);
    return col * progress + vec4(1,1,1,1) * (1. - progress);
}

uint GetLapCount() {
    if (S_EnableCustomLapCount) {
        return Math::Max(1, S_CustomLapCount);
    }
    return raceData.LapCount;
}

uint GetCPsToFinish() {
    if (S_EnableCustomLapCount) {
        return GetLapCount() * (raceData.CpCount + 1);
    }
    return raceData.CPsToFinish;
}

void DrawMainInterior() {
    auto theHook = MLFeed::GetRaceData_V2();
    if (theHook is null) return;

    vec2 pos = UI::GetCursorPos();
    UI::AlignTextToFramePadding();

    string cpCountStr = GetLapCount() == 1 ? "" : ("; " + (theHook.CPCount + 1) + " per Lap");
    auto nbPlayers = theHook.SortedPlayers_Race.Length;
    if (S_EnableCustomLapCount) cpCountStr += "\\$888 (custom lap count)";
    UI::Text("" + nbPlayers + " Players  |  " + GetCPsToFinish() + " Total Checkpoints" + cpCountStr);

    float btnSize = UI::GetFrameHeight();
    UI::SetCursorPos(pos + vec2(UI::GetWindowContentRegionWidth() - btnSize, 0));
    // string btnLabel = Setting_HideSortSettings ? Icons::EyeSlash : Icons::Eye;
    if (UI::Button(Setting_HideSortSettings ? Icons::EyeSlash : Icons::Eye, vec2(btnSize, btnSize))) {
        Setting_HideSortSettings = !Setting_HideSortSettings;
    }

    if (!Setting_HideSortSettings)
        DrawSortAndBestTimesSettings();

    bool ShowBestLapCol = Setting_ShowBestLapTimeCol && GetLapCount() > 1;
    bool showingLaps = S_ShowLapNumber && GetLapCount() > 1;

    uint cols = 4;
    if (showingLaps)
        cols++;
    if (Setting_ShowTimeDeltaToFirst)
        cols++;
    if (Setting_ShowTimeDeltaToAbove)
        cols++;
    if (ShowBestLapCol)
        cols++;
    if (Setting_ShowBestTimeCol)
        cols++;
    if (Setting_ShowCpPositionDelta)
        cols++;
    // if (Setting_ShowPastCPs)
    //     cols++;

    bool isTimeAttackSorting = g_sortMethod == SortMethod::TimeAttack;

    auto @sorted = g_sortMethod == SortMethod::Race
        ? theHook.SortedPlayers_Race
        : (isTimeAttackSorting
            ? theHook.SortedPlayers_TimeAttack
            : theHook.SortedPlayers_Race_Respawns);


    const MLFeed::PlayerCpInfo_V2@ firstPlacePlayer = null;
    if (sorted.Length > 0) {
        @firstPlacePlayer = sorted[0];
    }

    // SizingFixedFit / fixedsame / strechsame / strechprop
    if (UI::BeginTable("player times", cols, UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY)) {
        UI::TableSetupColumn("Pos.");
        UI::TableSetupColumn("Player");
        if (showingLaps)
            UI::TableSetupColumn("Lap #");
        UI::TableSetupColumn("CP #");
        UI::TableSetupColumn("CP Time");
        if (Setting_ShowTimeDeltaToFirst)
            UI::TableSetupColumn("+/- to 1st");
        if (Setting_ShowTimeDeltaToAbove)
            UI::TableSetupColumn("+/- to next");
        if (Setting_ShowCpPositionDelta)
            UI::TableSetupColumn("Pos +/-");
        if (ShowBestLapCol)
            UI::TableSetupColumn("Best Lap");
        if (Setting_ShowBestTimeCol)
            UI::TableSetupColumn("Best Time");
        UI::TableHeadersRow();

        UI::ListClipper clipper(sorted.Length);
        while (clipper.Step()) {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                uint colVars = 1;
                auto player = sorted[i];
                auto priorPlayer = i == 0 ? null : sorted[i - 1];
                if (player is null) continue;
                if (player.spawnStatus != MLFeed::SpawnStatus::Spawned) {
                    UI::PushStyleColor(UI::Col::Text, vec4(.3, .65, 1, .9));
                } else if (player.cpCount >= int(GetCPsToFinish())) { // finished 1-lap
                    UI::PushStyleColor(UI::Col::Text, vec4(.2, 1, .2, .9));
                } else if (player.name == LocalUserName && Setting_HighlightLocalPlayersName) {
                    UI::PushStyleColor(UI::Col::Text, vec4(1, .3, .65, .9));
                } else {
                    UI::PushStyleColor(UI::Col::Text, vec4(1, 1, 1, 1));
                }
                UI::TableNextRow();

                UI::TableNextColumn();
                UI::Text(tostring(i + 1) + "."); // rank

                UI::TableNextColumn();
                UI::Text(player.Name);
                if (g_ShiftKeyDown && UI::IsItemHovered()) {
                    bool clicked = UI::IsItemClicked();
                    AddSimpleTooltip("\\$fffClick to spectate.");
                    if (clicked) {
                        trace("Clicked: " + player.Name);
                        SpectatePlayer(player.Name);
                    }
                }

                // lap / CP
                UI::PushStyleColor(UI::Col::Text, ScaledCpColor(player.CpCount, GetCPsToFinish()));
                if (showingLaps) {
                    UI::TableNextColumn();
                    if (player.IsSpawned && player.CpCount < int(GetCPsToFinish()))
                        UI::Text(Text::Format("%.0f", Math::Floor(float(player.CpCount) / float(theHook.CpCount + 1) + 1)));
                }

                UI::TableNextColumn();
                string cpCount = tostring(player.CpCount);
                if (player.CpCount > 0 && S_ShowPercentAfterCP) {
                    cpCount += " (" + Text::Format("%.0f", Math::Floor(100. * float(player.CpCount) / float(GetCPsToFinish()))) + "%)";
                }
                if (player.IsSpawned)
                    UI::Text(cpCount);
                UI::PopStyleColor();

                UI::TableNextColumn();
                if (player.CpCount > 0) {
                    UI::Text(MsToSeconds(player.LastCpTime));
                } else {
                    UI::Text('---');
                }

                if (Setting_ShowTimeDeltaToFirst) {
                    UI::TableNextColumn();
                    // skip player in 1st
                    if (i > 0 && (isTimeAttackSorting || player.IsSpawned)) {
                        int playerTime = isTimeAttackSorting ? sorted[i].BestTime : sorted[i].LastCpOrRespawnTime;
                        int firstTime = isTimeAttackSorting ? firstPlacePlayer.BestTime : firstPlacePlayer.CpTimes[player.CpCount];
                        int extraTime = 0;
                        // int extraTime = isTimeAttackSorting || player.CpCount == firstPlacePlayer.CpCount ? 0
                        //     : firstPlacePlayer.LastCpOrRespawnTime - firstPlacePlayer.CpTimes[player.CpCount];
                        if (playerTime >= 0) {
                            int delta = playerTime - firstTime;
                            int deltaMod = 0;
                            if (delta != 0) deltaMod = delta < 0 ? -1000 : 1000;
                            UI::PushStyleColor(UI::Col::Text, ScaledCpDeltaColor((delta + deltaMod) / 1000, 10));
                            UI::Text(MsToSeconds(delta));
                            UI::PopStyleColor();
                        }
                    }
                }

                if (Setting_ShowTimeDeltaToAbove) {
                    UI::TableNextColumn();
                    // skip player in 1st
                    if (i > 0 && priorPlayer !is null && (isTimeAttackSorting || player.IsSpawned)) {
                        int playerTime = isTimeAttackSorting ? sorted[i].BestTime : sorted[i].LastCpOrRespawnTime;
                        int aboveTime = isTimeAttackSorting ? priorPlayer.BestTime : priorPlayer.CpTimes[player.CpCount];
                        int extraTime = 0;
                        // int extraTime = isTimeAttackSorting || player.CpCount == priorPlayer.CpCount ? 0
                        //     : priorPlayer.LastCpOrRespawnTime - priorPlayer.CpTimes[player.CpCount];
                        if (playerTime >= 0) {
                            int delta = playerTime - aboveTime;
                            int deltaMod = 0;
                            if (delta != 0) deltaMod = delta < 0 ? -1000 : 1000;
                            UI::PushStyleColor(UI::Col::Text, ScaledCpDeltaColor((delta + deltaMod) / 1000, 10));
                            UI::Text(MsToSeconds(delta));
                            UI::PopStyleColor();
                        }
                    }
                }

                auto cpTracker = GetPlayersCpTracker(player.name);

                if (Setting_ShowCpPositionDelta) {
                    UI::TableNextColumn();
                    if (cpTracker !is null && cpTracker.lastCpCount > 1) {
                        int delta = int(i) - cpTracker.priorCpRank;
                        string cpd = (delta < 0 ? "-" : (delta > 0 ? "+" : ""))
                            + Math::Abs(delta);
                        UI::PushStyleColor(UI::Col::Text, ScaledCpDeltaColor(delta));
                        UI::Text(cpd);
                        UI::PopStyleColor();
                    }
                }

                if (ShowBestLapCol) {
                    UI::TableNextColumn();
                    if (cpTracker !is null) {
                        auto bt = int(cpTracker.bestLapTime);
                        if (bt > 0) UI::Text(MsToSeconds(bt));
                    }
                }

                if (Setting_ShowBestTimeCol) {
                    UI::TableNextColumn();
                    auto bt = int(player.BestTime);
                    if (bt > 0) UI::Text(MsToSeconds(bt));
                }

                UI::PopStyleColor(colVars);
            }
        }
        UI::EndTable();
    }
}

const string get_LocalUserName() {
    auto NW = cast<CTrackManiaNetwork>(GetApp().Network);
    if (NW is null) return "";
    return NW.PlayerInfo.Name;
}

const string MsToSeconds(int t) {
    return (t < 0 ? "-" : "") +  Time::Format(Math::Abs(t), true, true);
    // return Text::Format("%.3f", float(t) / 1000.0);
}

// just pretend the shift key is always pressed down.
bool g_ShiftKeyDown = true;

/** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey).
*/
// UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
//     if (key == VirtualKey::Shift) {
//         g_ShiftKeyDown = down;
//     }
//     return UI::InputBlocking::DoNothing;
// }
