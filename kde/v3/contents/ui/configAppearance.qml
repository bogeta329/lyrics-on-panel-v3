import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.15 as QQLayouts

Kirigami.FormLayout {
    id: appearancePage
    signal configurationChanged

    property alias cfg_showAlbumCover: showAlbumCoverCheckBox.checked
    property alias cfg_lyricTextSize: lyricTextSizeSpinBox.value 
    property alias cfg_lyricTextColor: lyricTextColorButton.color
    property alias cfg_lyricTextBold: boldButton.checked   
    property alias cfg_lyricTextItalic: italicButton.checked 
    property alias cfg_lyricTextVerticalOffset: lyricTextVerticalOffsetSpinBox.value
    property alias cfg_lyricTextAlignment: lyricTextAlignmentComboBox.currentIndex

    property alias cfg_mediaControllSpacing: mediaControllSpacingSpinBox.value
    property alias cfg_mediaControllItemSize: mediaControllItemSizeSpinBox.value
    property alias cfg_mediaControllItemVerticalOffset: mediaControllItemVerticalOffsetSpinBox.value
    property alias cfg_whiteMediaControlIconsChecked: whiteMediaControlIconsChecked.checked

    property alias cfg_preferedWidgetWidth: preferedWidgetWidthTextField.text
    property alias cfg_hideItemWhenNoControlChecked: hideItemWhenNoControlChecked.checked

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Text & Typography")
    }

    QQC2.SpinBox {
        id: lyricTextSizeSpinBox
        Kirigami.FormData.label: i18n("Lyric text size:")
        from: 8
        to: 36
        stepSize: 1
        QQLayouts.Layout.maximumWidth: 130
    }

    QQC2.ComboBox {
        id: lyricTextAlignmentComboBox
        Kirigami.FormData.label: i18n("Text alignment:")
        model: [i18n("Left"), i18n("Center"), i18n("Right")]
        currentIndex: 2
        QQLayouts.Layout.maximumWidth: 160
    }

    QQLayouts.RowLayout {
        Kirigami.FormData.label: i18n("Style & color:")
        spacing: Kirigami.Units.smallSpacing

        KQControls.ColorButton {
            id: lyricTextColorButton
        }

        QQC2.Button {
            id: boldButton
            QQC2.ToolTip.text: i18n("Bold text")
            icon.name: "format-text-bold"
            checkable: true
        }

        QQC2.Button {
            id: italicButton
            QQC2.ToolTip.text: i18n("Italic text")
            icon.name: "format-text-italic"
            checkable: true
        }
    }

    QQC2.SpinBox {
        id: lyricTextVerticalOffsetSpinBox
        Kirigami.FormData.label: i18n("Text vertical offset:")
        from: -20
        to: 20
        QQLayouts.Layout.maximumWidth: 130
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Media Controls & Album Art")
    }

    QQC2.CheckBox {
        id: showAlbumCoverCheckBox
        Kirigami.FormData.label: i18n("Display album cover art:")
        text: i18n("Show track cover art instead of player logo")
        checkable: true
    }

    QQC2.CheckBox {
        id: whiteMediaControlIconsChecked
        Kirigami.FormData.label: i18n("White icons (dark mode):")
        checkable: true
    }

    QQC2.SpinBox {
        id: mediaControllItemSizeSpinBox
        Kirigami.FormData.label: i18n("Control icon size:")
        from: 10
        to: 32
        QQLayouts.Layout.maximumWidth: 130
    }

    QQC2.SpinBox {
        id: mediaControllSpacingSpinBox
        Kirigami.FormData.label: i18n("Icon spacing:")
        from: 2
        to: 30
        QQLayouts.Layout.maximumWidth: 130
    }

    QQC2.SpinBox {
        id: mediaControllItemVerticalOffsetSpinBox
        Kirigami.FormData.label: i18n("Icon vertical offset:")
        from: -20
        to: 20
        QQLayouts.Layout.maximumWidth: 130
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Dimensions & Behavior")
    }

    QQC2.TextField {
        id: preferedWidgetWidthTextField
        Kirigami.FormData.label: i18n("Preferred widget width (px):")
        QQLayouts.Layout.maximumWidth: 130
    }

    QQC2.CheckBox {
        id: hideItemWhenNoControlChecked
        Kirigami.FormData.label: i18n("Hide when no media playing:")
        checkable: true
    }
}
