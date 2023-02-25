import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'home.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<AlertPage> createState() => _AlertPageState();
}

String agencyDefault = 'กรุณาเลือกหน่วยงานที่ต้องการแจ้งเหตุ';
String typeDefault = 'กรุณาเลือกประเภทการแจ้งเหตุ';

class _AlertPageState extends State<AlertPage> {
  final box = GetStorage();
  Position? _currentPosition;
  Position? position;
  List<CameraDescription>? cameras; //list out the camera available
  CameraController? controller; //controller for camera
  XFile? image; //for captured image
  String image_1_Path = "";
  String image_2_Path = "";
  String image_3_Path = "";
  String image_1_64base = "";
  String image_2_64base = "";
  String image_3_64base = "";

  @override
  void initState() {
    loadCamera();
    loadPosition();
    super.initState();
  }

  loadPosition() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  loadCamera() async {
    cameras = await availableCameras();
    if (cameras != null) {
      controller = CameraController(cameras![0], ResolutionPreset.max);
      //cameras[0] = first camera, change to 1 to another camera

      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    } else {
      print("NO any camera found");
    }
  }

  final _formKey = GlobalKey<FormState>();
  late String detail;
  late String address;
  late String lat;
  late String lng;

  String typevalue = typeDefault;
  var typeList = [
    typeDefault,
    'อุบัติเหตุ',
    'การจราจรติดขัด',
    'พบเห็นการทารุณกรรม',
    'พบเห็นผู้สูญหาย/หลงทาง',
    'พบสัตว์มีพิษ หรือ พบสัตว์ถูกทําร้าย',
    'อื่น ๆ'
  ];

  String agencyvalue = agencyDefault;
  var agencyList = [
    agencyDefault,
    'มูลนิธิร่วมกตัญญู',
    'สถานีตํารวจ',
    'โรงพยาบาล',
    'การไฟฟ้านครหลวง',
    'การประปาส่วนภูมิภาค'
  ];

  Future<String> getBase64string(String imagepath) async {
    if (imagepath == null || imagepath == "") {
      return "";
    }
    File imagefile = File(imagepath); //convert Path to File
    Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
    String base64string = base64.encode(imagebytes);
    return base64string;
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _handleLocationPermission() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')));
        return false;
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
        return false;
      }
      return true;
    }

    Future<void> _getCurrentPosition() async {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((Position position) {
        setState(() => _currentPosition = position);
      }).catchError((e) {
        debugPrint(e);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Accident Alert"),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: ListView(scrollDirection: Axis.vertical, children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                'แจ้งเหตุ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField(
                      validator: (value) {
                        if (value == typeDefault) return typeDefault;
                        return null;
                      },
                      value: typevalue,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: typeList.map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          typevalue = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.report_problem),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    DropdownButtonFormField(
                      validator: (value) {
                        if (value == agencyDefault) return agencyDefault;
                        return null;
                      },
                      value: agencyvalue,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: agencyList.map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          agencyvalue = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาระบุรายละเอียด';
                        }
                        return null;
                      },
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'รายละเอียด',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => detail = value,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาระบุสถานะที่';
                        }
                        return null;
                      },
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'สถานะที่',
                        prefixIcon: const Icon(Icons.room),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => address = value,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: _getCurrentPosition,
                      child: const Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            WidgetSpan(
                                child: Icon(
                              Icons.near_me,
                              color: Colors.white,
                              size: 18,
                            )),
                            TextSpan(text: ' พิกัด'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child:
                              Text('LAT: ${_currentPosition?.latitude ?? ""}')),
                      Expanded(
                          child:
                              Text('LNG: ${_currentPosition?.longitude ?? ""}'))
                    ]),
                    const SizedBox(
                      height: 20,
                    ),
                    TextButton(
                        onPressed: () async {
                          try {
                            final image = await controller!.takePicture();
                            setState(() {
                              image_1_Path = image.path;
                            });
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: Text("ถ่ายภาพที่ 1")),
                    if (image_1_Path != "")
                      Container(
                          width: 200,
                          height: 200,
                          child: Image.file(
                            File(image_1_Path),
                          )),
                    const SizedBox(
                      height: 20,
                    ),
                    TextButton(
                        onPressed: () async {
                          try {
                            final image = await controller!.takePicture();
                            setState(() {
                              image_2_Path = image.path;
                            });
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: Text("ถ่ายภาพที่ 2")),
                    if (image_2_Path != "")
                      Container(
                          width: 200,
                          height: 200,
                          child: Image.file(
                            File(image_2_Path),
                          )),
                    const SizedBox(
                      height: 20,
                    ),
                    TextButton(
                        onPressed: () async {
                          try {
                            final image = await controller!.takePicture();
                            setState(() {
                              image_3_Path = image.path;
                            });
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: Text("ถ่ายภาพที่ 3")),
                    if (image_3_Path != "")
                      Container(
                          width: 200,
                          height: 200,
                          child: Image.file(
                            File(image_3_Path),
                          )),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            image_1_64base =
                                await getBase64string(image_1_Path);
                            image_2_64base =
                                await getBase64string(image_2_Path);
                            image_3_64base =
                                await getBase64string(image_3_Path);
                            FirebaseFirestore.instance.collection('alert').add({
                              'type': typevalue,
                              'agency': agencyvalue,
                              'detail': detail,
                              'address': address,
                              'lat': _currentPosition?.latitude ?? "",
                              'lng': _currentPosition?.longitude ?? "",
                              'image_1_64base': image_1_64base,
                              'image_2_64base': image_2_64base,
                              'image_3_64base': image_3_64base,
                              'status': 0,
                              'date_alert': DateTime.now(),
                              'alertby': box.read('email')
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('เรียบร้อย !')),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HomePage(title: 'HomePage UI'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                        ),
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                          child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HomePage(title: 'HomePage UI'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                            backgroundColor: Colors.grey),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                    ]),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              )
            ],
          ),
        ]),
      ),
    );
  }
}
