import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // 1. Storage property for the wallpaper directory path
    readonly property string wallpaperDir: Paths.home + "/.config/quickshell/Wallpapers"

    // 2. Process handler to execute 'awww'
    Process {
        id: wallpaperSetter
        command: ["awww", "img", ""] 
        function setWallpaper(path) {
            command = ["awww", "img", path]
            running = true
        }
        onExited: Qt.quit() // Autoclose when done
    }

    // 3. Dynamic Model populated at runtime
    ListModel {
        id: dynamicWallpaperModel
    }

    // 4. Folder Scanner: Runs on launch to detect images
    Process {
        id: folderScanner
        // Searches for files ending in jpg, jpeg, png, or webp
        command: ["find", wallpaperDir, "-type", "f", "-regextype", "posix-extended", "-iregex", ".*\\.(jpg|jpeg|png|webp)$"]
        running: true // Runs instantly when Quickshell starts

        stdout: StdioCollector {
            onStreamFinished: {
                // Split the terminal output into individual lines (file paths)
                let lines = text.trim().split("\n");
                
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "") continue;
                    
                    let absolutePath = lines[i];
                    // Extract just the filename for the display label (e.g., /path/img.png -> img.png)
                    let fileName = absolutePath.substring(absolutePath.lastIndexOf('/') + 1);
                    
                    // Push cleanly into the model
                    dynamicWallpaperModel.append({
                        "name": fileName,
                        "file": "file://" + absolutePath // Prefixed with file:// so QML can render it natively
                    });
                }
            }
        }
    }

    // 5. Interface Layout
    FloatingWindow {
        id: switcherWindow
        title: "Wallpaper Switcher"
        width: 650
        height: 450
        visible: true
        //anchors.centerIn: parent
        
        active: true 
        Component.onCompleted: switcherWindow.forceActiveFocus()
        Keys.onEscapePressed: Qt.quit()

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text {
                    text: "Dynamic Wallpaper Picker"
                    color: "#cdd6f4"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cellWidth: 190
                    cellHeight: 140
                    model: dynamicWallpaperModel
                    clip: true

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                width: 170
                                height: 100
                                radius: 8
                                clip: true
                                color: "#313244"
                                border.color: hoverArea.containsMouse ? "#cba6f7" : "transparent"
                                border.width: 2

                                Image {
                                    anchors.fill: parent
                                    source: model.file
                                    fillMode: Image.PreserveAspectCrop
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        // Strip out file:// prefix to feed a clean system path to awww
                                        let cleanPath = model.file.replace("file://", "");
                                        wallpaperSetter.setWallpaper(cleanPath);
                                    }
                                }
                            }

                            Text {
                                text: model.name
                                color: hoverArea.containsMouse ? "#cba6f7" : "#a6adc8"
                                font.pixelSize: 11
                                elide: Text.ElideRight // Shortens long names neatly with ...
                                Layout.preferredWidth: 160
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}