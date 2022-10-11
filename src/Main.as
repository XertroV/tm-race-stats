[Setting hidden]
bool g_windowVisible = false;

UI::Font@ subheadingFont = UI::LoadFont("DroidSans.ttf", 18, -1, -1, true, true);

enum Cmp {Lt = -1, Eq = 0, Gt = 1}

/*

todo show green when players fin

 */
void Main() {
    DepCheck();
    MLHook::RequireVersionApi('0.3.1');
    startnew(InitCoro);
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

void Render() {}

void RenderInterface() {
    if (!g_windowVisible) return;
    UI::PushFont(subheadingFont);
    if (UI::Begin("Race Stats", g_windowVisible, UI::WindowFlags::NoCollapse)) { // UI::WindowFlags::AlwaysAutoResize |
        DrawMainInterior();
    }
    UI::End();
    UI::PopFont();
}

void RenderMenu() {
    if (UI::MenuItem("\\$2f8" + Icons::ListAlt + "\\$z Race Stats", "", g_windowVisible)) {
        g_windowVisible = !g_windowVisible;
    }
}

enum SortMethod {
    Race, TimeAttack
}

/* with race, the winning players unspawn. how to differentiate?
maybe track *when* they unspawned, and group those.
so active racers get grouped with most recent unspawn.
then, when the respawn happens, racers all respawn at the same time,
so we can track the number of respawns
*/

SortMethod[] AllSortMethods = {Race, TimeAttack};

[Setting hidden]
SortMethod g_sortMethod = SortMethod::TimeAttack;
[Setting hidden]
bool Setting_ShowBestTimeCol = true;
[Setting hidden]
bool Setting_ShowPastCPs = false;

vec4 finishColor = vec4(.2, 1, .2, .9);

vec4 ScaledCpColor(uint cp, uint totalCps) {
    float progress = float(cp) / float(totalCps + 1);
    return finishColor * progress + vec4(1,1,1,1) * (1 - progress);
}

void DrawMainInterior() {
    auto theHook = MLFeed::GetRaceData();

    if (theHook is null) return;

    string cpCountStr = theHook.LapCount == 1 ? "" : ("; " + (theHook.CPCount + 1) + " per Lap");
    UI::Text("" + theHook.SortedPlayers_Race.Length + " Players  |  " + theHook.CPsToFinish + " Total Checkpoints" + cpCountStr);

    if (UI::BeginCombo("Sort Method", tostring(g_sortMethod))) {
        for (uint i = 0; i < AllSortMethods.Length; i++) {
            auto item = AllSortMethods[i];
            if (UI::Selectable(tostring(item), item == g_sortMethod)) {
                g_sortMethod = item;
            }
        }
        UI::EndCombo();
    }

    Setting_ShowBestTimeCol = UI::Checkbox("Show Best Times?", Setting_ShowBestTimeCol);

    uint cols = 4;
    if (Setting_ShowBestTimeCol)
        cols++;
    if (Setting_ShowPastCPs)
        cols++;

    auto @sorted = g_sortMethod == SortMethod::Race ? theHook.SortedPlayers_Race : theHook.SortedPlayers_TimeAttack;

    // SizingFixedFit / fixedsame / strechsame / strechprop
    if (UI::BeginTable("player times", cols, UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY)) {
        UI::TableSetupColumn("Pos.");
        UI::TableSetupColumn("Player");
        UI::TableSetupColumn("CP #");
        UI::TableSetupColumn("CP Lap Time");
        if (Setting_ShowBestTimeCol)
            UI::TableSetupColumn("Best Time");
        UI::TableHeadersRow();

        for (uint i = 0; i < sorted.Length; i++) {
            uint colVars = 1;
            auto player = sorted[i];
            if (player is null) continue;
            if (player.spawnStatus != MLFeed::SpawnStatus::Spawned) {
                UI::PushStyleColor(UI::Col::Text, vec4(.3, .65, 1, .9));
            } else if (player.cpCount >= int(theHook.CPsToFinish)) { // finished 1-lap
                UI::PushStyleColor(UI::Col::Text, vec4(.2, 1, .2, .9));
            } else if (player.name == LocalUserName) {
                UI::PushStyleColor(UI::Col::Text, vec4(1, .3, .65, .9));
            } else {
                UI::PushStyleColor(UI::Col::Text, vec4(1, 1, 1, 1));
            }
            UI::TableNextRow();

            UI::TableNextColumn();
            UI::Text("" + (i + 1) + "."); // rank

            UI::TableNextColumn();
            UI::Text(player.name);

            UI::TableNextColumn();
            UI::PushStyleColor(UI::Col::Text, ScaledCpColor(player.cpCount, theHook.CPsToFinish));
            UI::Text('' + player.cpCount);
            UI::PopStyleColor();

            UI::TableNextColumn();
            if (player.cpCount > 0) {
                UI::Text(MsToSeconds(player.lastCpTime));
            } else {
                UI::Text('---');
            }

            if (Setting_ShowBestTimeCol) {
                UI::TableNextColumn();
                auto bt = int(player.bestTime);
                if (bt > 0) UI::Text(MsToSeconds(bt));
            }

            UI::PopStyleColor(colVars);
        }
        UI::EndTable();
    }
}

const string get_LocalUserName() {
    auto NW = cast<CTrackManiaNetwork>(GetApp().Network);
    if (NW is null) return "";
    return NW.PlayerInfo.Login;
}

const string MsToSeconds(int t) {
    return Text::Format("%.3f", float(t) / 1000.0);
}
