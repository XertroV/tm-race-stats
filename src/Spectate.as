void SpectatePlayer(const string &in name) {
    auto net = GetApp().Network;
    auto pgsapi = net.PlaygroundClientScriptAPI;
    auto svrInfo = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);

    auto player = MLFeed::GetRaceData_V2().GetPlayer_V2(LocalUserName);

    auto target = FindPlayerInfo(name);
    if (target is null) return;

    pgsapi.UI.Spectator_SetAutoTarget_Clear();
    if (player is null || player.SpawnStatus != MLFeed::SpawnStatus::NotSpawned || (!pgsapi.IsSpectatorClient && svrInfo !is null && !svrInfo.CurGameModeStr.Contains("TM_KnockoutDaily_Online")))
        pgsapi.RequestSpectatorClient(true);
    pgsapi.SetSpectateTarget(target.Login);
}

CTrackManiaPlayerInfo@ FindPlayerInfo(const string &in name) {
    auto net = GetApp().Network;
    for (uint i = 0; i < net.PlayerInfos.Length; i++) {
        auto item = cast<CTrackManiaPlayerInfo>(net.PlayerInfos[i]);
        if (item.Name == name) {
            return item;
        }
    }
    warn("FindPlayerInfo not found: " + name);
    return null;
}
