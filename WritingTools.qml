import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.guruthechosen.translateonthego"

  // Resolve from this checkout so updates and removal need no external links.
  readonly property string launcherPath: decodeURIComponent(
    Qt.resolvedUrl("bin/tot-plugin").toString().replace(/^file:\/\//, ""))

  function launch() {
    Quickshell.execDetached(["bash", root.launcherPath])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "Aa" : "Writing"
    tooltipText: "Writing Tools — translate, proofread, or correct selected text"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.launch()
    }
  }
}
