
import 'dart:async';
import 'dart:math' as math;
import 'package:aitaku/components/bottom-modal.dart';
import 'package:aitaku/const.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  // - Properties
  bool isBoarding = true;
  Map<PolylineId, Polyline> polylines = {};
  late GoogleMapController mapController;
  late StreamSubscription<Position> positionStream;
  Set<Marker> markers = {};

  final CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(35.07512, 135.219), // 丹波篠山市
    zoom: 10.0,
  );
  final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0);

  TextEditingController boardingPositionController = TextEditingController();
  FocusNode boardingPositionFocusNode = FocusNode();
  LatLng? boarding;

  TextEditingController destinationPositionController = TextEditingController();
  FocusNode destinationPositionFocusNode = FocusNode();
  LatLng? destination;


  // - Functions
  Future<void> _requestPermission() async {
    //位置情報が許可されていない時に許可をリクエストする
    Future(() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    });
  }

  void _setMarker(LatLng position, String markerId, String infoTitle) {
    setState(() {
      markers.removeWhere((marker) => marker.markerId == MarkerId(markerId));
      markers.add(
        Marker(
            icon: BitmapDescriptor.defaultMarkerWithHue(isBoarding
                ? BitmapDescriptor.hueBlue
                : BitmapDescriptor.hueGreen),
            markerId: MarkerId(markerId),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: infoTitle)),
      );
    });
  }

  void _setUpCurrentPosition(LatLng position) async {
    String boardingAddress = await _latLngToAddressStr(position);
    setState(() {
      boardingPositionController.text = boardingAddress;
    });
    _setMarker(position, "boarding-location", isBoarding ? "乗車位置" : "目的地");
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _setDefaultCameraPosition({required LatLng position}) async {
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _showModal(String duration) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        builder: (context) {
          return BottomModal(
            duration: duration,
            boarding: boarding!,
            boardingAddress: boardingPositionController.value.text,
            destination: destination!,
            destinationAddress: destinationPositionController.value.text,
          );
        });
  }

  Future<List<LatLng>> _getPolylinePoints(
      {required LatLng boarding, required LatLng destination}) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    print(GOOGLE_DIRECTION_API);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_DIRECTION_API,
        PointLatLng(boarding.latitude, boarding.longitude),
        PointLatLng(destination.latitude, destination.longitude),
        travelMode: TravelMode.driving);

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void _generatePolylineFromPoints(List<LatLng> polylineCoordinate) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.indigoAccent,
        points: polylineCoordinate,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap);

    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<String> _latLngToAddressStr(LatLng position) async {
    List<Placemark> placeMarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    String addressStr = "";
    if (placeMarks.isNotEmpty) {
      final place = placeMarks[0];
      if (place.postalCode != "") {
        addressStr =
        "${place.administrativeArea ?? ""} ${place.locality ?? ""} ${place.street ?? ""}";
      } else {
        addressStr =
        "${place.administrativeArea} ${place.locality} ${place.subLocality}";
      }
      return addressStr;
    }
    return addressStr;
  }

  Future<String> _calcTravelTime(
      {required LatLng boarding, required LatLng destination}) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${boarding.latitude},${boarding.longitude}&key=$GOOGLE_DIRECTION_API");
    final dio = Dio();
    final response = await dio.get(url.toString());
    if (response.statusCode == 200) {
      final String duration =
      response.data["routes"][0]["legs"][0]["duration"]["text"];
      return duration.split("min")[0];
    } else {
      return "測定に失敗しました。。。";
    }
  }

  Future<void> _setBoardingPosition(LatLng position) async {
    String selectAddress = await _latLngToAddressStr(position);
    polylines = {};
    setState(() {
      isBoarding
          ? boardingPositionController.text = selectAddress
          : destinationPositionController.text = selectAddress;
    });
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );

    isBoarding ? boarding = position : destination = position;
    _setMarker(
        position, isBoarding ? "boarding-location" : "destination-location",isBoarding ? "乗車位置" : "目的地");
  }

  void _toggleSwitch(bool value) {
    setState(() {
      isBoarding = value;
    });
  }

  LatLngBounds calculateBounds(List<LatLng> coordinates) {
    double minLat = double.infinity;
    double minLng = double.infinity;
    double maxLat = -double.infinity;
    double maxLng = -double.infinity;

    for (LatLng point in coordinates) {
      minLat = math.min(minLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLat = math.max(maxLat, point.latitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _checkInputValues() {
    final String boardingStr = boardingPositionController.value.text;
    final String destinationStr = destinationPositionController.value.text;
    if(boardingStr == "") {
      Fluttertoast.showToast(msg: "乗車位置を入力して下さい。", timeInSecForIosWeb: 2);
      return;
    }
    if(destinationStr == ""){
      Fluttertoast.showToast(msg: "目的地を入力して下さい。", timeInSecForIosWeb: 2);
      return;
    }
  }

  void _nextButtonTapped() async {

    _checkInputValues();

    final coordinates = await _getPolylinePoints(
      boarding: boarding!,
      destination: destination!,
    );

    _generatePolylineFromPoints(coordinates);
    final bounds = calculateBounds(coordinates);

    // カメラを調整してポリラインが全て収まるように移動

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // マージンを設定できます
    );

    final travelTime = await _calcTravelTime(
        boarding: boarding!, destination: destination!);

    _showModal(travelTime);
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    await _requestPermission();

    // 現在地の移動を監視、更新
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
                (Position position) async => _setDefaultCameraPosition(
                position: LatLng(position.latitude, position.longitude)));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    mapController.dispose();
    positionStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) async =>
                _onMapCreated(controller),
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            markers: markers,
            polylines: Set<Polyline>.of(polylines.values),
            onTap: (LatLng position) async =>
                _setBoardingPosition(position),

          ),
        ),
        Transform.translate(
          offset: const Offset(0, -5),
          child: Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'どこからどこに行きますか？',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 18),
                ),
                TextField(
                  controller: boardingPositionController,
                  focusNode: boardingPositionFocusNode,
                  decoration: InputDecoration(
                    label: Container(
                        child: Text('乗車位置',
                            style: isBoarding
                                ? TextStyle(color: Colors.white)
                                : null),
                        padding: isBoarding
                            ? EdgeInsets.symmetric(horizontal: 12)
                            : null,
                        decoration: isBoarding
                            ? BoxDecoration(
                            color: Colors.blue[700],
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4))
                            : null),
                  ),
                ),
                TextField(
                  controller: destinationPositionController,
                  focusNode: destinationPositionFocusNode,
                  decoration: InputDecoration(
                    label: Container(
                        child: Text('目的地',
                            style: !isBoarding
                                ? TextStyle(color: Colors.white)
                                : null),
                        padding: !isBoarding
                            ? EdgeInsets.symmetric(horizontal: 12)
                            : null,
                        decoration: !isBoarding
                            ? BoxDecoration(
                            color: Colors.green[700],
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4))
                            : null),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4),
                          color: isBoarding
                              ? Colors.blue[50]
                              : Colors.green[50],
                        ),
                        child: Column(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                  color: isBoarding
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                                ),
                                width: 150,
                                child: Text(
                                    !isBoarding ? "目的地を選択" : "乗車場所を選択",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                        color: Colors.white))),
                            Transform.scale(
                              scale: 1.3,
                              child: Switch(
                                value: isBoarding,
                                onChanged: _toggleSwitch,
                                activeColor: Colors.blue[700],
                                activeTrackColor: Colors.blue[200],
                                inactiveThumbColor: Colors.green[700],
                                inactiveTrackColor: Colors.green[200],
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        width: 180,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(4))),
                            onPressed: _nextButtonTapped,
                            child: const Text(
                              '次へ進む',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4),
                            )),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
