import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Layouts 1.15 as QQLayouts
import org.kde.plasma.core 2.0 as PlasmaCore

Kirigami.FormLayout {
    id: syncPage
    signal configurationChanged

    property alias cfg_showNextLyric: showNextLyricCheckBox.checked
    property alias cfg_nextLyricOpacity: nextLyricOpacitySlider.value
    property alias cfg_transitionDurationMs: transitionDurationMsSpinBox.value
    property alias cfg_syncOffsetMs: syncOffsetMsSpinBox.value

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Next Line Preview")
    }

    QQC2.CheckBox {
        id: showNextLyricCheckBox
        Kirigami.FormData.label: i18n("Show next line preview:")
        text: i18n("Apple Music style 2-line layout")
        checkable: true
    }

    QQLayouts.RowLayout {
        Kirigami.FormData.label: i18n("Next line opacity:")
        enabled: showNextLyricCheckBox.checked
        QQLayouts.Layout.maximumWidth: 300

        QQC2.Slider {
            id: nextLyricOpacitySlider
            from: 0.05
            to: 1.0
            stepSize: 0.05
            QQLayouts.Layout.fillWidth: true
        }
        QQC2.Label {
            text: Math.round(nextLyricOpacitySlider.value * 100) + "%"
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Animations & Timing")
    }

    QQC2.SpinBox {
        id: transitionDurationMsSpinBox
        Kirigami.FormData.label: i18n("Transition duration (ms):")
        from: 0
        to: 1000
        stepSize: 50
        QQLayouts.Layout.maximumWidth: 130
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Manual Sync Adjustment")
    }

    QQC2.SpinBox {
        id: syncOffsetMsSpinBox
        Kirigami.FormData.label: i18n("Sync offset (ms):")
        from: -5000
        to: 5000
        stepSize: 50
        editable: true
        QQLayouts.Layout.maximumWidth: 130
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Offset guide:")
        text: i18n("Positive values (+ms) delay lyrics. Negative values (-ms) advance lyrics.")
        font.italic: true
        font.pointSize: 9
        opacity: 0.8
        wrapMode: Text.WordWrap
    }
}
