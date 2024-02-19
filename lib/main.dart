import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'exam.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;


class ExamForm extends StatefulWidget {
  final Function(Exam) addExam;

  const ExamForm({required this.addExam, Key? key}) : super(key: key);

  @override
  ExamFormState createState() => ExamFormState();
}

class ExamFormState extends State<ExamForm> {
  final TextEditingController subjectController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  LatLng selectedLocation = LatLng(41.994883, 21.425322);

  void openMapForLocationSelection(BuildContext context) async {
    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(initialLocation: selectedLocation,),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        selectedLocation = pickedLocation;
      });
    }
  }
  

  ElevatedButton buildStyledButton({
    required VoidCallback onPressed,
    required String buttonText,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[100],
        shadowColor: Colors.black54,
        elevation: 4,
      ),
      child: Text(
        buttonText,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> datePicker(BuildContext context) async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2019),
      lastDate: DateTime(2030),
    );

    if (datePicked != null && datePicked != selectedDate) {
      setState(() {
        selectedDate = datePicked;
      });
    }
  }

  void timePicker(BuildContext context) async {
    final TimeOfDay? timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );

    if (timePicked != null && timePicked != selectedDate) {
      setState(() {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          timePicked.hour,
          timePicked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatTimestamp(DateTime timestamp) {
      String formattedDate = DateFormat('EEEE, d MM yyyy').format(timestamp);
      String formattedTime = DateFormat('jm').format(timestamp);
      return '$formattedDate $formattedTime';
    }

    String? _subjectError;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ), 
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${formatTimestamp(selectedDate)}',
                ),
                buildStyledButton(
                  buttonText: 'Select Date',
                  onPressed: () => datePicker(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time: ${selectedDate.toLocal().toString().split(' ')[1].substring(0, 5)}',
                ),
                buildStyledButton(
                  onPressed: () => timePicker(context),
                  buttonText: 'Select Time',
                ),
              ],
            ),
            const SizedBox(height: 16),  Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Location: ${selectedLocation.latitude.toStringAsFixed(2)}, ${selectedLocation.longitude.toStringAsFixed(2)}',
        ),
        buildStyledButton(
          buttonText: 'Select Location',
          onPressed: () => openMapForLocationSelection(context),
        ),
      ],
    ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (subjectController.text.trim().isEmpty) {
                  setState(() {
                    _subjectError = 'Subject is required';
                  });
                } else {
                  setState(() {
                    _subjectError = null;
                  });

                  Exam exam = Exam(
                    course: subjectController.text,
                    timestamp: selectedDate,
                    latitude: selectedLocation.latitude,
                    longitude: selectedLocation.longitude
                  );
                  widget.addExam(exam);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                shadowColor: Colors.black54,
                elevation: 4,
              ),
              child: const Text(
                'Add Exam',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); 

  
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  
  runApp(const MyApp());
}


Future<void> scheduleNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    Exam exam,
) async {
  final DateTime now = DateTime.now();
  final DateTime notificationTime = exam.timestamp.subtract(const Duration(days: 1));

  if (notificationTime.isAfter(now)) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'exam_channel', 'Exam Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Upcoming Exam',
      'You have an upcoming exam for ${exam.course} tomorrow!',
      notificationTime,
      platformChannelSpecifics,
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anastasija Josifovska 193077',
      initialRoute: '/',
      routes: {
        '/': (context) => const MainListScreen(),
        '/login': (context) => const AuthScreen(isLogin: true),
        '/register': (context) => const AuthScreen(isLogin: false),
      },
    );
  }
}

ElevatedButton buildStyledButton({
  required VoidCallback onPressed,
  required String buttonText,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.pink[100],
      shadowColor: Colors.black54,
      elevation: 4,
    ),
    child: Text(
      buttonText,
      style: TextStyle(color: Colors.white),
    ),
  );
}

class MainListScreen extends StatefulWidget {
  const MainListScreen({Key? key});

