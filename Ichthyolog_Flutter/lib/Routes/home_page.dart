import 'dart:io';
import '../Helpers/custom_icons.dart';
import '../main.dart';
import 'package:flutter/material.dart';
import '../Helpers/standard_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:uuid/uuid.dart';
import '../Models/user.dart';
import '../Models/post.dart';
import '../Models/species.dart';
import '../Helpers/helper.dart';
import '../Helpers/http.dart';
import 'camera_page.dart';
import 'gallery_page.dart';
import 'post_page.dart';
import 'waiting_list_page.dart';
import 'statistics_page.dart';
import 'notifications_page.dart';
import 'expert_application_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'stepper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _authorised = false;
  File? image;
  String jwt = '';
  String newUsername = '';
  String newEmail = '';
  String newPassword = '';
  String oldPassword = '';
  String newTitle = '';
  String newDescription = '';
  final helpers = Helpers();
  final httpHelpers = HttpHelpers();
  final _formKey = GlobalKey<FormState>();
  bool editProfileRequestProcessing = false;
  bool editpfpRequestProcessing = false;
  bool editPostRequestProcessing = false;
  bool deletePostRequestProcessing = false;

  @override
  void initState() {
    super.initState();
    helpers.checkJwt().then((token) {
      if (token == '') {
        setState(() {
          _authorised = false;
          jwt = '';
        });
      } else {
        setState(() {
          _authorised = true;
          jwt = token;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorised) {
      return const NoticeDialog(
          content: 'Not authorised. Please sign in again');
    } else {
      return FutureBuilder(
          future: httpHelpers.viewOwnUserProfileRequest(jwt),
          builder: ((context, snapshotUser) {
            if (snapshotUser.hasData) {
              return Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    leading: userManualButton(snapshotUser.data!),
                    title: const Text('Home Page'),
                    backgroundColor: const Color.fromARGB(255, 65, 90, 181),

                    // Settings and logout buttons for changing profile picture, editing profile, and logging out
                    actions: [
                      settingsButton(
                          snapshotUser.data!, editProfileProcessingCallback),
                      logoutButton()
                    ],
                  ),
                  body: SingleChildScrollView(
                      physics: const ScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color.fromARGB(255, 30, 51, 128),
                                Color.fromARGB(255, 66, 94, 185),
                              ],
                            )),
                            height:
                                MediaQuery.of(context).size.height * 1 / 2.7,
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              1 /
                                              18),

                                  // Profile picture and edit profile picture button
                                  pfpture(snapshotUser.data!,
                                      editpfpProcessingCallback),

                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              1 /
                                              36),

                                  // Username
                                  Wrap(children: [
                                    Text(
                                      snapshotUser.data!.username,
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),

                                    // Expert tag if user is an isExpert
                                    snapshotUser.data!.isExpert
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                  60,
                                                ),
                                              ),
                                            ),
                                            margin:
                                                const EdgeInsets.only(left: 5),
                                            child: const Text(
                                              'isExpert',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white),
                                            ),
                                          )
                                        : const SizedBox.shrink()
                                  ]),
                                ]),
                          ),
                          FutureBuilder(
                              future: httpHelpers.viewOwnPostsRequest(jwt),
                              builder: ((context, snapshot) {
                                return snapshot.hasData
                                    // Display posts if there are posts by the user
                                    ? galleryScreen(context, snapshot.data!,
                                        snapshotUser.data!)
                                    : snapshot.hasError &&
                                            snapshot.error == 'Posts Not Found'
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      1 /
                                                      5,
                                                ),
                                                const Text(
                                                  'No sightings yet, start posting!',
                                                  style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 70, 88, 152),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 20),
                                                ),
                                              ])
                                        : loadingComment();
                              })),
                        ],
                      )),

                  // Bottom navigation bar for isExpert and non-isExpert users
                  bottomNavigationBar: snapshotUser.data!.isExpert
                      ? BottomAppBar(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              //Visit camera page to post sighting
                              cameraPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //Visit gallery page to view sightings
                              galleryPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //Visit statistics page to access sighting data
                              statsPageButton(refreshCallback),
                              //Visit isExpert application page to review/submit applications
                              isExpertApplicationPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //Visit waiting list page to verify/flag posts
                              waitingListPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //visit notifications to read notifications
                              notificationsPageButton(snapshotUser.data!)
                            ],
                          ),
                        )
                      : BottomAppBar(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              //Visit camera page to post sighting
                              cameraPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //Visit gallery page to view sightings
                              galleryPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //Visit statistics page to access sighting data
                              statsPageButton(refreshCallback),
                              //Visit isExpert application page to review/submit applications
                              isExpertApplicationPageButton(
                                  snapshotUser.data!, refreshCallback),
                              //visit notifications to read notifications
                              notificationsPageButton(snapshotUser.data!)
                            ],
                          ),
                        ));
            } else if (snapshotUser.hasError) {
              return const NoticeDialog(
                  content: 'User not found! Please try again');
            } else {
              return Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    title: const Text('Home Page'),
                    backgroundColor: const Color.fromARGB(255, 65, 90, 181),
                  ),
                  body: const LoadingScreen());
            }
          }));
    }
  }

  Widget pfpture(User user, Function editpfpProcessingCallback) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 75,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(user.pfp),
        ),
        Positioned(
          bottom: 2,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  width: 0.5,
                  color: Colors.white,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(
                    60,
                  ),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(2, 4),
                    color: Colors.black.withOpacity(
                      0.3,
                    ),
                    blurRadius: 3,
                  ),
                ]),
            child: IconButton(
                padding: const EdgeInsets.all(2.0),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(builder: (context, setState) {
                          void uploadPic(
                            String jwt,
                          ) async {
                            final key = const Uuid().v4();
                            final file = AWSFile.fromPath(image!.path);
                            if (editpfpRequestProcessing) {
                              null;
                            } else {
                              try {
                                Amplify.Storage.uploadFile(
                                  key: key,
                                  localFile: file,
                                  options: const StorageUploadFileOptions(
                                    accessLevel: StorageAccessLevel.guest,
                                  ),
                                );
                                editpfpProcessingCallback();
                                httpHelpers
                                    .editUserProfilePicRequest(
                                        "https://ichthyolog175756-dev.s3.ap-southeast-1.amazonaws.com/public/$key",
                                        jwt)
                                    .then((String response) {
                                  editpfpProcessingCallback();
                                  Fluttertoast.showToast(
                                    msg: response,
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                  );
                                  if (response == 'User Edited') {
                                    Navigator.pop(context);
                                    setState(() {
                                      image = null;
                                    });
                                  }
                                });
                              } catch (error) {
                                Fluttertoast.showToast(
                                  msg: error.toString(),
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                );
                              }
                            }
                          }

                          Future<void> takePhoto(ImageSource source) async {
                            final imagePicker = ImagePicker();
                            final pickedImage =
                                await imagePicker.pickImage(source: source);

                            if (pickedImage != null) {
                              setState(() {
                                image = File(pickedImage.path);
                              });
                            }
                          }

                          Future<void> selectFromGallery() async {
                            takePhoto(ImageSource.gallery);
                          }

                          return AlertDialog(
                            title: const Text('Change Profile Picture'),
                            content: image != null
                                ? SingleChildScrollView(
                                    child: Center(
                                        child: Column(
                                    children: [
                                      Image.file(image!),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Wrap(
                                            spacing: 10,
                                            children: [
                                              ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color
                                                                  .fromARGB(
                                                                  255,
                                                                  80,
                                                                  170,
                                                                  121)),
                                                  child: const Text("Confirm",
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  onPressed: () {
                                                    uploadPic(jwt);
                                                    image = null;
                                                  }),
                                              ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color
                                                                  .fromARGB(255,
                                                                  170, 80, 80)),
                                                  child: const Text("Cancel",
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      image = null;
                                                    });
                                                  })
                                            ],
                                          ))
                                    ],
                                  )))
                                : SingleChildScrollView(
                                    child: Center(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                        Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.photo,
                                                size: 110,
                                                color: Color.fromARGB(
                                                    255, 51, 64, 113),
                                              ),
                                              const SizedBox(height: 10),
                                              ElevatedButton(
                                                onPressed: () => takePhoto(
                                                    ImageSource.camera),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 74, 112, 178),
                                                ),
                                                child: const Text('Take Photo'),
                                              ),
                                              ElevatedButton(
                                                onPressed: selectFromGallery,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 87, 131, 206),
                                                ),
                                                child: const Text(
                                                    'Select from Gallery'),
                                              ),
                                            ])
                                      ]))),
                          );
                        });
                      }).then((value) {
                    setState(() {});
                  });
                },
                icon: const Icon(Icons.add_a_photo),
                color: const Color.fromARGB(255, 70, 88, 152)),
          ),
        ),
      ],
    );
  }

  Widget userLevel(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const Text(
            'Level ', // Replace with the actual level value
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 70, 88, 152)),
          ),
          const SizedBox(width: 5),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color.fromARGB(255, 70, 88, 152),
            foregroundColor: Colors.white,
            child: Text(
              '${user.level}', // Replace with the actual level value
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              value: user.level / 100,
              color: const Color.fromARGB(255, 76, 105, 210),
              backgroundColor: const Color.fromARGB(255, 158, 191, 255),
              minHeight: 20,
            ),
          )),
        ],
      ),
    );
  }

  Widget logoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () {
        helpers.logout(jwt, context);
      },
    );
  }

  Widget settingsButton(User user, Function editProfileProcessingCallback) {
    return IconButton(
      icon: const Icon(Icons.manage_accounts),
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text("Edit Profile")),
                content: SingleChildScrollView(
                    child: Form(
                        key: _formKey,
                        child: Column(children: [
                          Container(
                              margin: const EdgeInsets.only(left: 5),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Edit Username',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              )),
                          usernameField(),
                          Container(
                              margin: const EdgeInsets.only(top: 20, left: 5),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Edit Email',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              )),
                          emailField(),
                          Container(
                              margin: const EdgeInsets.only(top: 20, left: 5),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Edit Password',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              )),
                          newPasswordField(),
                        ]))),
                actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 80, 170, 121)),
                      child:
                          const Text("Confirm", style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        print(
                            'Username: $newUsername, Password: $newPassword, Email: $newEmail');

                        if (newUsername == '' &&
                            newEmail == '' &&
                            newPassword == '') {
                          Navigator.pop(context);
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const NoticeDialog(
                                    content: 'No changes made!');
                              });
                        } else {
                          final bool? isValid =
                              _formKey.currentState?.validate();
                          if (isValid == true) {
                            Navigator.pop(context);
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Padding(
                                        padding: EdgeInsets.only(left: 5),
                                        child: Text('Double Confirm')),
                                    content: SingleChildScrollView(
                                        child: Column(children: [
                                      Container(
                                          margin: const EdgeInsets.only(
                                              top: 10, left: 5),
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Enter your current password',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Color.fromARGB(
                                                    255, 51, 64, 113)),
                                          )),
                                      oldPasswordField()
                                    ])),
                                    actions: [
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 80, 170, 121)),
                                          child: const Text("Confirm",
                                              style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            if (editProfileRequestProcessing) {
                                              null;
                                            } else {
                                              editProfileProcessingCallback();
                                              httpHelpers
                                                  .editUserProfileRequest(
                                                      newEmail,
                                                      newUsername,
                                                      oldPassword,
                                                      newPassword,
                                                      jwt)
                                                  .then((response) {
                                                editProfileProcessingCallback();
                                                Fluttertoast.showToast(
                                                  msg: response,
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  timeInSecForIosWeb: 1,
                                                );
                                                if (response == 'User Edited') {
                                                  Navigator.pop(context);
                                                  if (newUsername != '') {
                                                    httpHelpers
                                                        .loginRequest(
                                                            newUsername,
                                                            newUsername,
                                                            newPassword == ''
                                                                ? oldPassword
                                                                : newPassword)
                                                        .then((String
                                                            response) async {
                                                      if (response != 'Password Incorrect' &&
                                                          response !=
                                                              'User Not Found' &&
                                                          response != 'Error') {
                                                        await storage.write(
                                                            key: "jwt",
                                                            value: response);
                                                      }
                                                    });
                                                  }
                                                  setState(() {
                                                    newUsername = '';
                                                    newEmail = '';
                                                    newPassword = '';
                                                  });
                                                }
                                              });
                                            }
                                          }),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 170, 80, 80)),
                                          child: const Text("Cancel",
                                              style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              newUsername = '';
                                              newEmail = '';
                                              newPassword = '';
                                            });
                                          })
                                    ],
                                  );
                                });
                          }
                        }
                      }),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 170, 80, 80)),
                      child:
                          const Text("Cancel", style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          newUsername = '';
                          newEmail = '';
                          newPassword = '';
                        });
                      })
                ],
              );
            });
      },
    );
  }

  Widget cameraPageButton(User user, Function refreshCallback) {
    return IconButton(
      icon: const Icon(Icons.add_a_photo_rounded,
          color: Color.fromARGB(255, 52, 66, 117)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CameraPage(currUser: user)),
        ).then((value) => refreshCallback());
      },
    );
  }

  Widget statsPageButton(Function refreshCallback) {
    return IconButton(
      icon: const Icon(Icons.search, color: Color.fromARGB(255, 52, 66, 117)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatisticsPage()),
        ).then((value) => refreshCallback());
      },
    );
  }

  Widget galleryPageButton(User user, Function refreshCallback) {
    return IconButton(
      icon: const Icon(CustomIcons.sightingsIcon),
      color: const Color.fromARGB(255, 52, 66, 117),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GalleryPage(currUser: user)),
        ).then((value) => refreshCallback());
      },
    );
  }

  Widget isExpertApplicationPageButton(User user, Function refreshCallback) {
    return IconButton(
      icon:
          const Icon(Icons.how_to_reg, color: Color.fromARGB(255, 52, 66, 117)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ExpertApplicationPage(currUser: user)),
        ).then((value) => refreshCallback());
      },
    );
  }

  Widget notificationsPageButton(User user) {
    return FutureBuilder(
        future: httpHelpers.countUnviewedNotificationsRequest(jwt),
        builder: ((context, snapshotNotif) {
          return Stack(children: [
            IconButton(
              icon: const Icon(Icons.notification_important,
                  color: Color.fromARGB(255, 52, 66, 117)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsPage(currUser: user)),
                ).then((value) => refreshCallback());
              },
            ),
            snapshotNotif.hasData && snapshotNotif.data! > 0 ||
                    snapshotNotif.hasError
                ? Positioned(
                    top: 3,
                    right: 6,
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                              color: Colors.white,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(
                                60,
                              ),
                            ),
                            color: const Color.fromARGB(255, 167, 71, 71),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(2, 4),
                                color: Colors.black.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 3,
                              ),
                            ]),
                        child: snapshotNotif.hasData
                            ? Text('${snapshotNotif.data!}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white))
                            : const Icon(Icons.error)))
                : const SizedBox.shrink()
          ]);
        }));
  }

  Widget waitingListPageButton(User user, Function refreshCallback) {
    return IconButton(
      icon: const Icon(
        Icons.feedback,
        color: Color.fromARGB(255, 52, 66, 117),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WaitingListPage(
                    currUser: user,
                  )),
        ).then((value) => refreshCallback());
      },
    );
  }

  Widget userManualButton(User user) {
    return IconButton(
      icon: const Icon(
        Icons.question_mark,
        color: Colors.white,
      ),
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'App Guide',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                content: Scrollbar(
                    //always show scrollbar
                    thickness: 5, //width of scrollbar
                    radius:
                        const Radius.circular(20), //corner radius of scrollbar
                    scrollbarOrientation: ScrollbarOrientation
                        .right, //which side to show scrollbar
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Introduction',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              )),
                          const Text(
                              'Welcome to Ichthyolog! We are dedicated to the documentation of fish species sightings in Singapore. You may upload fish sightings to be verified by experts and add them to our scientific database. You may then access statistics on verified fsh records through the species search page. You may also discuss with experts on any submitted sighting and suggest species identifications for unverified posts.'),
                          const Padding(
                              padding: EdgeInsets.only(top: 15, bottom: 10),
                              child: Text(
                                'Rationale',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              )),
                          const Text(
                              'The app aims to provide a more complete picture of aquatic biodiversity in Singapore through the collective effort of the public. It is designed to complement existing biodiversity records by capturing the fish records missed on purely professional field trips.'),
                          const Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: Text(
                                'Navigation Icons',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              )),
                          iconDescription(const Icon(Icons.add_a_photo_rounded),
                              'Upload a sighting'),
                          iconDescription(const Icon(CustomIcons.sightingsIcon),
                              'View all sightings'),
                          iconDescription(const Icon(Icons.search),
                              'Look up species statistics'),
                          iconDescription(
                              const Icon(Icons.how_to_reg),
                              user.isExpert
                                  ? 'Review expert applications'
                                  : 'Submit expert application'),
                          user.isExpert
                              ? iconDescription(const Icon(Icons.feedback),
                                  'Review unverified posts')
                              : const SizedBox.shrink(),
                          iconDescription(
                              const Icon(Icons.notification_important),
                              'View notifications'),
                          iconDescription(const Icon(Icons.manage_accounts),
                              'Edit your profile information'),
                          iconDescription(const Icon(Icons.logout),
                              'Logout of your account'),
                        ]))),
                actions: [
                  TextButton(
                      child: const Text(
                        "Ok",
                        style: TextStyle(
                            color: Color.fromARGB(255, 52, 66, 117),
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      })
                ],
              );
            });
      },
    );
  }

  Widget newPasswordField() {
    return Container(
        margin: const EdgeInsets.only(top: 8, left: 5, right: 5, bottom: 15),
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
        ),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 225, 235, 248),
            borderRadius: BorderRadius.circular(16)),
        child: TextFormField(
          obscureText: true,
          onChanged: (value) {
            setState(() {
              newPassword = value;
            });
          },
          validator: (value) {
            if (value!.isNotEmpty) {
              if (value.length < 6 || value.length > 20) {
                return 'Password must be 6-20 characters';
              } else if (!isValidPassword(value)) {
                return 'Password must contain at least one capital letter and one special character';
              }
            }
            return null;
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Leave blank if not changing',
          ),
        ));
  }

  Widget oldPasswordField() {
    return Container(
        margin: const EdgeInsets.only(top: 14, left: 5, right: 5),
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
        ),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 225, 235, 248),
            borderRadius: BorderRadius.circular(16)),
        child: TextFormField(
          obscureText: true,
          onChanged: (value) {
            setState(() {
              oldPassword = value;
            });
          },
          validator: (value) {
            if (value!.length < 6 || value.length > 20) {
              return 'Password must be 6-20 characters';
            } else if (!isValidPassword(value)) {
              return 'Password must contain at least one capital letter and one special character';
            }
            return null;
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Current password',
          ),
        ));
  }

  Widget emailField() {
    return Container(
        margin: const EdgeInsets.only(top: 8, left: 5, right: 5),
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
        ),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 225, 235, 248),
            borderRadius: BorderRadius.circular(16)),
        child: TextFormField(
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value!.isNotEmpty && !isValidEmail(value)) {
              return 'Please enter a valid email';
            } else {
              return null;
            }
          },
          onChanged: (value) {
            setState(() {
              newEmail = value;
            });
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Leave blank if not changing",
          ),
        ));
  }

  Widget usernameField() {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 5, right: 5),
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
      ),
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 225, 235, 248),
          borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        validator: (value) {
          if (value!.isNotEmpty && value.trim().length > 25) {
            return 'Username must be less than 25 characters';
          } else {
            return null;
          }
        },
        onChanged: (value) {
          setState(() {
            newUsername = value;
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Leave blank if not changing',
        ),
      ),
    );
  }

  bool isValidUsername(String username) {
    if (username.isEmpty || username.length > 25) {
      return false;
    }
    return true;
  }

  bool isValidEmail(String email) {
    return RegExp(
            r'^[\w-]+(.[\w-]+)@[a-zA-Z0-9-]+(.[a-zA-Z0-9-]+)(.[a-zA-Z]{2,})$')
        .hasMatch(email);
  }

  bool isValidPassword(String password) {
    // Check if the password meets the criteria
    bool hasCapitalLetter = false;
    bool hasSpecialCharacter = false;

    for (int i = 0; i < password.length; i++) {
      var char = password[i];
      if (char == char.toUpperCase()) {
        hasCapitalLetter = true;
      }
      if (char.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        hasSpecialCharacter = true;
      }
    }

    return hasCapitalLetter && hasSpecialCharacter;
  }

  Widget editPostButton(Post post, Function editPostRequestProcessingCallback) {
    return IconButton(
      constraints: const BoxConstraints(),
      icon: CircleAvatar(
          radius: 13,
          backgroundColor: Colors.white.withOpacity(0.85),
          child: const Icon(
            Icons.edit,
            size: 15,
            color: Color.fromARGB(255, 39, 49, 133),
          )),
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              String newTitle = '';
              String newClass = '';
              String newOrder = '';
              String newFamily = '';
              String newGenus = '';
              String newSpecies = '';
              String newLocation = '';
              final TextEditingController titleController =
                  TextEditingController();
              final TextEditingController locationController =
                  TextEditingController();
              List<String> allSpecies = <String>[];
              for (var record in singaporeRecords) {
                allSpecies.add('${record.commonNames} (${record.species})');
              }
              return StatefulBuilder(builder: (context, setState) {
                classCallback(newValue) {
                  setState(() {
                    newClass = newValue;
                  });
                }

                orderCallback(newValue) {
                  setState(() {
                    newOrder = newValue;
                  });
                }

                familyCallback(newValue) {
                  setState(() {
                    newFamily = newValue;
                  });
                }

                genusCallback(newValue) {
                  setState(() {
                    newGenus = newValue;
                  });
                }

                titleCallback(newValue) {
                  setState(() {
                    newTitle = newValue.split('(')[0].split(', ')[0];
                  });
                  final speciesRecord = singaporeRecords.singleWhere(
                      (record) =>
                          '${record.commonNames} (${record.species})' ==
                          newValue, orElse: () {
                    return SpeciesRecord(
                        class_: '',
                        order: '',
                        family: '',
                        genus: '',
                        species: '',
                        commonNames: '');
                  });
                  if (speciesRecord.class_ != '' &&
                      speciesRecord.order != '' &&
                      speciesRecord.family != '' &&
                      speciesRecord.genus != '') {
                    setState(() {
                      newClass = speciesRecord.class_;
                      newOrder = speciesRecord.order;
                      newFamily = speciesRecord.family;
                      newGenus = speciesRecord.genus;
                      newSpecies = speciesRecord.species;
                    });
                  }
                }

                locationCallback(newValue) {
                  setState(() {
                    newLocation = newValue;
                  });
                }

                return AlertDialog(
                  title: const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text("Edit Post"),
                  ),
                  content: SingleChildScrollView(
                      child: Column(children: [
                    Container(
                        margin: const EdgeInsets.only(left: 5),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Edit Species Name',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 51, 64, 113)),
                        )),
                    selectableTextForm(
                        titleController, post.title, allSpecies, titleCallback),
                    Container(
                        margin: const EdgeInsets.only(top: 10, left: 5),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Edit Description',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 51, 64, 113)),
                        )),
                    Container(
                        margin:
                            const EdgeInsets.only(top: 8, left: 5, right: 5),
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 15,
                        ),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 225, 235, 248),
                            borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          initialValue: post.description,
                          minLines: 1,
                          maxLines: 8,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Edit Description'),
                          onChanged: (value) {
                            setState(() {
                              newDescription = value;
                            });
                          },
                        )),
                    Container(
                        margin: const EdgeInsets.only(left: 5, top: 10),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Edit Location',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 51, 64, 113)),
                        )),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: selectableTextForm(
                            locationController,
                            post.sightingLocation,
                            locations,
                            locationCallback)),
                    Wrap(
                      children: [
                        const Text(
                          'Class: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 51, 64, 113),
                              fontSize: 13),
                        ),
                        Text(
                          newClass == '' ? '${post.class_}   ' : '$newClass   ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Text(
                          'Order: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 51, 64, 113),
                              fontSize: 13),
                        ),
                        Text(
                          newOrder == '' ? '${post.order}' : newOrder,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          children: [
                            const Text(
                              'Family: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 51, 64, 113),
                                  fontSize: 13),
                            ),
                            Text(
                              newFamily == ''
                                  ? '${post.family}   '
                                  : '$newFamily   ',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Text(
                              'Genus: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 51, 64, 113),
                                  fontSize: 13),
                            ),
                            Text(
                              newGenus == '' ? '${post.genus}' : newGenus,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        )),
                  ])),
                  actions: [
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, bottom: 7),
                        child: Wrap(spacing: 5, children: [
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(content: StatefulBuilder(
                                      builder: (context, setState) {
                                        return SpeciesStepper(
                                          classCallback: classCallback,
                                          orderCallback: orderCallback,
                                          familyCallback: familyCallback,
                                          genusCallback: genusCallback,
                                        );
                                      },
                                    ));
                                  });
                            },
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor:
                                    const Color.fromARGB(255, 102, 154, 217)),
                            child: const Text(
                              'Edit Classification',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor:
                                      const Color.fromARGB(255, 80, 170, 121)),
                              child: const Text(
                                "Confirm",
                                style: TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                if (editPostRequestProcessing) {
                                  null;
                                } else {
                                  editPostRequestProcessingCallback();
                                  httpHelpers
                                      .editPostInfoRequest(
                                          post.postid,
                                          jwt,
                                          newTitle,
                                          newDescription,
                                          newLocation,
                                          newClass,
                                          newOrder,
                                          newFamily,
                                          newGenus,
                                          newSpecies)
                                      .then((response) {
                                    editPostRequestProcessingCallback();
                                    Fluttertoast.showToast(
                                      msg: response,
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                    );
                                    if (response == 'Post Edited') {
                                      Navigator.pop(context);
                                      setState(() {
                                        newClass = '';
                                        newOrder = '';
                                        newFamily = '';
                                        newGenus = '';
                                      });
                                    }
                                  });
                                }
                              }),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor:
                                      const Color.fromARGB(255, 170, 80, 80)),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  newClass = '';
                                  newOrder = '';
                                  newFamily = '';
                                  newGenus = '';
                                });
                              })
                        ])),
                  ],
                );
              });
            }).then((value) {
          setState(() {});
        });
      },
    );
  }

  Widget deletePostButton(
      Post post, Function deletePostRequestProcessingCallback) {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      icon: CircleAvatar(
          radius: 13,
          backgroundColor: Colors.white.withOpacity(0.85),
          child: const Icon(
            Icons.delete,
            size: 15,
            color: Color.fromARGB(255, 155, 47, 47),
          )),
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: const Text("Warning"),
                  content:
                      const Text('Are you sure? This action is irreversible!'),
                  actions: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 80, 170, 121)),
                        child: const Text("Yes"),
                        onPressed: () {
                          if (deletePostRequestProcessing) {
                            null;
                          } else {
                            deletePostRequestProcessingCallback();
                            httpHelpers
                                .deletePostRequest(post.postid, jwt)
                                .then(
                              (response) {
                                deletePostRequestProcessingCallback();
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: response,
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                );
                                setState(() {});
                              },
                            );
                          }
                        }),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 170, 80, 80)),
                        child: const Text("Cancel"),
                        onPressed: () {
                          Navigator.pop(context);
                        })
                  ]);
            });
      },
    );
  }

  Widget clickableImage(Post post, User user) {
    return Expanded(
        child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 6),
            child: Stack(children: [
              InkWell(
                  child: Ink.image(
                      image: NetworkImage(post.sightingPics.first),
                      fit: BoxFit.cover),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PostPage(
                                postid: post.postid,
                                currUser: user,
                                acceptIdCallback: refreshCallback,
                              )),
                    );
                  }),
              Positioned(
                  right: 8,
                  child: Row(children: [
                    editPostButton(post, editPostRequestProcessingCallback),
                    deletePostButton(post, deletePostRequestProcessingCallback)
                  ]))
            ])));
  }

  Widget galleryScreen(BuildContext context, List<Post> posts, User user) {
    return Column(children: [
      GridView.builder(
          itemCount: posts.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5.0,
            mainAxisSpacing: 7.0,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            return postCard(posts[index], user);
          },
          shrinkWrap: true,
          padding: const EdgeInsets.all(12.0))
    ]);
  }

  Widget postCard(Post post, User user) {
    return Card(
        color: const Color.fromARGB(255, 253, 254, 255),
        elevation: 4.5,
        shadowColor: const Color.fromARGB(255, 113, 165, 255),
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ListTile(
                  dense: true,
                  minVerticalPadding: 0,
                  horizontalTitleGap: 0,
                  visualDensity:
                      const VisualDensity(vertical: -4, horizontal: 0),
                  contentPadding: post.species == null
                      ? const EdgeInsets.symmetric(horizontal: 10)
                      : const EdgeInsets.only(
                          left: 10, right: 10, top: 2, bottom: 2),
                  title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: post.species == null
                          ? [
                              Text(
                                post.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color.fromARGB(255, 33, 53, 88)),
                              ),
                            ]
                          : [
                              Text(
                                post.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color.fromARGB(255, 33, 53, 88)),
                              ),
                              Text(
                                post.species!,
                                style: const TextStyle(
                                    fontSize: 8,
                                    color: Color.fromARGB(255, 33, 53, 88)),
                              ),
                            ]),
                  trailing: CircleAvatar(
                    radius: 8,
                    backgroundColor: post.flagged
                        ? const Color.fromARGB(255, 152, 72, 85)
                        : post.verified
                            ? const Color.fromARGB(255, 73, 155, 109)
                            : const Color.fromARGB(255, 175, 103, 51),
                    child: Icon(
                      post.flagged
                          ? Icons.priority_high
                          : post.verified
                              ? Icons.verified
                              : Icons.pending,
                      size: 10,
                      color: Colors.white,
                    ),
                  )),
              //Post Image
              clickableImage(post, user),
              Padding(
                  padding: const EdgeInsets.only(
                      left: 12, top: 8, right: 9, bottom: 8),
                  child: Row(children: [
                    const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.pin_drop,
                          size: 14,
                          color: Color.fromARGB(255, 51, 64, 113),
                        )),
                    Expanded(
                      child: Text(post.sightingLocation,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 33, 53, 88))),
                    ),
                  ])),
            ]));
  }

  Widget selectableTextForm(TextEditingController controller, String hintText,
      List<String> options, Function callback) {
    return Container(
        margin: const EdgeInsets.only(top: 8, left: 5, right: 5),
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
        ),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 225, 235, 248),
            borderRadius: BorderRadius.circular(16)),
        child: TypeAheadFormField(
          hideOnLoading: true,
          hideOnEmpty: true,
          textFieldConfiguration: TextFieldConfiguration(
              onChanged: (value) => callback(value),
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                focusColor: const Color.fromARGB(255, 51, 64, 113),
                border: InputBorder.none,
              ),
              autofocus: true,
              style: const TextStyle(color: Color.fromARGB(255, 51, 64, 113))),
          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(suggestion),
            );
          },
          errorBuilder: (context, error) {
            return NoticeDialog(content: '$error');
          },
          suggestionsCallback: (pattern) {
            List<String> matches = [];
            if (pattern == '') {
              return matches;
            } else {
              matches.addAll(options);
              matches.retainWhere((matches) {
                return matches.toLowerCase().contains(pattern.toLowerCase());
              });
              return matches;
            }
          },
          onSuggestionSelected: (suggestion) {
            callback(suggestion);
            controller.text = suggestion;
          },
        ));
  }

  Widget iconDescription(Widget icon, String description) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 10,
      leading: icon,
      title: Text(description),
    );
  }

  refreshCallback() {
    setState(() {});
  }

  editProfileProcessingCallback() {
    setState(() {
      editProfileRequestProcessing = !editProfileRequestProcessing;
    });
  }

  editpfpProcessingCallback() {
    setState(() {
      editpfpRequestProcessing = !editpfpRequestProcessing;
    });
  }

  editPostRequestProcessingCallback() {
    setState(() {
      editPostRequestProcessing = !editPostRequestProcessing;
    });
  }

  deletePostRequestProcessingCallback() {
    setState(() {
      deletePostRequestProcessing = !deletePostRequestProcessing;
    });
  }
}
