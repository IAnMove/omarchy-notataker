import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Icono de Notataker en la barra: un clic captura una zona y abre el panel
// (Overlay.qml) para decirle al agente qué hacer con ella. El mismo flujo se
// lanza con el atajo de teclado (`notataker`).
Panel {
  id: root
  moduleName: "io.github.ianmove.notataker"
  manageIpc: false

  // El script viaja con el plugin (bin/notataker): se localiza desde esta misma
  // carpeta, así funciona tras `omarchy plugin add` sin copiar nada a ~/.local/bin.
  readonly property string command: decodeURIComponent(Qt.resolvedUrl("bin/notataker").toString().replace(/^file:\/\//, ""))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // El selector congela la pantalla: se espera un momento a que el clic y el
  // tooltip de la barra desaparezcan para que no salgan en la captura.
  function capture() {
    Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec \"$0\"", root.command])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰹑"   // nf-md-monitor_screenshot
    tooltipText: "Notataker: captura y pídele algo al agente"
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.capture()
    }
  }
}
