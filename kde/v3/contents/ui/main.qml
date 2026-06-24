import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtWebSockets

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents

/**
 * Lyrics on Panel for KDE Plasma 6 - v2.0.0
 *
 * This version uses a WebSocket connection to communicate with a Python backend
 * server that handles MPRIS2 interactions and lyrics fetching.
 *
 * Backend endpoints:
 *   ws://127.0.0.1:23560/poll    - Poll for player state and lyrics
 *   ws://127.0.0.1:23560/control - Send playback control commands
 */

PlasmoidItem {
    id: root

    width: 0
    height: (lyricColumn ? lyricColumn.height : 0) + 8

    preferredRepresentation: fullRepresentation
    Layout.preferredWidth: config_preferedWidgetWidth
    Layout.preferredHeight: height

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground

    Plasmoid.status: hasActivePlayer || !config_hideItemWhenNoControlChecked
        ? PlasmaCore.Types.ActiveStatus
        : PlasmaCore.Types.HiddenStatus

    RowLayout {
        anchors.fill: parent
        spacing: config_mediaControllSpacing

        Item {
            id: lyricTextContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            onWidthChanged: {
                if (lyricBounceAnimation.running) {
                    lyricBounceAnimation.stop()
                    restartTimer.start()
                }
            }

            SequentialAnimation {
                id: lyricBounceAnimation
                running: lyricColumn.width > lyricTextContainer.width && playbackStatus === "playing"
                loops: Animation.Infinite

                PropertyAnimation {
                    target: lyricColumn
                    property: "xPosition"
                    from: 0
                    to: lyricTextContainer.width - lyricColumn.width
                    duration: animationDuration
                    easing.type: Easing.Linear
                }

                PauseAnimation { duration: 1000 }

                PropertyAnimation {
                    target: lyricColumn
                    property: "xPosition"
                    from: lyricTextContainer.width - lyricColumn.width
                    to: 0
                    duration: animationDuration
                    easing.type: Easing.Linear
                }

                PauseAnimation { duration: 1000 }
            }

            Timer {
                id: restartTimer
                interval: 50
                running: false
                repeat: false
                onTriggered: {
                    if (lyricColumn.width > lyricTextContainer.width && playbackStatus === "playing") {
                        lyricColumn.xPosition = 0
                        lyricBounceAnimation.start()
                    }
                }
            }

            Item {
                id: lyricColumn
                property real spacing: 0
                height: (currentLyricText ? currentLyricText.contentHeight : 0) + ((nextLyricText && nextLyricText.visible) ? (nextLyricText.contentHeight * 0.8 + 2) : 0)
                width: currentLyricText ? currentLyricText.contentWidth : 0
                
                y: {
                    var centerY = (lyricTextContainer.height - height) / 2;
                    return Math.max(2, centerY) + config_lyricTextVerticalOffset;
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                property real initialXPosition: {
                    if (config_lyricTextAlignment === 0) {
                        return 0
                    } else if (config_lyricTextAlignment === 1) {
                        return (lyricTextContainer.width - width) / 2
                    } else {
                        return lyricTextContainer.width - width
                    }
                }

                property real xPosition: initialXPosition

                x: width <= lyricTextContainer.width || !lyricBounceAnimation.running
                    ? initialXPosition
                    : xPosition

                onWidthChanged: {
                    lyricBounceAnimation.stop()
                    restartTimer.start()
                }

                Text {
                    id: currentLyricText
                    text: displayedLyric || lrc_not_exists
                    color: config_lyricTextColor
                    font.pixelSize: actualFontSize
                    font.bold: config_lyricTextBold
                    font.italic: config_lyricTextItalic
                    
                    anchors.top: parent.top
                    anchors.horizontalCenter: config_lyricTextAlignment === 1 ? parent.horizontalCenter : undefined
                    anchors.left: config_lyricTextAlignment === 0 ? parent.left : undefined
                    anchors.right: config_lyricTextAlignment === 2 ? parent.right : undefined

                    transformOrigin: {
                        if (config_lyricTextAlignment === 0) return Item.Left
                        else if (config_lyricTextAlignment === 1) return Item.Center
                        else return Item.Right
                    }

                    transform: Translate {
                        id: currentTranslate
                        y: 0
                    }
                }

                Text {
                    id: nextLyricText
                    text: displayedNextLyric
                    color: config_lyricTextColor
                    font.pixelSize: actualFontSize
                    font.bold: config_lyricTextBold
                    font.italic: config_lyricTextItalic
                    opacity: config_nextLyricOpacity
                    visible: config_showNextLyric && displayedLyric && displayedNextLyric
                    
                    anchors.top: currentLyricText.bottom
                    anchors.topMargin: lyricColumn.spacing
                    
                    anchors.horizontalCenter: config_lyricTextAlignment === 1 ? parent.horizontalCenter : undefined
                    anchors.left: config_lyricTextAlignment === 0 ? parent.left : undefined
                    anchors.right: config_lyricTextAlignment === 2 ? parent.right : undefined

                    transformOrigin: currentLyricText.transformOrigin
                    scale: 0.8

                    transform: Translate {
                        id: nextTranslate
                        y: 0
                    }
                }
            }
        }

        RowLayout {
            id: iconsContainer
            Layout.preferredWidth: 5 * config_mediaControllItemSize + 4 * config_mediaControllSpacing
            Layout.preferredHeight: config_mediaControllItemSize
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 1
            spacing: config_mediaControllSpacing

            Image {
                source: backwardIcon
                sourceSize.width: config_mediaControllItemSize
                sourceSize.height: config_mediaControllItemSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: sendControl("previous")
                }
            }

            Image {
                source: (playbackStatus === "playing") ? pauseIcon : playIcon
                sourceSize.width: config_mediaControllItemSize
                sourceSize.height: config_mediaControllItemSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: sendControl("play_pause")
                }
            }

            Image {
                source: forwardIcon
                sourceSize.width: config_mediaControllItemSize
                sourceSize.height: config_mediaControllItemSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: sendControl("next")
                }
            }

            Image {
                source: liked ? likedIcon : likeIcon
                sourceSize.width: config_mediaControllItemSize
                sourceSize.height: config_mediaControllItemSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: liked = !liked
                }
            }

            Image {
                id: mediaPlayerIcon
                source: config_yesPlayMusicChecked ? cloudMusicIcon : spotifyIcon
                sourceSize.width: config_mediaControllItemSize
                sourceSize.height: config_mediaControllItemSize

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (availablePlayers.length > 0) {
                            var pos = mediaPlayerIcon.mapToGlobal(0, mediaPlayerIcon.height)
                            playerPopup.x = pos.x - playerPopup.width + mediaPlayerIcon.width
                            playerPopup.y = pos.y + 5
                            playerPopup.visible = !playerPopup.visible
                        }
                    }
                }
            }
        }
    }

    PlasmaCore.Dialog {
        id: playerPopup
        location: PlasmaCore.Types.Floating
        type: PlasmaCore.Dialog.PopupMenu
        flags: Qt.WindowStaysOnTopHint
        hideOnWindowDeactivate: true

        mainItem: ListView {
            id: playerList
            width: 250
            height: Math.min(contentHeight, 300)
            model: availablePlayers
            spacing: 2
            clip: true

            delegate: Rectangle {
                width: playerList.width
                height: 36
                color: "transparent"
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: modelData === currentPlayerBusName ? "\u25CF" : "\u25CB"
                        color: modelData === currentPlayerBusName ? "#4CAF50" : "#888"
                        font.pixelSize: 10
                    }

                    Text {
                        text: modelData.replace("org.mpris.MediaPlayer2.", "")
                        color: "white"
                        font.pixelSize: config_lyricTextSize
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: delegateMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        selectedPlayer = modelData
                        playerPopup.visible = false
                    }
                }
            }
        }
    }

    property string backwardIcon: config_whiteMediaControlIconsChecked ? "../assets/media-backward-white.svg" : "../assets/media-backward.svg"
    property string pauseIcon: config_whiteMediaControlIconsChecked ? "../assets/media-pause-white.svg" : "../assets/media-pause.svg"
    property string forwardIcon: config_whiteMediaControlIconsChecked ? "../assets/media-forward-white.svg" : "../assets/media-forward.svg"
    property string likeIcon: config_whiteMediaControlIconsChecked ? "../assets/media-like-white.svg" : "../assets/media-like.svg"
    property string likedIcon: "../assets/media-liked.svg"
    property string cloudMusicIcon: config_whiteMediaControlIconsChecked ? "../assets/netease-cloud-music-white.svg" : "../assets/netease-cloud-music.svg"
    property string spotifyIcon: config_whiteMediaControlIconsChecked ? "../assets/spotify-white.svg" : "../assets/spotify.svg"
    property string playIcon: config_whiteMediaControlIconsChecked ? "../assets/media-play-white.svg" : "../assets/media-play.svg"
    property bool liked: false

    property bool config_yesPlayMusicChecked: Plasmoid.configuration.yesPlayMusicChecked
    property bool config_lxMusicChecked: Plasmoid.configuration.lxMusicChecked
    property bool config_spotifyChecked: Plasmoid.configuration.spotifyChecked
    property bool config_compatibleModeChecked: Plasmoid.configuration.compatibleModeChecked

    property int config_lyricTextSize: Plasmoid.configuration.lyricTextSize
    property int actualFontSize: {
        var baseSize = config_lyricTextSize;
        if (!config_showNextLyric) {
            var maxSingleSize = Math.max(8, Math.floor((lyricTextContainer.height - 6) / 1.25));
            return Math.min(baseSize, maxSingleSize);
        } else {
            var maxCombinedSize = Math.max(8, Math.floor((lyricTextContainer.height - 6) / 2.2));
            return Math.min(baseSize, maxCombinedSize);
        }
    }
    property string config_lyricTextColor: Plasmoid.configuration.lyricTextColor
    property bool config_lyricTextBold: Plasmoid.configuration.lyricTextBold
    property bool config_lyricTextItalic: Plasmoid.configuration.lyricTextItalic
    property int config_lyricTextVerticalOffset: Plasmoid.configuration.lyricTextVerticalOffset
    property int config_lyricTextAlignment: Plasmoid.configuration.lyricTextAlignment

    property int config_mediaControllSpacing: Plasmoid.configuration.mediaControllSpacing
    property int config_mediaControllItemSize: Plasmoid.configuration.mediaControllItemSize
    property int config_mediaControllItemVerticalOffset: Plasmoid.configuration.mediaControllItemVerticalOffset

    property bool config_whiteMediaControlIconsChecked: Plasmoid.configuration.whiteMediaControlIconsChecked
    property int config_preferedWidgetWidth: Plasmoid.configuration.preferedWidgetWidth
    property bool config_hideItemWhenNoControlChecked: Plasmoid.configuration.hideItemWhenNoControlChecked

    property int config_lxMusicPort: Plasmoid.configuration.lxMusicPort

    property bool config_showNextLyric: Plasmoid.configuration.showNextLyric
    property int config_syncOffsetMs: Plasmoid.configuration.syncOffsetMs
    property int config_transitionDurationMs: Plasmoid.configuration.transitionDurationMs
    property double config_nextLyricOpacity: Plasmoid.configuration.nextLyricOpacity
    property string config_nextLyricSeparator: Plasmoid.configuration.nextLyricSeparator

    readonly property string serverHost: "127.0.0.1"
    readonly property int serverPort: 23560

    property string playbackStatus: "stopped"
    property string currentLyric: ""
    property string nextLyric: ""
    property int currentLyricDurationMs: 0
    property int timeRemainingMs: 0
    property string displayedLyric: ""
    property string displayedNextLyric: ""

    property string currentTitle: ""
    property string currentArtist: ""
    property string currentAlbum: ""
    property string currentPlayerIdentity: ""
    property string currentPlayerBusName: ""
    property int positionMs: 0
    property bool hasActivePlayer: false
    property var availablePlayers: []
    property string selectedPlayer: ""
    property int animationDuration: {
        var defaultDuration = Math.max(2000, Math.abs((lyricTextContainer.width - lyricColumn.width) / 50 * 1000));
        if (playbackStatus !== "playing" || timeRemainingMs <= 0) {
            return defaultDuration;
        }
        var adjustedRemaining = timeRemainingMs + config_syncOffsetMs;
        if (adjustedRemaining < 2000) {
            return 1500;
        }
        var targetDuration = (adjustedRemaining - 2000) / 2;
        return Math.max(1500, Math.min(defaultDuration, targetDuration));
    }

    property string requestedPlayer: {
        if (selectedPlayer) {
            return selectedPlayer
        } else if (config_yesPlayMusicChecked) {
            return "org.mpris.MediaPlayer2.yesplaymusic"
        } else if (config_spotifyChecked) {
            return "org.mpris.MediaPlayer2.spotify"
        } else if (config_lxMusicChecked) {
            return "org.mpris.MediaPlayer2.lx-music-desktop"
        } else {
            return ""
        }
    }

    property string lrc_not_exists: {
        if (currentTitle && currentArtist) {
            return currentTitle + " - " + currentArtist
        } else if (currentTitle) {
            return currentTitle
        } else {
            return " "
        }
    }

    Timer {
        id: pollTimer
        interval: 500
        running: pollSocket.status === WebSocket.Open
        repeat: true
        onTriggered: {
            sendPollRequest()
        }
    }

    WebSocket {
        id: pollSocket
        url: "ws://" + serverHost + ":" + serverPort + "/poll"
        active: true

        onStatusChanged: {
            if (pollSocket.status === WebSocket.Open) {
                console.log("Poll WebSocket connected")
                sendPollRequest()
            } else if (pollSocket.status === WebSocket.Closed) {
                console.log("Poll WebSocket closed, reconnecting...")
                hasActivePlayer = false
                currentLyric = ""
                reconnectTimer.start()
            } else if (pollSocket.status === WebSocket.Error) {
                console.log("Poll WebSocket error:", pollSocket.errorString)
                hasActivePlayer = false
                reconnectTimer.start()
            }
        }

        onTextMessageReceived: function(message) {
            try {
                var data = JSON.parse(message)
                handlePollResponse(data)
            } catch (e) {
                console.log("Error parsing poll response:", e)
            }
        }
    }

    WebSocket {
        id: controlSocket
        url: "ws://" + serverHost + ":" + serverPort + "/control"
        active: true

        onStatusChanged: {
            if (controlSocket.status === WebSocket.Open) {
                console.log("Control WebSocket connected")
            } else if (controlSocket.status === WebSocket.Error) {
                console.log("Control WebSocket error:", controlSocket.errorString)
            }
        }

        onTextMessageReceived: function(message) {
            try {
                var data = JSON.parse(message)
                if (!data.success) {
                    console.log("Control command failed")
                }
            } catch (e) {
                console.log("Error parsing control response:", e)
            }
        }
    }

    function sendPollRequest() {
        if (pollSocket.status === WebSocket.Open) {
            var request = { "player": requestedPlayer || null }
            pollSocket.sendTextMessage(JSON.stringify(request))
        }
    }

    Timer {
        id: reconnectTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            if (pollSocket.status !== WebSocket.Open) {
                pollSocket.active = false
                pollSocket.active = true
            }
            if (controlSocket.status !== WebSocket.Open) {
                controlSocket.active = false
                controlSocket.active = true
            }
        }
    }

    onCurrentLyricChanged: {
        triggerTransition()
    }

    onNextLyricChanged: {
        if (!fadeTransitionAnimation.running && !slideTransitionAnimation.running) {
            displayedNextLyric = nextLyric
        }
    }

    onLrc_not_existsChanged: {
        if (!currentLyric) {
            triggerTransition()
        }
    }

    function triggerTransition() {
        if (config_transitionDurationMs <= 0) {
            displayedLyric = currentLyric
            displayedNextLyric = nextLyric
            return
        }

        var canSlide = config_showNextLyric && displayedNextLyric !== "" && currentLyric === displayedNextLyric;
        if (canSlide) {
            slideTransitionAnimation.restart()
        } else {
            fadeTransitionAnimation.restart()
        }
    }

    SequentialAnimation {
        id: fadeTransitionAnimation
        
        PropertyAnimation {
            target: lyricColumn
            property: "opacity"
            to: 0
            duration: config_transitionDurationMs / 2
            easing.type: Easing.InOutQuad
        }
        
        ScriptAction {
            script: {
                displayedLyric = currentLyric
                displayedNextLyric = nextLyric
            }
        }
        
        PropertyAnimation {
            target: lyricColumn
            property: "opacity"
            to: 1
            duration: config_transitionDurationMs / 2
            easing.type: Easing.InOutQuad
        }
    }

    SequentialAnimation {
        id: slideTransitionAnimation
        
        ParallelAnimation {
            NumberAnimation {
                target: currentTranslate
                property: "y"
                from: 0
                to: -4
                duration: config_transitionDurationMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: currentLyricText
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: config_transitionDurationMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: currentLyricText
                property: "scale"
                from: 1.0
                to: 0.8
                duration: config_transitionDurationMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: nextTranslate
                property: "y"
                from: 0
                to: -(currentLyricText.height + lyricColumn.spacing)
                duration: config_transitionDurationMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: nextLyricText
                property: "opacity"
                from: config_nextLyricOpacity
                to: 1.0
                duration: config_transitionDurationMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: nextLyricText
                property: "scale"
                from: 0.8
                to: 1.0
                duration: config_transitionDurationMs
                easing.type: Easing.OutCubic
            }
        }
        
        ScriptAction {
            script: {
                displayedLyric = currentLyric
                displayedNextLyric = nextLyric
                currentTranslate.y = 0
                nextTranslate.y = 0
                currentLyricText.scale = 1.0
                nextLyricText.scale = 0.8
                currentLyricText.opacity = 1.0
                nextLyricText.opacity = config_nextLyricOpacity
                nextLyricFadeIn.restart()
            }
        }
    }

    NumberAnimation {
        id: nextLyricFadeIn
        target: nextLyricText
        property: "opacity"
        from: 0.0
        to: config_nextLyricOpacity
        duration: 150
        easing.type: Easing.OutQuad
    }

    function handlePollResponse(data) {
        if (!data || !data.player) {
            hasActivePlayer = false
            currentLyric = ""
            nextLyric = ""
            currentLyricDurationMs = 0
            timeRemainingMs = 0
            currentTitle = ""
            currentArtist = ""
            currentAlbum = ""
            playbackStatus = "stopped"
            return
        }

        hasActivePlayer = true
        playbackStatus = data.playback_status || "stopped"
        positionMs = data.position_ms || 0

        if (data.player) {
            currentPlayerIdentity = data.player.identity || ""
            currentPlayerBusName = data.player.bus_name || ""
        }

        if (data.track) {
            currentTitle = data.track.title || ""
            currentArtist = data.track.artist || ""
            currentAlbum = data.track.album || ""
        }

        if (data.lyrics) {
            currentLyric = data.lyrics.current_lyric || ""
            nextLyric = data.lyrics.next_lyric || ""
            currentLyricDurationMs = data.lyrics.current_lyric_duration_ms || 0
            timeRemainingMs = data.lyrics.time_remaining_ms || 0
        } else {
            currentLyric = ""
            nextLyric = ""
            currentLyricDurationMs = 0
            timeRemainingMs = 0
        }

        if (data.available_players) {
            availablePlayers = data.available_players
        }
    }

    function sendControl(action) {
        if (controlSocket.status !== WebSocket.Open) {
            console.log("Control socket not connected")
            return
        }
        var request = {
            "action": action,
            "player": requestedPlayer || currentPlayerBusName || null
        }
        controlSocket.sendTextMessage(JSON.stringify(request))
    }
}
