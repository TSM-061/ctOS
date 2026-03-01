pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: focusManager

    readonly property var current: _currentEntry?.item ?? null

    property var _currentEntry: null
    property var _targets: []

    function registerTarget(item: var, tabIndex: int) {
        _targets.push({
            item: item,
            tabIndex: tabIndex
        });
        _targets.sort((a, b) => a.tabIndex - b.tabIndex);
        console.log(`[FocusManager] Registered target at tabIndex ${tabIndex}. Total targets: ${_targets.length}`);
    }

    function requestFocus(item: var) {
        _currentEntry = _targets.find(t => t.item === item) ?? null;
        console.log(`[FocusManager] Focus changed -> tabIndex: ${_currentEntry?.tabIndex ?? "none"}`);
    }

    function focusNext() {
        const index = _targets.findIndex(t => t.item === _currentEntry?.item);
        _currentEntry = _targets[(index + 1) % _targets.length] ?? null;
        console.log(`[FocusManager] focusNext -> tabIndex: ${_currentEntry?.tabIndex ?? "none"}`);
    }

    function focusPrevious() {
        const index = _targets.findIndex(t => t.item === _currentEntry?.item);
        _currentEntry = _targets[(index - 1 + _targets.length) % _targets.length] ?? null;
        console.log(`[FocusManager] focusPrevious -> tabIndex: ${_currentEntry?.tabIndex ?? "none"}`);
    }
}
