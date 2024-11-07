import QtQuick 2.14
import QtQuick.Window 2.14
import QtLocation 5.14
import QtPositioning 5.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.0
import ElevationReader 1.0
import AStar 1.0
import ACO 1.0

Window {
    visible: true
    width: 1024
    height: 720
    title: qsTr("UAV path planning")

    //Biến kiểm soát hiển thị thanh slider
    property bool slidersVisible: false
    property bool isSelectingStartCoordinate: false
    property bool isSelectingGoalCoordinate: false
    // Biến để lưu tọa độ điểm bắt đầu và điểm đến
    property double startLat: 0.0
    property double startLon: 0.0
    property double goalLat: 0.0
    property double goalLon: 0.0
    property double uavAltitude: 0.0
    property string selectedAlgorithm: "AStar"

     Map {
            id: map
            anchors.fill: parent

            plugin: Plugin {
                name: "mapboxgl"

                PluginParameter {
                    name: "mapboxgl.mapping.use_fbo"
                    value: true
                }

                PluginParameter {
                    name: "mapboxgl.mapping.items.insert_before"
                    value: "aerialway"
                }
            }

            center: QtPositioning.coordinate(21.0313350, 105.8133596) // Hà Nội
            zoomLevel: 14
            minimumZoomLevel: 0
            maximumZoomLevel: 20
            tilt: tiltSlider.value
            bearing: bearingSlider.value

            // Layer các tòa nhà 3d
            MapParameter {
                type: "layer"

                property var name: "3d-buildings"
                property var source: "composite"
                property var sourceLayer: "building"
                property var layerType: "fill-extrusion"
                property var minzoom: 15
            }

            MapParameter {
                type: "filter"

                property var layer: "3d-buildings"
                property var filter: [ "==", "extrude", "true" ]
            }

            MapParameter {
                type: "paint"

                property var layer: "3d-buildings"
                property var fillExtrusionColor: "#00617f"
                property var fillExtrusionOpacity: 0.7 //Độ trong suốt của tòa nhà
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "min_height" } }
            }

            // Khu vực cấm bay
            // bán kính 1km từ nhà quốc hội
            MapParameter {
                id: obstacle1
                type: "source"
                property var name: "nha-quoc-hoi-source"
                property var sourceType: "geojson"
                property var data: ":/geojson-file/nha-quoc-hoi-1km.geojson"
            }

            // Thêm layer fill-extrusion để vẽ hình trụ
            MapParameter {
                type: "layer"
                property var name: "nha-quoc-hoi-layer"
                property var source: "nha-quoc-hoi-source"
                property var layerType: "fill-extrusion"
                property var minzoom: 0
            }

            // Thiết lập paint properties cho layer hình trụ
            MapParameter {
                type: "paint"
                property var layer: "nha-quoc-hoi-layer"
                property var fillExtrusionColor: "red"
                property var fillExtrusionOpacity: 0.5
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "base_height" } }
            }

            //bán kính 0.5 km từ bệnh viện y học cổ truyền
            MapParameter {
                id: obstacle2
                type: "source"
                property var name: "bo-tu-lenh-source"
                property var sourceType: "geojson"
                property var data: ":/geojson-file/benh-vien-y-hoc-co-truyen-0.5km.geojson"
            }

            // Thêm layer fill-extrusion để vẽ hình trụ
            MapParameter {
                type: "layer"
                property var name: "bo-tu-lenh-layer"
                property var source: "bo-tu-lenh-source"
                property var layerType: "fill-extrusion"
                property var minzoom: 0
            }

            // Thiết lập paint properties cho layer hình trụ
            MapParameter {
                type: "paint"
                property var layer: "bo-tu-lenh-layer"
                property var fillExtrusionColor: "red"
                property var fillExtrusionOpacity: 0.5
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "base_height" } }
            }

            // Bán kính 1km từ bộ công an
            MapParameter {
                id: obstacle3
                type: "source"
                property var name: "bo-cong-an-source"
                property var sourceType: "geojson"
                property var data: ":/geojson-file/bo-cong-an-1km.geojson"
            }

            // Thêm layer fill-extrusion để vẽ hình trụ
            MapParameter {
                type: "layer"
                property var name: "bo-cong-an-layer"
                property var source: "bo-cong-an-source"
                property var layerType: "fill-extrusion"
                property var minzoom: 0
            }

            // Thiết lập paint properties cho layer hình trụ
            MapParameter {
                type: "paint"
                property var layer: "bo-cong-an-layer"
                property var fillExtrusionColor: "red"
                property var fillExtrusionOpacity: 0.5
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "base_height" } }
            }

            // Bán kính 0.5km từ bộ công thương
            MapParameter {
                id: obstacle4
                type: "source"
                property var name: "bo-cong-thuong-source"
                property var sourceType: "geojson"
                property var data: ":/geojson-file/bo-cong-thuong-0.5km.geojson"
            }

            // Thêm layer fill-extrusion để vẽ hình trụ
            MapParameter {
                type: "layer"
                property var name: "bo-cong-thuong-layer"
                property var source: "bo-cong-thuong-source"
                property var layerType: "fill-extrusion"
                property var minzoom: 0
            }

            // Thiết lập paint properties cho layer hình trụ
            MapParameter {
                type: "paint"
                property var layer: "bo-cong-thuong-layer"
                property var fillExtrusionColor: "red"
                property var fillExtrusionOpacity: 0.5
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "base_height" } }
            }

            // Bán kính 0.5km từ bv 108
            MapParameter {
                id: obstacle5
                type: "source"
                property var name: "bv-108-source"
                property var sourceType: "geojson"
                property var data: ":/geojson-file/bv-108-0.5km.geojson"
            }

            // Thêm layer fill-extrusion để vẽ hình trụ
            MapParameter {
                type: "layer"
                property var name: "bv-108-layer"
                property var source: "bv-108-source"
                property var layerType: "fill-extrusion"
                property var minzoom: 0
            }

            // Thiết lập paint properties cho layer hình trụ
            MapParameter {
                type: "paint"
                property var layer: "bv-108-layer"
                property var fillExtrusionColor: "red"
                property var fillExtrusionOpacity: 0.5
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "base_height" } }
            }

            // Bán kính 0.5km từ học viện quốc phòng
            MapParameter {
                id: obstacle6
                type: "source"
                property var name: "hv-quoc-phong-source"
                property var sourceType: "geojson"
                property var data: ":/geojson-file/hoc-vien-quoc-phong-0.5km.geojson"
            }

            // Thêm layer fill-extrusion để vẽ hình trụ
            MapParameter {
                type: "layer"
                property var name: "hv-quoc-phong-layer"
                property var source: "hv-quoc-phong-source"
                property var layerType: "fill-extrusion"
                property var minzoom: 0
            }

            // Thiết lập paint properties cho layer hình trụ
            MapParameter {
                type: "paint"
                property var layer: "hv-quoc-phong-layer"
                property var fillExtrusionColor: "red"
                property var fillExtrusionOpacity: 0.5
                property var fillExtrusionHeight: { return { type: "identity", property: "height" } }
                property var fillExtrusionBase: { return { type: "identity", property: "base_height" } }
            }

            // Ghim icon và cập nhật tọa độ cùng độ cao trên bản đồ
            MouseArea {
                id: mapMouseArea
                anchors.fill: parent
                onClicked: {

                    var clickedCoordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y));
                    var latitude = clickedCoordinate.latitude;
                    var longitude = clickedCoordinate.longitude;
                    var elevation = readHGT.getElevation(latitude, longitude);

                    if (isSelectingStartCoordinate) {
                        startLatField.text = clickedCoordinate.latitude.toFixed(7);
                        startLonField.text = clickedCoordinate.longitude.toFixed(7);
                        isSelectingStartCoordinate = false;
                        notification.visible = false;
                    } else if (isSelectingGoalCoordinate) {
                        endLatField.text = clickedCoordinate.latitude.toFixed(7);
                        endLonField.text = clickedCoordinate.longitude.toFixed(7);
                        isSelectingGoalCoordinate = false;
                        notification.visible = false;
                    }

                    // Cập nhật tọa độ và độ cao hiển thị trong ô
                    latLonDisplay.text = "Latitude: " + latitude.toFixed(7) + ", Longitude: " + longitude.toFixed(7) + ", Elevation: " + elevation + " meters";
                    latLonDisplayBox.visible = true

                    // Cập nhật tọa độ pin và hiển thị pin icon
                    pinIcon.coordinate = clickedCoordinate
                    pinIcon.visible = true
                }
            }

            // Icon sẽ xuất hiện tại vị trí người dùng nhấn
            MapQuickItem {
                id: pinIcon
                anchorPoint.x: icon.width / 2
                anchorPoint.y: icon.height
                coordinate: QtPositioning.coordinate(0, 0)  // Tọa độ mặc định
                visible: false

                sourceItem: Image {
                    id: icon
                    source: "qrc:/png/pinIcon.png"
                    width: 32
                    height: 32
                }
            }

            MapQuickItem {
                id: startMarker
                visible: false

                sourceItem: Image {
                    id: greenMarker
                    source: "qrc:/png/marker-green.png"
                }

                coordinate : QtPositioning.coordinate(startLat, startLon)
                anchorPoint.x: greenMarker.width / 2
                anchorPoint.y: greenMarker.height
            }

            MapQuickItem {
                id: endMarker

                sourceItem: Image {
                    id: redMarker
                    source: "qrc:/png/marker-red.png"
                }

                coordinate : QtPositioning.coordinate(goalLat, goalLon)
                anchorPoint.x: redMarker.width / 2
                anchorPoint.y: redMarker.height
            }

            MapQuickItem {
                id: uavModel

                // Item chứa UAV và Text
                sourceItem: Item {
                    width: 40
                    height: 60 // Đảm bảo đủ không gian cho text

                    // Hình ảnh UAV
                    Image {
                        id: uavImage
                        source: "qrc:/png/drone.png"
                        width: 40
                        height: 40
                    }

                    // Hiển thị độ cao phía trên UAV
                    Text {
                        id: elevationText
                        text: "Elevation: 0m"
                        color: "black"
                        font.pixelSize: 12
                        anchors.horizontalCenter: uavImage.horizontalCenter
                        y: -20 // Đặt Text trên đầu UAV
                        visible: true
                    }
                }

                // Tọa độ UAV
                coordinate: QtPositioning.coordinate(startLat, startLon)

                // Đặt điểm neo cho UAV
                anchorPoint.x: uavImage.width / 2
                anchorPoint.y: uavImage.height / 2
            }

            //Đường bay
            MapPolyline {
                id: pathLine
                line.width: 5
                line.color: 'blue'
            }

            // Hiển thị độ cao tòa nhà
            ListModel {
                id: areaModel
                // Khu vực cấm bay
                ListElement { latitude: 21.0485743; longitude: 105.7800104; height: 100 } // Vùng cấm bay bộ công an
                ListElement { latitude: 21.0338809; longitude: 105.7795177; height: 100 } // Vùng cấm bay bệnh viện y học cổ truyền
                ListElement { latitude: 21.0440653; longitude: 105.8018651; height: 50 } // Vùng cấm bay học viện quốc phòng
                ListElement { latitude: 21.0372747; longitude: 105.8371396; height: 100 } // Vùng cấm bay tòa nhà quốc hội
                ListElement { latitude: 21.0260690; longitude: 105.8480420; height: 50 } // Vùng cấm bay bộ công thương
                ListElement { latitude: 21.0183784; longitude: 105.8603403; height: 50 } // Vùng cấm bay bv 108

                // Các tòa nhà cao tầng
                ListElement { latitude: 21.0167251; longitude: 105.7841804; height: 336 } // AON Hanoi Landmark Tower 336m
                ListElement { latitude: 21.0321836; longitude: 105.8126368; height: 267 } // Lotte Center 267m
                ListElement { latitude: 21.0182555; longitude: 105.7841261; height: 212 } // AON Landmark Residential Tower A 212m
                ListElement { latitude: 21.0176241; longitude: 105.7833234; height: 212 } // AON Landmark Residential Tower B 212m
                ListElement { latitude: 21.0054152; longitude: 105.8039347; height: 176 } // Diamond flower tower 176m
                ListElement { latitude: 21.0240257; longitude: 105.7902456; height: 173 } // Golden Park cầu giấy 173m
                ListElement { latitude: 21.0216479; longitude: 105.7894814; height: 167 } // Vinacomin Tower 167m
                ListElement { latitude: 21.0053478; longitude: 105.8057048; height: 159 } // BRG Diamond Residence 159m
                ListElement { latitude: 21.0038823; longitude: 105.7943412; height: 142 } // D'capitale C1 142m
                ListElement { latitude: 21.0044640; longitude: 105.7941894; height: 158 } // D'capitale C2 158m
                ListElement { latitude: 21.0050972; longitude: 105.7943238; height: 148 } // D'capitale C3 148m
                ListElement { latitude: 21.0058359; longitude: 105.7946772; height: 165 } // D'capitale C5 165m
                ListElement { latitude: 21.0064294; longitude: 105.7952854; height: 158 } // D'capitale C6 158m
                ListElement { latitude: 21.0068491; longitude: 105.7959166; height: 158 } // D'capitale C7 158m
                ListElement { latitude: 21.0023280; longitude: 105.7920670; height: 152 } // Thăng Long Number One A 152m
                ListElement { latitude: 21.0029783; longitude: 105.7930751; height: 152 } // Thăng Long Number One B 152m
                ListElement { latitude: 21.0201724; longitude: 105.7809074; height: 151 } // VinHome SkyLake 1 151m
                ListElement { latitude: 21.0198623; longitude: 105.7815959; height: 151 } // VinHome SkyLake 2 151m
                ListElement { latitude: 21.0197360; longitude: 105.7829264; height: 151 } // VinHome SkyLake 3 151m
                ListElement { latitude: 21.0091010; longitude: 105.7933277; height: 150 } // CT4 Vimeco 150m
                ListElement { latitude: 21.0167373; longitude: 105.7817838; height: 140 } // Handico Tower 140m
                ListElement { latitude: 21.0082461; longitude: 105.8029051; height: 136 } // 34T Trung Hòa 136, từng cao nhất đến khi xây Landmark
                ListElement { latitude: 21.0253005; longitude: 105.7879615; height: 130 } // Viện kiểm sát nhân dân tối cao 130m
                ListElement { latitude: 21.0085313; longitude: 105.7961842; height: 123 } // The Summit 123m
            }

            Repeater {
                model: areaModel
                delegate: MapQuickItem {
                    coordinate: QtPositioning.coordinate(model.latitude, model.longitude)
                    anchorPoint.x: buildingRectangle.width / 2
                    anchorPoint.y: buildingRectangle.height / 2

                    visible: map.zoomLevel >= 16

                    sourceItem: Item {
                        Rectangle {
                            id: buildingRectangle
                            width: 30
                            height: 30
                            color: "transparent"

                            Text {
                                id: heightText
                                text: model.height +"m"
                                font.pointSize: 11
                                anchors.centerIn: parent
                                color: "black"
                            }
                        }
                    }
                }
            }


            //Góc nghiêng theo phương đứng
            Slider {
                id: tiltSlider
                anchors.left: parent.left
                anchors.top: parent.top
                width: parent.width / 2
                from: 0
                to: 60
                value: 0
                visible: slidersVisible
                onValueChanged: {
                    map.tilt = value
                }
            }

            //xoay theo hướng bắc
            Slider {
                id: bearingSlider
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 30
                width: parent.width / 2
                from: 0
                to: 360
                value: 0
                visible: slidersVisible
                onValueChanged: {
                    map.bearing = value
                }
            }
        }

     AStar {
         id: aStar
     }

     ACO {
         id: aco
     }

     ElevationReader {
         id: readHGT
     }

     //Hiển thị lat lon alt
     //Hiển thị lat lon alt
     Rectangle {
         id: latLonDisplayBox
         width: latLonDisplay.implicitWidth + 10  // Tự động điều chỉnh chiều rộng theo text
         height: latLonDisplay.implicitHeight + 5  // Tự động điều chỉnh chiều cao theo text
         color: "white"
         border.color: "black"
         anchors.bottom: parent.bottom
         anchors.bottomMargin: 30

         TextField {
             id: latLonDisplay
             color: "black"
             anchors.centerIn: parent
             readOnly: true
             selectByMouse: true
             background: Rectangle {
                 color: "transparent"  // Đảm bảo không có nền phía sau text
             }
         }

         visible: false
     }

     //Các nút chức năng
     Rectangle {
         id: bottomBar
         color: "white"
         height: 30
         width: parent.width
         anchors.bottom: parent.bottom
         anchors.horizontalCenter: parent.horizontalCenter

         Row {
             anchors.bottom: parent.bottom
             anchors.horizontalCenter: parent.horizontalCenter
             spacing: 30

             Button {
                 height: 30
                 width: 80
                 background: Rectangle {
                     id: findBackground
                     color: "white"
                     border.color: "black"
                     radius: 4

                     // Tạo hiệu ứng khi ấn
                     MouseArea {
                         id: findPath
                         anchors.fill: parent
                         onPressedChanged: {
                             if (findPath.pressed) {
                                 findBackground.color = "lightgray";
                             } else {
                                 findBackground.color = "white";
                             }
                         }
                         onClicked: {
                             inputBox.visible = !inputBox.visible
                         }
                     }
                 }

                 contentItem: Text {
                     text: "Find Path"
                     color: "black"
                     horizontalAlignment: Text.AlignHCenter // Align text horizontally
                     verticalAlignment: Text.AlignVCenter   // Align text vertically
                     anchors.centerIn: parent               // Center the text in the button
                 }
             }

             Button {
                 height: 30
                 width: 80
                 background: Rectangle {
                     id: moveBackground
                     color: "white"
                     border.color: "black"
                     radius: 4

                     MouseArea {
                         id: moveButton
                         anchors.fill: parent
                         onPressedChanged: {
                             if (moveButton.pressed) {
                                 moveBackground.color = "lightgray"; // Màu khi nhấn
                             } else {
                                 moveBackground.color = "white"; // Màu khi thả ra
                             }
                         }
                         onClicked: {
                             startMarker.visible = true;
                             animateUAV(pathLine.path);
                         }
                     }
                 }

                 contentItem: Text {
                     text: "Move"
                     color: "black"
                     horizontalAlignment: Text.AlignHCenter // Align text horizontally
                     verticalAlignment: Text.AlignVCenter   // Align text vertically
                     anchors.centerIn: parent               // Center the text in the button
                 }
             }

             Button {
                 height: 30
                 width: 80
                 background: Rectangle {
                     id: resetBackground
                     color: "white"
                     border.color: "black"
                     radius: 4

                     MouseArea {
                         id: resetButton
                         anchors.fill: parent
                         onPressedChanged: {
                             if (resetButton.pressed) {
                                 resetBackground.color = "lightgray"; // Màu khi nhấn
                             } else {
                                 resetBackground.color = "white"; // Màu khi thả ra
                             }
                         }
                         onClicked: {
                             reset();
                         }
                     }
                 }

                 contentItem: Text {
                     text: "Reset"
                     color: "black"
                     horizontalAlignment: Text.AlignHCenter // Align text horizontally
                     verticalAlignment: Text.AlignVCenter   // Align text vertically
                     anchors.centerIn: parent               // Center the text in the button
                 }
             }
         }
     }

     //Nút ẩn hiện thanh xoay
     Button {
         height: 30
         width: 100
         anchors.top: parent.top
         anchors.right: parent.right
         background: Rectangle {
             id: rotationBackground
             color: "white"
             border.color: "black"
             radius: 4

             MouseArea {
                 id: rotation
                 anchors.fill: parent
                 onPressedChanged: {
                     if (rotation.pressed) {
                         rotationBackground.color = "lightgray"; // Màu khi nhấn
                     } else {
                         rotationBackground.color = "white"; // Màu khi thả ra
                     }
                 }
                 onClicked: {
                     slidersVisible = !slidersVisible; // Đổi trạng thái ẩn/hiện của sliders
                 }
             }
         }

         contentItem: Text {
             text: slidersVisible ? "Rotation Enable" : "Rotation Disable"
             color: "black"
             horizontalAlignment: Text.AlignHCenter
             verticalAlignment: Text.AlignVCenter
             anchors.centerIn: parent
         }
     }

     //Dữ liệu đầu vào
     Rectangle {
         id: inputBox
         color: "white"
         border.color: "black"
         height: 560
         width: 480
         x: (parent.width - width) / 2  // Đặt ban đầu ở giữa màn hình
         y: (parent.height - height) / 2 // Đặt ban đầu ở giữa màn hình
         visible: false

         // Cho phép người dùng di chuyển inputBox
         MouseArea {
             id: dragArea
             anchors.fill: parent
             drag.target: inputBox
             drag.axis: Drag.XAndYAxis
             cursorShape: Qt.OpenHandCursor

             onPressed: {
                 dragArea.cursorShape = Qt.ClosedHandCursor;
             }
             onReleased: {
                 dragArea.cursorShape = Qt.OpenHandCursor;
             }
         }

         // Cập nhật cho phép kéo thả
         Drag.active: dragArea.drag.active
         Drag.hotSpot.x: dragArea.width / 2
         Drag.hotSpot.y: dragArea.height / 2

         Column {
             anchors.centerIn: parent
             spacing: 20

             // Tọa độ điểm bắt đầu
             Text {
                 text: "Start coordinate:"
                 color: "black"
                 anchors.horizontalCenter: parent.horizontalCenter
             }
             Row {
                 spacing: 10
                 anchors.horizontalCenter: parent.horizontalCenter
                 TextField {
                     id: startLatField
                     placeholderText: "Latitude"
                     width: 150
                     selectByMouse: true  // Cho phép chọn và copy
                     onTextChanged: {
                         startLat = parseFloat(text) // Cập nhật giá trị cho biến startLat
                     }
                 }
                 TextField {
                     id: startLonField
                     placeholderText: "Longitude"
                     width: 150
                     selectByMouse: true
                     onTextChanged: {
                         startLon = parseFloat(text) // Cập nhật giá trị cho biến startLon
                     }
                 }
             }

             // Tọa độ điểm đến
             Text {
                 text: "Goal coordinate:"
                 color: "black"
                 anchors.horizontalCenter: parent.horizontalCenter
             }

             Row {
                 spacing: 10
                 anchors.horizontalCenter: parent.horizontalCenter
                 TextField {
                     id: endLatField
                     placeholderText: "Latitude"
                     width: 150
                     selectByMouse: true
                     onTextChanged: {
                         goalLat = parseFloat(text) // Cập nhật giá trị cho biến goalLat
                     }
                 }
                 TextField {
                     id: endLonField
                     placeholderText: "Longitude"
                     width: 150
                     selectByMouse: true
                     onTextChanged: {
                         goalLon = parseFloat(text) // Cập nhật giá trị cho biến goalLon
                     }
                 }
             }

             // Thêm ô nhập độ cao UAV
             Text {
                 text: "UAV altitude:"
                 color: "black"
                 anchors.horizontalCenter: parent.horizontalCenter
             }
             Row {
                 spacing: 10
                 anchors.horizontalCenter: parent.horizontalCenter
                 TextField {
                     id: uavAltitudeField
                     placeholderText: "Altitude (meters)"
                     width: 150
                     selectByMouse: true
                     onTextChanged: {
                         uavAltitude = parseFloat(text) // Cập nhật giá trị cho biến uavAltitude
                     }
                 }
             }

             // Lựa chọn thuật toán
             Text {
                 text: "Select Algorithm:"
                 color: "black"
                 anchors.horizontalCenter: parent.horizontalCenter
             }

             ComboBox {
                 id: algorithmSelector
                 width: 200
                 anchors.horizontalCenter: parent.horizontalCenter
                 model: ["AStar", "ACO"]  // Hai lựa chọn cho thuật toán
                 currentIndex: 0  // Mặc định là Astar
                 // Sử dụng onActivated để đảm bảo giá trị chính xác khi thay đổi lựa chọn
                 onActivated: function(index) {
                     selectedAlgorithm = algorithmSelector.model[index]; // Cập nhật giá trị theo model
                     console.log("Selected Algorithm: " + selectedAlgorithm); // In ra giá trị để kiểm tra
                 }
             }

             // Hiển thị thông báo lỗi
             Text {
                 id: errorMessage
                 text: ""
                 color: "red"
                 visible: false
             }
             // Hiển thị thông báo
             Text {
                 id: notification
                 text: ""
                 color: "black"
                 visible: false
             }

             Button {
                 id: enterButton
                 text: "Enter"
                 height: 30
                 width: 50
                 anchors.horizontalCenter: parent.horizontalCenter

                 background: Rectangle {
                     id: enterBackground
                     color: "white"
                     border.color: "black"
                     radius: 4

                     // Tạo hiệu ứng khi ấn
                     MouseArea {
                         id: enterClick
                         anchors.fill: parent
                         onPressedChanged: {
                             if (enterClick.pressed) {
                                 enterBackground.color = "lightgray"; // Màu khi nhấn
                             } else {
                                 enterBackground.color = "white"; // Màu khi thả
                             }
                        }
                         onClicked: {
                             // Cập nhật độ cao
                             elevationText.text = "Elevation: " + uavAltitude + "m";
                             // Kiểm tra dữ liệu đầu vào và tìm đường
                             if (isValidCoordinate(startLat, startLon, uavAltitude) && isValidCoordinate(goalLat, goalLon, uavAltitude)) {

                                 var obstacles = [
                                             // UAV sẽ tránh bán kính vật cản với khoảng cách 20m
                                             //khu vực cấm bay
                                             { "latitude": 21.0372747, "longitude": 105.8371396, "radius": 1020, "height": 100 }, // Tòa nhà quốc hội
                                             { "latitude": 21.0260690, "longitude": 105.8480420, "radius": 520, "height": 50 }, // Bộ công thương
                                             { "latitude": 21.0485743, "longitude": 105.7800104, "radius": 1020, "height": 100 }, // Bộ công an
                                             { "latitude": 21.0338809, "longitude": 105.7795177, "radius": 520, "height": 100 }, // bệnh viện y học cổ truyền
                                             { "latitude": 21.0183784, "longitude": 105.8603403, "radius": 520, "height": 50 }, // Bệnh viện 108
                                             { "latitude": 21.0440653, "longitude": 105.8018651, "radius": 520, "height": 50 }, // Học viện quốc phòng

                                             // Các tòa nhà cao tâng
                                             { "latitude": 21.0167251, "longitude": 105.7841804, "radius": 60, "height": 296 }, // AON Hanoi Landmark Tower 336m
                                             { "latitude": 21.0321836, "longitude": 105.8126368, "radius": 60, "height": 267 }, // Lotte Center 267m
                                             { "latitude": 21.0182555, "longitude": 105.7841261, "radius": 60, "height": 212 }, // AON Landmark Residential Tower A 212m
                                             { "latitude": 21.0176241, "longitude": 105.7833234, "radius": 60, "height": 212 }, // AON Landmark Residential Tower B 212m
                                             { "latitude": 21.0054152, "longitude": 105.8039347, "radius": 60, "height": 176 }, // Diamond flower tower 176m
                                             { "latitude": 21.0240257, "longitude": 105.7902456, "radius": 60, "height": 173 }, // Golden Park cầu giấy 173m
                                             { "latitude": 21.0216479, "longitude": 105.7894814, "radius": 60, "height": 167 }, // Vinacomin Tower 167m
                                             { "latitude": 21.0053478, "longitude": 105.8057048, "radius": 60, "height": 159 }, // BRG Diamond Residence 159m
                                             { "latitude": 21.0038823, "longitude": 105.7943412, "radius": 60, "height": 142 }, // D'capitale C1 142m
                                             { "latitude": 21.0044640, "longitude": 105.7941894, "radius": 60, "height": 158 }, // D'capitale C2 158m
                                             { "latitude": 21.0050972, "longitude": 105.7943238, "radius": 60, "height": 148 }, // D'capitale C3 148m
                                             { "latitude": 21.0058359, "longitude": 105.7946772, "radius": 60, "height": 165 }, // D'capitale C5 165m
                                             { "latitude": 21.0064294, "longitude": 105.7952854, "radius": 60, "height": 158 }, // D'capitale C6 158m
                                             { "latitude": 21.0068491, "longitude": 105.7959166, "radius": 60, "height": 158 }, // D'capitale C7 158m
                                             { "latitude": 21.0023280, "longitude": 105.7920670, "radius": 60, "height": 152 }, // Thăng Long Number One A 152m
                                             { "latitude": 21.0029783, "longitude": 105.7930751, "radius": 60, "height": 152 }, // Thăng Long Number One B 152m
                                             { "latitude": 21.0201724, "longitude": 105.7809074, "radius": 70, "height": 151 }, // VinHome SkyLake 1 151m
                                             { "latitude": 21.0198623, "longitude": 105.7815959, "radius": 70, "height": 151 }, // VinHome SkyLake 2 151m
                                             { "latitude": 21.0197360, "longitude": 105.7829264, "radius": 70, "height": 151 }, // VinHome SkyLake 3 151m
                                             { "latitude": 21.0091010, "longitude": 105.7933277, "radius": 60, "height": 150 }, // CT4 Vimeco 150m
                                             { "latitude": 21.0167373, "longitude": 105.7817838, "radius": 60, "height": 140 }, // Handico Tower 140m
                                             { "latitude": 21.0082461, "longitude": 105.8029051, "radius": 60, "height": 136 }, // 34T Trung Hòa 136, từng cao nhất đến khi xây Landmark
                                             { "latitude": 21.0253005, "longitude": 105.7879615, "radius": 60, "height": 130 }, // Viện kiểm sát nhân dân tối cao 130m
                                             { "latitude": 21.0085313, "longitude": 105.7961842, "radius": 60, "height": 123 }  // The Summit 123m
                                 ];

                                 // Kiểm tra thuật toán được chọn
                                 if (selectedAlgorithm === "AStar") {
                                     // Chạy thuật toán AStar
                                     var pathAstar = aStar.findPath(startLat, startLon, goalLat, goalLon, obstacles, uavAltitude);

                                     // Kiểm tra xem có tìm được đường không
                                     if (pathAstar.length > 0) {
                                         pathLine.path = pathAstar;
                                         notification.text = "Path found.\n" + "Path length: " + aStar.pathLength.toFixed(2) + " meters";
                                         notification.visible = true;
                                         errorMessage.visible = false;
                                         inputBox.visible = true;
                                     } else {
                                         errorMessage.text = "Can't find path.";
                                         errorMessage.visible = true;
                                         inputBox.visible = true;
                                     }

                                 } else if (selectedAlgorithm === "ACO") {
                                     // Chạy thuật toán ACO
                                     var pathACO = aco.findPath(startLat, startLon, goalLat, goalLon, obstacles, uavAltitude);

                                     // Kiểm tra xem có tìm được đường không
                                     if (pathACO.length > 0) {
                                         pathLine.path = pathACO;
                                         notification.text = "Path found.\n" + "Path length: " + aco.shortestPathLength.toFixed(2) + " meters";
                                         notification.visible = true;
                                         errorMessage.visible = false;
                                         inputBox.visible = true;
                                     } else {
                                         errorMessage.text = "Can't find path.";
                                         errorMessage.visible = true;
                                         inputBox.visible = true;
                                         notification.visible = false;
                                     }

                                 }

                             } else {
                                 errorMessage.text = "Invalid coordinates or altitude! \nPlease enter valid value.";
                                 errorMessage.visible = true;
                                 inputBox.visible = true;
                                 notification.visible = false;
                             }
                         }
                     }
                 }
             }

             // Chọn đầu vào từ bản đồ
             Row {
                 spacing: 10
                 Button {
                     text: "Select start coordinate from map"
                     height: 30
                     width: 220
                     background: Rectangle {
                             id: startMapBackground
                             color: "white"
                             border.color: "black"
                             radius: 4

                             // Tạo hiệu ứng khi ấn
                             MouseArea {
                                 id: startMapClick
                                 anchors.fill: parent
                                 onPressedChanged: {
                                     if (startMapClick.pressed) {
                                         startMapBackground.color = "lightgray";
                                     } else {
                                         startMapBackground.color = "white";
                                     }
                                 }
                                 onClicked: {
                                     isSelectingStartCoordinate = true;
                                     notification.text = "Choose starting point from map.";
                                     notification.visible = true;
                                     errorMessage.visible = false;
                                 }
                             }
                     }
                 }

                 Button {
                     text: "Select goal coordinate from map"
                     height: 30
                     width: 220
                     background: Rectangle {
                             id: goalMapBackground
                             color: "white"
                             border.color: "black"
                             radius: 4

                             // Tạo hiệu ứng khi ấn
                             MouseArea {
                                 id: goalMapClick
                                 anchors.fill: parent
                                 onPressedChanged: {
                                     if (goalMapClick.pressed) {
                                         goalMapBackground.color = "lightgray";
                                     } else {
                                         goalMapBackground.color = "white";
                                     }
                                 }
                                 onClicked: {
                                     isSelectingGoalCoordinate = true;
                                     notification.text = "Choose destination from map.";
                                     notification.visible = true;
                                     errorMessage.visible = false;
                                 }
                             }
                     }
                 }
             }
         }
         // Đóng/mở bảng
         Button {
             id: closeButton
             text: "\u2715"
             width: 30
             height: 30
             anchors.right: parent.right
             anchors.top: parent.top
             anchors.margins: 10
             font.pixelSize: 20
             onClicked: {
                 inputBox.visible = false;  // Ẩn bảng khi nhấn nút "X"
             }
         }
     }

     // Hàm reset
     function reset() {
         uavModel.coordinate = QtPositioning.coordinate(startLat, startLon);
         pathLine.path = [];
         startMarker.visible = false;
         endMarker.visible = true;
        // elevationText.text = "Elevation: 0m"
         uavTimer.stop();
     }

     // Hàm di chuyển
     function animateUAV(path) {
         pathModel.clear();
         for (var i = 0; i < path.length; i++) {
             pathModel.append(path[i]);
         }
         uavTimer.start();
     }

     // Hàm kiểm tra tọa độ hợp lệ
     function isValidCoordinate(lat, lon, alt) {

         // Kiểm tra xem alt có > 0 không
         if (alt <= 0) {
             return false;
         }

         // Kiểm tra xem lat và lon có phải là chuỗi rỗng không
         if (lat === '' || lon === '' || alt === '') {
             return false;
         }

         // Kiểm tra xem lat và lon có phải là số không
         if (typeof lat !== 'number' || typeof lon !== 'number' || typeof alt != 'number') {
             return false;
         }

         // Kiểm tra xem lat và lon có phải là giá trị số hợp lệ không
         if (isNaN(lat) || isNaN(lon) ||  isNaN(alt)) {
             return false;
         }

         // Kiểm tra xem lat và lon có nằm trong phạm vi hợp lệ không
         if (lat < 8 || lat > 25 || lon < 100 || lon > 110) {
             return false;
         }

         return true;
     }

     Timer {
         id: uavTimer
         interval: 10
         repeat: true
         running: false
         property real moveStep: 0.01 // Adjust this value for smoothness
         onTriggered: {
             if (pathModel.count > 0) {
                 var nextPoint = pathModel.get(0);
                 var currentCoordinate = uavModel.coordinate;
                 var newCoordinate = QtPositioning.coordinate(nextPoint.latitude, nextPoint.longitude);

                 // Interpolate between current and next point for smooth movement
                 var latDiff = nextPoint.latitude - currentCoordinate.latitude;
                 var lonDiff = nextPoint.longitude - currentCoordinate.longitude;

                 if (Math.abs(latDiff) > moveStep || Math.abs(lonDiff) > moveStep) {
                     uavModel.coordinate.latitude += latDiff * moveStep;
                     uavModel.coordinate.longitude += lonDiff * moveStep;
                 } else {
                     // If close enough, snap to next point and remove it from the list
                     uavModel.coordinate = newCoordinate;
                     pathModel.remove(0);
                 }

                 // Get and update elevation
                 var latitude = uavModel.coordinate.latitude.toFixed(7);
                 var longitude = uavModel.coordinate.longitude.toFixed(7);
                 //var elevation = readHGT.getElevation(latitude, longitude) + 90;

                 console.log("Move to coordinate: (" + latitude + ", " + longitude + ")");
             } else {
                 console.log("Done!");
                 uavTimer.stop();
             }
         }
     }

     ListModel {
         id: pathModel
     }
}
