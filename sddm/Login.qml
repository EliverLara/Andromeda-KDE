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

    signal loginRequest(string username, string password)

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
        loginRequest(username, password);
    }



    //goal is to show the prompts, in ~16 grid units high, then the action buttons
    //but collapse the space between the prompts and actions if there's no room
    //ui is constrained to 16 grid units wide, or the screen
             
    Rectangle {
        anchors.fill: prompts
        color: "#0f0"
        opacity: 0.5
    }


    RowLayout {
        id: prompts
        
        // anchors.verticalCenter: parent.verticalCenter
        // anchors.topMargin: units.gridUnit * 0.5
        // anchors.left: parent.left
        // anchors.right: parent.right
        // anchors.bottom: parent.bottom
        
        anchors.fill: parent
        
        Item {

            id: userListColumn
            
            Layout.fillHeight: true
            
            Layout.fillWidth: true
            
            // Layout.minimumHeight: implicitHeight
            // Layout.maximumWidth: units.gridUnit * 16

            Rectangle {
                anchors.fill: parent
                color: "#ff0"
                opacity: 0.5
            }

            Rectangle {
                width: parent.width - 10
                height: userListView.height
                color: "#f00"
                opacity: 0.5
                radius: 10
                
                anchors.centerIn: userListView
            }

            Rectangle {
                id: userImage
                width: 150
                height: width
                radius: width / 2
                color: "#fff"
                clip: true
                //avatarPath: userListCurrentModelData.icon || ""
        //iconSource: userListCurrentModelData.iconName || "user-identity"
                //Image takes priority, taking a full path to a file, if that doesn't exist we show an icon
                Image {
                    id: face
                    source: userListCurrentModelData.icon || ""
                  //  sourceSize: Qt.size(faceSize, faceSize)
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                }
               anchors.centerIn: parent
               
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



        ColumnLayout {
            Layout.minimumHeight: implicitHeight
            Layout.maximumHeight: units.gridUnit * 10
            Layout.maximumWidth: units.gridUnit * 16
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            ColumnLayout {
                id: innerLayout
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                    Input {
                    id: userNameInput
                    Layout.fillWidth: true
                    text: lastUserName
                    visible: showUsernamePrompt
                    focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Username")

                    onAccepted:
                        if (root.loginScreenUiVisible) {
                            passwordBox.forceActiveFocus()
                        }
                }

                Input {
                    id: passwordBox
                    placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Password")
                    focus: !showUsernamePrompt || lastUserName
                    echoMode: TextInput.Password

                    Layout.fillWidth: true

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
                    text: userListCurrentModelData.realName || userListCurrentModelData.name
                    enabled: passwordBox.text != ""

                    Layout.topMargin: 20
                    Layout.fillWidth: true
                    
                    font.pointSize: config.fontSize
                    font.family: config.font
                        opacity: enabled ? 1.0 : 0.7

                    contentItem: Text {
                        text: loginButton.text
                        font: loginButton.font
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        id: buttonBackground
                        height: parent.width
                        width: height / 9
                        radius: width / 2
                            rotation: -90
                            anchors.centerIn: parent

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#F9D423" }
                            GradientStop { position: 0.33; color: "#FF4E50" }
                            GradientStop { position: 1.0; color: "#8A2387" }
                        }
                    }

                    onClicked: startLogin();
                }
            }

            PlasmaComponents.Label {
                id: notificationsLabel
                Layout.maximumWidth: units.gridUnit * 16
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.italic: true
            }
            Item {
                Layout.fillHeight: true
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }



        Row { //deliberately not rowlayout as I'm not trying to resize child items
            id: actionItemsLayout
            spacing: units.smallSpacing
            Layout.alignment: Qt.AlignHCenter
        }



}