  @override
  MainListScreenState createState() => MainListScreenState();
}

class MainListScreenState extends State<MainListScreen> {
  GoogleMapController? _mapController;
  final List<Exam> exams = [
    Exam(course: 'Kalkulus', timestamp: DateTime.now(), latitude: 41.9846, longitude: 21.4302),
Exam(course: 'Maths', timestamp: DateTime.now(), latitude: 42.0096, longitude: 21.3895),
Exam(course: 'Programiranje na video igri', timestamp: DateTime(2024, 02, 25), latitude: 41.9641, longitude: 21.4455),
    // Exam(course: 'Verojatnost', timestamp: DateTime(2024, 02, 25)),
    // Exam(course: 'Diskretni strukturi', timestamp: DateTime(2024, 10, 02)),
    // Exam(course: 'Algebra', timestamp: DateTime(2024, 05, 13)),
  ];

  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> events = [];

    for (Exam exam in exams) {
      if (day.year == exam.timestamp.year &&
          day.month == exam.timestamp.month &&
          day.day == exam.timestamp.day) {
        events.add(exam);
      }
    }

    return events;
  }

  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.disabled;

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    bool isDialogOpen = false;

    void _openMapForExam(Exam exam) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LocationPickerMap(initialLocation: LatLng(exam.latitude, exam.longitude)),
    ),
  );
}

      Set<Marker> _getMarkers() {
    return exams
        .map(
          (exam) => Marker(
            markerId: MarkerId(exam.course),
            position: LatLng(exam.latitude, exam.longitude),
            infoWindow: InfoWindow(title: exam.course, onTap: () {
              _openMapForExam(exam);
            }),
          ),
        )
        .toSet();
  }




    return Scaffold(
      appBar: AppBar(
        title: const Text('Anastasija Josifovska 193077'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => FirebaseAuth.instance.currentUser != null
                ? addExam(context)
                : signIn(context),
          ),
          InkWell(
            onTap: isLoggedIn ? signOut : () => signIn(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  isLoggedIn ? 'Log Out' : 'Log In',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(
                    markers: _getMarkers().toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            firstDay: DateTime.utc(
                2022, 1, 1), 
            lastDay: DateTime.utc(
                2025, 12, 31), 
            focusedDay: DateTime.now(),
            onDaySelected: (selectedDay, focusedDay) {
              print("Selected day: $selectedDay");
              List<dynamic> examsonday = _getEventsForDay(selectedDay);
              for (Exam exam in examsonday) {
                print(" exams: ${exam.course} - ${exam.timestamp}");

                

                if (!isDialogOpen) {
                  isDialogOpen = true;
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                              "Events for ${DateFormat('MMMM d, yyyy').format(selectedDay)}"),
                          content: Column(
                            children: examsonday.map((exam) {
                              return ListTile(
                                title: Text(exam.course),
                                subtitle: Text(
                                    DateFormat('jm').format(exam.timestamp)),
                              );
                            }).toList(),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                isDialogOpen = false;
                              },
                              child: Text("Close"),
                            ),
                          ],
                        );
                      });
                }
              }
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      width: 16,
                      height: 16,
                      child: Center(
                        child: Text(
                          events.length.toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
              ),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final course = exams[index].course;
                final timestamp = exams[index].timestamp;

                return Card(
                  color: Colors.pink[100],
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.pink, width: 1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          formatTimestamp(timestamp),
                          style: const TextStyle(
                              color: Color.fromARGB(255, 59, 59, 59)),
                        ),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(
                                text: 'Time from now: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 59, 59, 59),
                                ),
                              ),
                              TextSpan(
                                text: '${calculateTimeFromNow(timestamp)}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
              icon: Icon(Icons.map),
              onPressed: () => _openMapForExam(exams[index]),
            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String calculateTimeFromNow(DateTime timestamp) {
    Duration duration = timestamp.difference(DateTime.now());
    String timeFromNow = '';

    if (duration.inDays > 0) {
      timeFromNow += '${duration.inDays}d ';
    }
    if (duration.inHours > 0) {
      timeFromNow += '${duration.inHours % 24}h ';
    }
    if (duration.inMinutes > 0) {
      timeFromNow += '${duration.inMinutes % 60}m';
    }

    return timeFromNow.isNotEmpty ? timeFromNow : 'Now';
  }

  String formatTimestamp(DateTime timestamp) {
    String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(timestamp);
    String formattedTime = DateFormat('jm').format(timestamp);
    return '$formattedDate $formattedTime';
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {});
  }

  void signIn(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> addExam(BuildContext context) async {
    return showModalBottomSheet(
        context: context,
        builder: (_) {
          return GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: ExamForm(
              addExam: _addExam,
            ),
          );
        });
  }

  void _addExam(Exam exam) {
    setState(() {
      exams.add(exam);
    });
    scheduleNotification(flutterLocalNotificationsPlugin, exam);
  }
}

