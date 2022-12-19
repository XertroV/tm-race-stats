/* tooltips */

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}

// /* button */

void DisabledButton(const string &in text, const vec2 &in size = vec2 ( )) {
    UI::BeginDisabled();
    UI::Button(text, size);
    UI::EndDisabled();
}

bool MDisabledButton(bool disabled, const string &in text, const vec2 &in size = vec2 ( )) {
    if (disabled) {
        DisabledButton(text, size);
        return false;
    } else {
        return UI::Button(text, size);
    }
}

/*
Notification stuff
*/

void NotifyDepError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Dependency Error", msg, vec4(.9, .6, .1, .5), 15000);
}
