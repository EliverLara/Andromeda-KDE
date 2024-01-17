import "components"

import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4
import QtQuick.Controls.Styles 1.4

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {

    id: root

        /*
     * Any message to be displayed to the user, visible above the text fields
     */
    property alias notificationMessage: notificationsLabel.text

    /*
     * A list of Items (typically ActionButtons) to be shown in a Row beneath the prompts
     */
    property alias actionItems: actionItemsLayout.children

    /*
     * A model with a list of users to show in the view
     * The following roles should exist:
     *  - name
     *  - iconSource
     *
     * The following are also handled:
     *  - vtNumber
     *  - displayNumber
     *  - session
     *  - isTty
     */
    property alias userListModel: userListView.model

    /*
     * Self explanatory
     */
    property alias userListCurrentIndex: userListView.currentIndex
    property var userListCurrentModelData: userListView.currentItem === null ? [] : userListView.currentItem.m
    property bool showUserList: true

    //property alias userList: userListView

   // default property alias _children: innerLayout.children


    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList

    property string lastUserName
    property bool loginScreenUiVisible: false

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + units.smallSpacing

    signal loginRequest(string username, string password, int sessionIndex)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    /*
    * Login has been requested with the following username and password
    * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
    */
    function startLogin() {
        var username = showUsernamePrompt ? userNameInput.text : userListView.selectedUser
        var password = passwordBox.text

        //this is partly because it looks nicer
        //but more importantly it works round a Qt bug that can trigger if the app is closed with a TextField focused
        //DAVE REPORT THE FRICKING THING AND PUT A LINK
        loginButton.forceActiveFocus();
        loginRequest(username, password, sessionButton.currentIndex);
    }

    // Gets the system time to determinate the correct greeting
    property int hours

    PlasmaCore.DataSource {
        id: timeSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 1000
        onDataChanged: {
            var date = new Date(data["Local"]["DateTime"]);
            hours = date.getHours();
            // minutes = date.getMinutes();
            // seconds = date.getSeconds();
        }
        Component.onCompleted: {
            onDataChanged();
        }
    }

    //goal is to show the prompts, in ~16 grid units high, then the action buttons
    //but collapse the space between the prompts and actions if there's no room
    //ui is constrained to 16 grid units wide, or the screen
             
    RowLayout {
        id: prompts
        
        anchors.fill: parent
        
        // Avatar image and user list column
        Item {
            id: userListColumn
            
            Layout.fillHeight: true  
            Layout.fillWidth: true
            
            UserImage {
                id: userImage
                avatarPath: userListCurrentModelData.icon || ""
                iconSource: userListCurrentModelData.iconName || "user-identity"
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -(userListView.height / 2)
                width: 150
                height: width
            }

            // Semi-transparent border aroud user image
            Rectangle {
                id: userImageBorder
                anchors.fill: userImage
                
                radius: width / 2
                color: "#fff"
                opacity: 0.2
                clip: true
                z: -1
            }

            UserList {
                id: userListView
                visible: showUserList && y > 0
                anchors {
                    top: userImage.bottom
                    left: parent.left
                    right: parent.right
                    margins: height / 2
                }
            }
            
        }


        // Greeting, password and username prompts column
        ColumnLayout {
            Layout.maximumWidth: parent.width / 2
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: 15

            // Greeting Label
            Label {
                id: greetingLabel
                text: hours < 12 ? "Good Morning," : hours < 18 ? "Good Afternoon," : "Good Evening,"
                color: "#fff"
                style: softwareRendering ? Text.Outline : Text.Normal
                styleColor: softwareRendering ? ColorScope.backgroundColor : "transparent" //no outline, doesn't matter
                font.pointSize:24 
                Layout.alignment: Qt.AlignLeft
                font.family: config.font
                font.bold: true
            }
            // Display username below the greeting label to correctly manage the label size in case that User-Name isn't available
            Label {
                id: userNameLabel
                Layout.fillWidth: true
                Layout.topMargin: -20
                text: userListCurrentModelData.realName || userListCurrentModelData.name
                color: "#fff"
                style: softwareRendering ? Text.Outline : Text.Normal
                styleColor: softwareRendering ? ColorScope.backgroundColor : "transparent" //no outline, doesn't matter
                font.pointSize: userListCurrentModelData.realName ? 24 : 14
                Layout.alignment: Qt.AlignLeft
                font.family: config.font
                font.bold: true
                wrapMode: Text.WordWrap
            }

            // User name input in case user is not included in user-list
            Input {
                id: userNameInput
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: lastUserName
                visible: showUsernamePrompt
                focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
                Layout.topMargin: 20
                placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Username")

                onAccepted:
                    if (root.loginScreenUiVisible) {
                        passwordBox.forceActiveFocus()
                    }
            }

            // Passwrod and login button row
            RowLayout {
                
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.rightMargin: 30

                Input {
                    id: passwordBox
                    placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Password")
                    focus: !showUsernamePrompt || lastUserName
                    echoMode: TextInput.Password

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    onAccepted: {
                        if (root.loginScreenUiVisible) {
                            startLogin();
                        }
                    }

                    Keys.onEscapePressed: {
                        mainStack.currentItem.forceActiveFocus();
                    }

                    //if empty and left or right is pressed change selection in user switch
                    //this cannot be in keys.onLeftPressed as then it doesn't reach the password box
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Left && !text) {
                            userListView.decrementCurrentIndex();
                            event.accepted = true
                        }
                        if (event.key == Qt.Key_Right && !text) {
                            userListView.incrementCurrentIndex();
                            event.accepted = true
                        }
                    }

                    Connections {
                        target: sddm
                        onLoginFailed: {
                            passwordBox.selectAll()
                            passwordBox.forceActiveFocus()
                        }
                    }
                }

                Button {
                    id: loginButton
                    enabled: passwordBox.text != ""

                    Layout.preferredHeight: passwordBox.height
                    Layout.preferredWidth: text.length === 0 ? loginButton.Layout.preferredHeight : -1
                    Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Log In")

                    font.pointSize: config.fontSize
                    font.family: config.font

                    icon.name: text.length === 0 ? (root.LayoutMirroring.enabled ? "go-previous" : "go-next") : ""
                    icon.color: enabled ? "#fff" : "#666666"

                    text: root.showUsernamePrompt || userList.currentItem.needsPassword ? "" : i18n("Log In")
                    background: Rectangle {
                        id: buttonBackground
                        radius: 8
                        anchors.fill: parent
                        color: enabled ? "#fff" : "#ADADAD"
                        opacity: 0.1
                    }

                    onClicked: startLogin();
                }
                
            }

            // Notifications - login state label
            PlasmaComponents.Label {
                id: notificationsLabel
                Layout.maximumWidth: units.gridUnit * 16
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.italic: true
            }

            RowLayout {
                id: footer

                Layout.alignment: Qt.AlignHCenter

                Behavior on opacity {
                    OpacityAnimator {
                        duration: units.longDuration
                    }
                }

                PlasmaComponents.ToolButton {
                    // text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                    iconName: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                    onClicked: inputPanel.showHide()
                    visible: inputPanel.status == Loader.Ready
                }

                KeyboardButton {
                }

                SessionButton {
                    id: sessionButton
                }
            }
        }

    }

    Row { //deliberately not rowlayout as I'm not trying to resize child items
        id: actionItemsLayout
        spacing: units.smallSpacing
            
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: height / 2
    }

}