class AuthScreen extends StatefulWidget {
  final bool isLogin;

  const AuthScreen({Key? key, required this.isLogin});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailInput = TextEditingController();
  final TextEditingController passwordInput = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> _authAction() async {
    try {
      if (widget.isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: emailInput.text,
          password: passwordInput.text,
        );
        successDialog("Login Successful", "You have successfully logged in");
        HomeNavigation();
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: emailInput.text,
          password: passwordInput.text,
        );
        successDialog(
            "Registration Successful", "You have successfully registered");
        LoginNavigation();
      }
    } catch (e) {
      errorDialog("Authentication Error", "Error: $e");
    }
  }

  void successDialog(String title, String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  void errorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void HomeNavigation() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  void LoginNavigation() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void RegisterNavigation() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/register');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isLogin ? const Text("Login") : const Text("Register"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(49.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailInput,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordInput,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            buildStyledButton(
              onPressed: _authAction,
              buttonText: (widget.isLogin ? "Sign In" : "Register"),
            ),
            if (!widget.isLogin)
              buildStyledButton(
                onPressed: LoginNavigation,
                buttonText: 'Login',
              ),
            if (widget.isLogin)
              buildStyledButton(
                onPressed: RegisterNavigation,
                buttonText: 'Register',
              ),
            TextButton(
              onPressed: HomeNavigation,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}


class MapScreen extends StatelessWidget {
  final List<Marker> markers;

  MapScreen({required this.markers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Locations'),
      ),
      body: GoogleMap(
        initialCameraPosition: calculateInitialCameraPosition(context),
        markers: markers.toSet(),
      ),
    );
  }

  CameraPosition calculateInitialCameraPosition(BuildContext context) {
    if (markers.isEmpty) {
      return CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 10.0,
      );
    }

  double minLat = markers.first.position.latitude;
  double maxLat = markers.first.position.latitude;
  double minLng = markers.first.position.longitude;
  double maxLng = markers.first.position.longitude;

  for (Marker marker in markers) {
    double lat = marker.position.latitude;
    double lng = marker.position.longitude;

    minLat = math.min(minLat, lat);
    maxLat = math.max(maxLat, lat);
    minLng = math.min(minLng, lng);
    maxLng = math.max(maxLng, lng);
  }

  LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  double zoom = 12;

  return CameraPosition(
    target: center,
    zoom: zoom,
  );
}


}


class LocationPickerMap extends StatefulWidget {
  final LatLng initialLocation;

  LocationPickerMap({required this.initialLocation});

  @override
  _LocationPickerMapState createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late GoogleMapController mapController;
  LatLng pickedLocation = LatLng(41.994883, 21.425322); 

  @override
  void initState() {
    super.initState();
    pickedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, pickedLocation);
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        onTap: (latLng) {
          setState(() {
            pickedLocation = latLng;
          });
        },
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation,
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('pickedLocation'),
            position: pickedLocation,
          ),
        },
      ),
    );
  }
}
