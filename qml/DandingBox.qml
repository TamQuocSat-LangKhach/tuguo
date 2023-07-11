// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root
  title.text: Backend.translate("#danding-choose")
  width: 110 + Math.max((hand1.length > 0 ? hand1.length : 0) + (equip1.length > 0 ? equip1.length : 0) + (judge1.length > 0 ? judge1.length : 0), (hand2.length > 0 ? hand2.length : 0) + (equip2.length > 0 ? equip2.length : 0) + (judge2.length > 0 ? judge2.length : 0)) * 100
  height: 50 + ((hand1.length + equip1.length + judge1.length) > 0 ? 150 : 0) + ((hand2.length + equip2.length + judge2.length) > 0 ? 150 : 0)

  property var selected_ids: []

  property string myGeneral: ""
  property string yourGeneral: ""

  property var hand1: []
  property var equip1: []
  property var judge1: []
  property var hand2: []
  property var equip2: []
  property var judge2: []

  Component {
    id: cardDelegate
    CardItem {
      Component.onCompleted: {
        setData(modelData);
      }
      autoBack: false
      selectable: true
      onSelectedChanged: {
        if (selected) {
          origY = origY - 20;
          root.selected_ids.push(cid);
        } else {
          origY = origY + 20;
          root.selected_ids.splice(root.selected_ids.indexOf(cid), 1);
        }
        origX = x;
        goBack(true);
        root.selected_idsChanged();
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 20

    Row {
      height: 130
      spacing: 15
      visible: (hand1.length + equip1.length + judge1.length) > 0

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height

        Text {
          color: "#E4D5A0"
          text: Backend.translate(myGeneral)
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 5
        Repeater {
          id: handcards1
          model: hand1
          delegate: cardDelegate
        }
      }

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height
        visible: equip1.length > 0

        Text {
          color: "#E4D5A0"
          text: Backend.translate("$Equip")
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 5
        visible: equip1.length > 0
        Repeater {
          id: equipment1
          model: equip1
          delegate: cardDelegate
        }
      }

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height
        visible: judge1.length > 0

        Text {
          color: "#E4D5A0"
          text: Backend.translate("$Judge")
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 5
        visible: judge1.length > 0
        Repeater {
          id: judgecard1
          model: judge1
          delegate: cardDelegate
        }
      }
    }

    Row {
      height: 130
      spacing: 15
      visible: (hand2.length + equip2.length + judge2.length) > 0

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height

        Text {
          color: "#E4D5A0"
          text: Backend.translate(yourGeneral)
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 5
        Repeater {
          id: handcards2
          model: hand2
          delegate: CardItem {
            Component.onCompleted: {
              setData(modelData);
            }
            autoBack: false
            known: false
            selectable: true
            onSelectedChanged: {
              if (selected) {
                origY = origY - 20;
                root.selected_ids.push(cid);
              } else {
                origY = origY + 20;
                root.selected_ids.splice(root.selected_ids.indexOf(cid), 1);
              }
              origX = x;
              goBack(true);
              root.selected_idsChanged();
            }
          }
        }
      }

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height
        visible: equip2.length > 0

        Text {
          color: "#E4D5A0"
          text: Backend.translate("$Equip")
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 5
        visible: equip2.length > 0
        Repeater {
          id: equipment2
          model: equip2
          delegate: cardDelegate
        }
      }

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: parent.height
        visible: judge2.length > 0

        Text {
          color: "#E4D5A0"
          text: Backend.translate("$Judge")
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      Row {
        spacing: 5
        visible: judge2.length > 0
        Repeater {
          id: judgecard2
          model: judge2
          delegate: cardDelegate
        }
      }
    }

    Row {
      MetroButton {
        text: Backend.translate("OK")
        enabled: root.selected_ids.length == 2
        onClicked: {
          close();
          ClientInstance.replyToServer("", JSON.stringify(root.selected_ids));
        }
      }
    }
  }

  function loadData(data) {
    const d = data;
    myGeneral = d[0];
    hand1 = d[1].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    equip1 = d[2].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    judge1 = d[3].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    yourGeneral = d[4];
    hand2 = d[5].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    equip2 = d[6].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    judge2 = d[7].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
  }
}

