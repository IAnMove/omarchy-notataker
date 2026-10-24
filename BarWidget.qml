import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Notataker bar icon: one click captures a region and opens the panel
// (Overlay.qml) to tell the agent what to do with it. The hotkey runs the same
// flow (`notataker`).
Panel {
  id: root
  moduleName: "io.github.ianmove.notataker"
  manageIpc: false

  // The script ships with the plugin (bin/notataker): it is found from this very
  // folder, so it works after `omarchy plugin add` without copying anything to ~/.local/bin.
  readonly property string command: decodeURIComponent(Qt.resolvedUrl("bin/notataker").toString().replace(/^file:\/\//, ""))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The picker freezes the screen: wait a moment so the click and the bar
  // tooltip are gone and don't end up in the capture.
  function capture() {
    Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec \"$0\"", root.command])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰹑"   // nf-md-monitor_screenshot
    tooltipText: "Notataker: capture and ask your agent"
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.capture()
    }
  }
}
