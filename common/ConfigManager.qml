import QtQuick
import Quickshell.Io
import qs.common

Item {
    id: config

    required property string fileName
    required property JsonAdapter adapter

    property bool global: false

    Logger {
        id: logger
        name: "ConfigManager"
    }

    FileView {
        id: fileView

        blockWrites: config.global

        // qmllint disable missing-type
        adapter: config.adapter

        path: `${config.global ? Paths.globalConfigDir : Paths.localConfigDir}/${config.fileName}.json`

        onAdapterChanged: writeAdapter()

        onLoadFailed: function (error) {
            if (blockWrites && error === FileViewError.FileNotFound) {
                logger.critical(`Missing config file: ${fileView.path}`);
            }
        }
    }
}
