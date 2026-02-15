pragma Singleton

import Quickshell

Singleton {
    function padTime(n: int): string {
        return n.toString().padStart(2, "0");
    }

    function getTimestamp(): string {
        const date = new Date();
        return padTime(date.getHours()) + ":" + padTime(date.getMinutes()) + ":" + padTime(date.getSeconds());
    }

    function clamp(num: int, min: int, max: int): int {
        return Math.round(Math.min(Math.max(num, min), max));
    }

    function toStringTyped(value: var): string {
        let valueString;
        if (typeof value === "string") {
            valueString = `'${value}'`;
        } else if (Number.isInteger(value)) {
            valueString = value;
        } else if (Array.isArray(value)) {
            valueString = `[${value}]`;
        } else if (Utils.isStrictObject(value))
            valueString = JSON.stringify(value, null, 2);
        else {
            throw new Error("Value not supported type: string, int, array");
        }

        return valueString;
    }

    /* Detect POJO */
    function isStrictObject(value) {
        return (typeof value === 'object' && value !== null && !Array.isArray(value) && value.constructor === Object);
    }
}
