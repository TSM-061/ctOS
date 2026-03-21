pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: focusManager

    readonly property var currentItem: _currentTarget?.item

    property var _currentTarget: null
    property var _targets: []

    onCurrentItemChanged: {
        if (currentItem) {
            currentItem.forceActiveFocus();
        }
    }

    function _getFocusableTargets() {
        return _targets.filter(t => t.item.visible && t.item.enabled);
    }

    function registerTarget(item: var, options = {}) {
        const {
            tabIndex = 0
        } = options;

        _targets.push({
            item: item,
            tabIndex: tabIndex
        });

        _targets.sort((a, b) => a.tabIndex - b.tabIndex);
    }

    function requestFocus(item: var) {
        _currentTarget = _targets.find(target => {
            if (!target.item || !item) {
                return false;
            }

            return target.item.toString() === item.toString();
        }) ?? null;
    }

    function focusNext() {
        const focusable = _getFocusableTargets();
        const index = focusable.findIndex(target => {
            if (!target.item || !_currentTarget?.item) {
                return false;
            }

            return target.item.toString() === _currentTarget.item.toString();
        });
        _currentTarget = focusable[(index + 1) % focusable.length] ?? null;
    }

    function focusPrevious() {
        const focusable = _getFocusableTargets();
        const index = focusable.findIndex(target => {
            if (!target.item || !_currentTarget?.item) {
                return false;
            }

            return target.item.toString() === _currentTarget.item.toString();
        });
        _currentTarget = focusable[(index - 1 + focusable.length) % focusable.length] ?? null;  // prevent negative remainder
    }
}
