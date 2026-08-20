import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance & Layout")
        icon: "preferences-desktop-display"
        source: "configAppearance.qml"
    }

    ConfigCategory {
        name: i18n("Animation & Sync")
        icon: "media-playback-start"
        source: "configSync.qml"
    }
}