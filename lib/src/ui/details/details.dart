import 'package:flutter/material.dart';
import 'package:horoscopes/src/common/signs.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:translator/translator.dart';

class DetailPage extends StatefulWidget {
  final ZodiacSign sign;

  DetailPage({Key key, this.sign}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  final translator = GoogleTranslator(); //加了這行!
  var afterTrans; //加了這行!
  AnimationController _controller;
  final List<String> timeSpans = ["Today", "Week", "Month", "Year"];
  String selectedSpan = "Today";

  Future<List<dynamic>> getData() async {
    var info = ["", ""];

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      info[0] = "Please Check your Internet Connection and Try Again.";
      return info;
    }
    var url = Uri.parse(
        "http://horoscope-api.herokuapp.com/horoscope/${selectedSpan.toLowerCase()}/${widget.sign.name}");
    http.Response response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
      },
    );
    Map<String, dynamic> data = json.decode(response.body);
    String horo = data['horoscope']; //加了這行!

    afterTrans = await translator.translate(horo, to: 'zh-tw'); //加了這行!

    // translator.translate(data, from: 'en', to: 'zh-cn');

    switch (selectedSpan) {
      case "Today":
        info[0] = data["date"];
        break;
      case "Week":
        info[0] = data["week"];
        break;
      case "Month":
        info[0] = data["month"];
        break;
      case "Year":
        info[0] = data["year"];
        break;
      default:
    }

    info[1] = afterTrans.toString(); //加了這行!

    return info;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF151846),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: widget.sign.name,
              child: GestureDetector(
                onPanDown: (details) {
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: widget.sign.signColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                          MediaQuery.of(context).size.width / 2),
                      bottomRight: Radius.circular(
                          MediaQuery.of(context).size.width / 2),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.sign.logoPath,
                      width: 200,
                      height: 200,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: FutureBuilder<List<dynamic>>(
                future: getData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 75.0),
                        child: CircularProgressIndicator(
                          backgroundColor: widget.sign.signColor,
                        ),
                      ),
                    );
                  }
                  return Text(
                    snapshot.data[0],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: FutureBuilder<List<dynamic>>(
                      future: getData(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container();
                        }
                        return Text(
                          snapshot.data[1],
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(timeSpans.length, (int index) {
          Widget child = Container(
            height: 80.0,
            width: 60.0,
            alignment: FractionalOffset.topCenter,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  0.0,
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: FloatingActionButton(
                heroTag: null,
                shape: StadiumBorder(),
                backgroundColor: widget.sign.getColor,
                child: Text(
                  timeSpans[index],
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  setState(() {
                    selectedSpan = timeSpans[index];
                  });
                  if (_controller.isDismissed) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                },
              ),
            ),
          );
          return child;
        }).toList()
          ..add(
            FloatingActionButton(
              heroTag: null,
              backgroundColor: widget.sign.getColor,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget child) {
                  return Opacity(
                    opacity: 1 - _controller.value,
                    child: Text(
                      selectedSpan,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              onPressed: () {
                if (_controller.isDismissed) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              },
            ),
          ),
      ),
    );
  }
}
