import QtQuick
import Quickshell.Io
import qs.common

Item {
    id: config

    required property string path
    required property JsonAdapter adapter

    property bool writeEnabled: true

    Logger {
        id: logger
        name: "ConfigManager"
    }

    FileView {
        id: fileView

        // qmllint disable missing-type
        adapter: config.adapter
        path: config.path

        onAdapterChanged: !fileView.path.startsWith("/etc") && config.writeEnabled ? writeAdapter() : () => {}

        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) {
                logger.critical(`Missing config file: ${fileView.path}`);
            }
        }
    }
}
