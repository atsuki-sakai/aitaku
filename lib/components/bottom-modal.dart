import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BottomModal extends StatefulWidget {
  final String duration;
  final String boardingAddress;
  final LatLng boarding;
  final String destinationAddress;
  final LatLng destination;
  const BottomModal(
      {Key? key,
        required this.duration,
        required this.boardingAddress,
        required this.boarding,
        required this.destinationAddress,
        required this.destination})
      : super(key: key);

  @override
  _BottomModalState createState() => _BottomModalState();
}

class _BottomModalState extends State<BottomModal> {
  // - Functions
  String _addMinutesToCurrentTime(int travelMinute) {
    final now = DateTime.now();
    final newTime = now.add(Duration(minutes: travelMinute));

    final formattedTime = DateFormat('HH時mm分').format(newTime);

    final slowTime = now.add(Duration(minutes: (travelMinute * 1.2).toInt()));

    final slowFormattedTime = DateFormat('HH時mm分').format(slowTime);
    return formattedTime + "~" + slowFormattedTime;
  }

  Future<void> _searchingTaxi(int searchSec, int intervalSec) async {
    print("search taxi.");
    print(widget.boardingAddress);
    print(widget.destinationAddress);
    print("${widget.boarding.latitude}, ${widget.boarding.longitude}");
    print("${widget.destination.latitude}, ${widget.destination.longitude}");

    // var uuid = const Uuid();
    // final japanNowTime = DateTime.now().toLocal();
    // final AuthBase auth = Provider.of<AuthBase>(context, listen: false);
    // final rider = auth.currentUser;

    // Ticket ticket = new Ticket(
    //     uuid.v4(),
    //     japanNowTime,
    //     widget.boarding,
    //     widget.boardingAddress,
    //     widget.destination,
    //     widget.destinationAddress,
    //     rider?.uid ?? "");
    // print(ticket.toMap());
    // Fluttertoast.showToast(
    //     msg: ticket.toMap().toString(), timeInSecForIosWeb: 10);
    // showDialog(
    //     context: context,
    //     barrierDismissible: false,
    //     builder: (context) => Container(
    //       child: Center(child: CircularProgressIndicator()),
    //     ));
  }

  @override
  Widget build(BuildContext context) {
    int travelMinute = int.parse(widget.duration);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
      height: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            width: 20,
            height: 20,
            alignment: Alignment.centerLeft,
            child: IconButton(
              color: Colors.grey,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(2),
                    padding:
                    const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo[900],
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "移動時間 - " +
                          travelMinute.toString() +
                          "分" +
                          "～" +
                          (travelMinute * 1.2).toInt().toString() +
                          "分",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    alignment: Alignment.center,
                    child: Text(
                        "到着予想時間 - " + _addMinutesToCurrentTime(travelMinute),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  ),
                ]),
          ),
          SizedBox(height: 10),
          Text("乗車場所",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo[800])),
          Text(widget.boardingAddress.split("兵庫県")[1]),
          SizedBox(height: 2),
          Text("目的地",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[800])),
          Text(widget.destinationAddress.split("兵庫県")[1]),
          Container(
            width: double.infinity,
            height: 50,
            margin: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.indigo),
                onPressed: () async => await _searchingTaxi(14, 3),
                child: Text('タクシーを呼ぶ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4))),
          )
        ],
      ),
    );
  }
}
