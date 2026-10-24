import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls          // before qs.Ui, so Button is Omarchy's
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Notataker panel: a thumbnail of the capture, a text box to tell the agent
// what to do with it, and one-click shortcuts for the most common requests.
// `notataker` (bin/notataker) opens it with summon and gets the text back
// through `notataker --send`, which builds the prompt and launches Omarchy's agent.
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string image: ""
  property string notesDir: ""
  property string agent: ""
  property string bin: ""

  readonly property color foreground: Color.menu.text
  readonly property color background: Color.menu.background
  readonly property color border: Color.menu.border
  readonly property color scrim: Color.menu.scrim
  readonly property color muted: Util.alpha(foreground, 0.6)
  readonly property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  readonly property int contentMargin: Style.spacing.panelPadding
  readonly property int cardWidth: Math.min(Style.space(640), panel.width - Style.gapsOut * 2)
  readonly property string command: root.bin !== "" ? root.bin : Quickshell.env("HOME") + "/.local/bin/notataker"

  // One-click requests. They fill the text box instead of sending right away,
  // so they can be tweaked before going out.
  readonly property var presets: [
    { label: "Transcribe to my notes", text: "Transcribe the content of the screenshot and save it to my notes." },
    { label: "Translate", text: "Translate the text in the screenshot into " },
    { label: "Explain", text: "Explain what is in the screenshot." },
    { label: "Summarize", text: "Summarize the content of the screenshot in a few bullet points." },
    { label: "Build this", text: "Build what you see in the screenshot: " }
  ]

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
    root.image = String(payload.image || "")
    root.notesDir = String(payload.notesDir || "")
    root.agent = String(payload.agent || "")
    root.bin = String(payload.bin || "")
    input.text = ""
    root.opened = true
    Qt.callLater(function() { input.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.ianmove.notataker")
  }

  // Cancelling also throws the capture away: with no request there is nothing to send.
  function cancel() {
    if (root.image !== "") Quickshell.execDetached([root.command, "--discard", root.image])
    root.dismiss()
  }

  function submit() {
    var text = input.text.trim()
    if (text === "" || root.image === "") return
    Quickshell.execDetached([root.command, "--send", root.image, text])
    root.dismiss()
  }

  function applyPreset(text) {
    input.text = input.text.trim() === "" ? text : input.text.replace(/\s+$/, "") + "\n" + text
    input.forceActiveFocus()
    input.cursorPosition = input.length
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-notataker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    // A click outside cancels, but only while nothing is typed: losing a
    // half-written request to a stray click is worse than having to press Esc.
    MouseArea {
      anchors.fill: parent
      onClicked: if (input.text.trim() === "") root.cancel()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(column.implicitHeight + card.contentTopInset + card.contentBottomInset,
                       panel.height - Style.gapsOut * 2)
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }

      ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.space(12)

        Text {
          Layout.fillWidth: true
          textFormat: Text.PlainText
          text: "Notataker"
          color: root.foreground
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.heading
          font.bold: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(230)
          radius: Style.cornerRadius
          color: Util.alpha(root.foreground, 0.06)
          clip: true

          Image {
            id: thumb
            anchors.fill: parent
            anchors.margins: Style.space(6)
            source: Util.fileUrl(root.image)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            // Bound the texture: a 4K capture doesn't need 33 MB for a thumbnail.
            sourceSize.width: 1600
            sourceSize.height: 900
          }

          Text {
            anchors.centerIn: parent
            visible: thumb.status === Image.Error
            text: "Couldn't show the screenshot"
            color: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Repeater {
            model: root.presets

            Button {
              required property var modelData
              text: modelData.label
              bordered: true
              fontFamily: Style.font.menuFamily
              onClicked: root.applyPreset(modelData.text)
            }
          }
        }

        ScrollView {
          id: scroll
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(96)
          clip: true

          background: BorderSurface {
            radius: Style.cornerRadius
            color: Style.controlFill(input.activeFocus, false, root.foreground, Color.accent)
            borderSpec: Border.controlSpec(input.activeFocus ? "focus" : "normal", root.foreground, Color.accent)
          }

          TextArea {
            id: input
            wrapMode: TextArea.Wrap
            color: root.foreground
            selectionColor: Style.selectionFillFor(root.foreground, Color.accent)
            selectedTextColor: root.foreground
            placeholderText: "What should I do with the screenshot?   Enter sends · Shift+Enter new line"
            placeholderTextColor: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
            padding: Style.spacing.controlPaddingX
            background: null

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.cancel()
                event.accepted = true
              } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                         && !(event.modifiers & Qt.ShiftModifier)) {
                root.submit()
                event.accepted = true
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            text: (root.agent !== "" ? "Agent: " + root.agent : "No default agent")
                  + (root.notesDir !== "" ? "  ·  Notes: " + root.notesDir : "")
            color: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            text: "Cancel (Esc)"
            fontFamily: Style.font.menuFamily
            onClicked: root.cancel()
          }

          Button {
            text: "Send (Enter)"
            bordered: true
            selected: true
            fontFamily: Style.font.menuFamily
            onClicked: root.submit()
          }
        }
      }
    }
  }
}
