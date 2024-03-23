import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'date_time_picker.dart';
import '../Helpers/helper.dart';
import '../Helpers/http.dart';
import '../Helpers/standard_widgets.dart';
import '../Models/species.dart';
import '../Models/user.dart';
import 'package:intl/intl.dart';
import 'gallery_page.dart';
import 'Stepper.dart';

class Utils {
  static String getFormattedDateSimple(int time) {
    DateFormat newFormat = DateFormat("yyyy-MM-dd");
    return newFormat.format(DateTime.fromMillisecondsSinceEpoch(time));
  }
}

class CameraPage extends StatefulWidget {
  final User currUser;
  const CameraPage({Key? key, required this.currUser}) : super(key: key);
  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  List<File> images = <File>[];
  int _current = 0;
  final CarouselController _controller = CarouselController();
  String jwt = '';
  String date = '';
  String time = '';
  String title = '';
  String description = '';
  String sightingLocation = '';
  String class_ = '';
  String order = '';
  String family = '';
  String genus = '';
  String species = '';
  bool picUploadRequestProcessing = false;
  final helpers = Helpers();
  final httpHelpers = HttpHelpers();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> allSpecies = <String>[];

  @override
  void initState() {
    super.initState();
    helpers.checkJwt().then((token) {
      if (token == '') {
        setState(() {
          jwt = '';
        });
      } else {
        setState(() {
          jwt = token;
        });
      }
    });
    for (var record in singaporeRecords) {
      allSpecies.add('${record.commonNames} (${record.species})');
    }
  }

  @override
  Widget build(BuildContext context) {
    // when image is selected from gallery or taken from camera
    if (images.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Post a Sighting'),
          backgroundColor: const Color.fromARGB(255, 65, 90, 181),
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Species name text field with autocomplete
                selectableTextForm(
                    titleController,
                    'Enter species name',
                    const Icon(
                      Icons.phishing,
                      color: Color.fromARGB(255, 51, 64, 113),
                    ),
                    allSpecies,
                    titleCallback,
                    titleClearCallback),

                // Description text field
                Container(
                    margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 225, 235, 248),
                        borderRadius: BorderRadius.circular(16)),
                    child: TextFormField(
                      minLines: 1,
                      maxLines: 3,
                      controller: descriptionController,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.description,
                            color: Color.fromARGB(255, 51, 64, 113)),
                        border: InputBorder.none,
                        labelText: 'Enter species description',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              description = '';
                              descriptionController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          description = value;
                        });
                      },
                    )),

                // Location text field with autocomplete
                selectableTextForm(
                    locationController,
                    'Enter the location of sighting',
                    const Icon(
                      Icons.pin_drop,
                      color: Color.fromARGB(255, 51, 64, 113),
                    ),
                    locations,
                    locationCallback,
                    locationClearCallback),

                // Date and time picker
                Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: 45,
                    child: Wrap(children: [
                      const Text(
                        'Sighting timing:  ',
                        style: TextStyle(fontSize: 16),
                      ),
                      (date == '' && time == '')
                          ? Text(
                              DateFormat("yyyy-MM-dd hh:mm:ss")
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 51, 64, 113),
                                  fontSize: 16),
                            )
                          : Text(
                              "$date $time",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 51, 64, 113),
                                  fontSize: 16),
                            ),
                    ])),
                PickerDateTimeRoute(
                  dateCallback: dateCallback,
                  timeCallback: timeCallback,
                ),

                // Image preview
                Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: CarouselSlider(
                        carouselController: _controller,
                        options: CarouselOptions(
                            aspectRatio: 1.2,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }),
                        items: images.map((i) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Image.file(i);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () => _controller.animateToPage(entry.key),
                          child: Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black)
                                    .withOpacity(
                                        _current == entry.key ? 0.9 : 0.4)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Classification selection
                Container(
                    margin: const EdgeInsets.only(bottom: 7, top: 15),
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    alignment: Alignment.center,
                    width: double.infinity,
                    child: Column(children: [
                      Wrap(
                        children: [
                          const Text(
                            'Class: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 51, 64, 113),
                                fontSize: 14),
                          ),
                          Text(
                            class_ == '' ? '[Choose below]   ' : '$class_   ',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Text(
                            'Order: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 51, 64, 113),
                                fontSize: 14),
                          ),
                          Text(
                            order == '' ? '[Choose below]' : order,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      Wrap(
                        children: [
                          const Text(
                            'Family: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 51, 64, 113),
                                fontSize: 14),
                          ),
                          Text(
                            family == '' ? '[Choose below]   ' : '$family   ',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Text(
                            'Genus: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 51, 64, 113),
                                fontSize: 14),
                          ),
                          Text(
                            genus == '' ? '[Choose below]' : genus,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ])),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _takePhoto(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 74, 112, 178),
                      ),
                      child: const Text('Take another photo'),
                    ),
                    ElevatedButton(
                      onPressed: _selectFromGallery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 87, 131, 206),
                      ),
                      child: const Text('Add another image from gallery'),
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    Container(
                        margin: const EdgeInsets.only(
                            top: 6, left: 12, right: 12, bottom: 10),
                        child: ElevatedButton(
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
                              backgroundColor:
                                  const Color.fromARGB(255, 102, 154, 217)),
                          child: const Text('Add classification',
                              style: TextStyle(fontSize: 16)),
                        )),

                    // Upload and clear buttons
                    Container(
                        margin: const EdgeInsets.only(
                            top: 6, right: 12, bottom: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            _uploadPost(
                                title,
                                description,
                                sightingLocation,
                                "$date $time",
                                jwt,
                                class_,
                                order,
                                family,
                                genus,
                                species,
                                images,
                                picUploadRequestProcessingCallback);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 80, 170, 121)),
                          child: const Text('Upload',
                              style: TextStyle(fontSize: 17)),
                        )),
                    Container(
                        margin: const EdgeInsets.only(
                            top: 6, right: 12, bottom: 10),
                        child: ElevatedButton(
                          onPressed: () => setState(() {
                            images = [];
                            class_ = '';
                            order = '';
                            family = '';
                            genus = '';
                          }),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 170, 80, 80)),
                          child: const Text('Clear',
                              style: TextStyle(fontSize: 17)),
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      );
    } else {
      // when no image is selected from gallery or taken from camera
      return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Post a Sighting'),
            backgroundColor: const Color.fromARGB(255, 65, 90, 181),
          ),
          body: SingleChildScrollView(
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 2 / 7),
                  const Icon(
                    Icons.photo,
                    size: 110,
                    color: Color.fromARGB(255, 53, 71, 134),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _takePhoto(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 74, 112, 178),
                    ),
                    child: const Text('Take Photo'),
                  ),
                  ElevatedButton(
                    onPressed: _selectFromGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 87, 131, 206),
                    ),
                    child: const Text('Select from Gallery'),
                  ),
                ])
              ]))));
    }
  }

  void _uploadPost(
    String title,
    String description,
    String sightingLocation,
    String sightingTime,
    String jwt,
    String class_,
    String order,
    String family,
    String genus,
    String species,
    List<File> images,
    Function picUploadRequestProcessingCallback,
  ) async {
    if (picUploadRequestProcessing) {
      return; // Exit if upload request is already processing
    }

    try {
      // Upload each image in the list
      final List<String> uploadedImageKeys = [];
      for (final File imageFile in images) {
        final key = const Uuid().v4();
        final file = AWSFile.fromPath(imageFile.path);
        try {
          final result = await Amplify.Storage.uploadFile(
            key: key,
            localFile: file,
            options: const StorageUploadFileOptions(
              accessLevel: StorageAccessLevel.guest,
            ),
          ).result;
          print('Uploaded file: ${result.uploadedItem.key}');
          uploadedImageKeys.add(key);
        } on StorageException catch (e) {
          print('Error uploading file: ${e.message}');
        } // Keep track of uploaded image keys
      }

      // Send description and other post information to the database
      picUploadRequestProcessingCallback();
      List<String> imageURLs = uploadedImageKeys
          .map((key) =>
              "https://ichthyolog175756-dev.s3.ap-southeast-1.amazonaws.com/public/$key")
          .toList();
      String imageUrlString = '{${imageURLs.map((url) => '"$url"').join(',')}}';
      final response = await httpHelpers.uploadPostRequest(
        title,
        description,
        sightingLocation,
        sightingTime == ''
            ? DateFormat("yyyy-MM-dd hh:mm:ss").format(DateTime.now())
            : sightingTime,
        imageUrlString,
        jwt,
        class_,
        order,
        family,
        genus,
        species,
      );

      picUploadRequestProcessingCallback();
      Fluttertoast.showToast(
        msg: response,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );

      if (response == 'Post Uploaded') {
        titleController.text = '';
        locationController.text = '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GalleryPage(
              currUser: widget.currUser,
            ),
          ),
        );
        setState(() {
          images = [];
          class_ = '';
          order = '';
          family = '';
          genus = '';
        });
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: error.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }
  }

  // take photo from device camera
  Future<void> _takePhoto(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        images.add(File(pickedImage.path));
      });
    }
  }

  // select photo from device gallery
  Future<void> _selectFromGallery() async {
    _takePhoto(ImageSource.gallery);
  }

  timeCallback(newValue) {
    setState(() {
      time = newValue;
    });
  }

  dateCallback(newValue) {
    setState(() {
      date = newValue;
    });
  }

  classCallback(newValue) {
    setState(() {
      class_ = newValue;
    });
  }

  orderCallback(newValue) {
    setState(() {
      order = newValue;
    });
  }

  familyCallback(newValue) {
    setState(() {
      family = newValue;
    });
  }

  genusCallback(newValue) {
    setState(() {
      genus = newValue;
    });
  }

  titleCallback(newValue) {
    setState(() {
      title = newValue.split('(')[0].split(', ')[0];
    });
    final speciesRecord = singaporeRecords.singleWhere(
        (record) => '${record.commonNames} (${record.species})' == newValue,
        orElse: () {
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
        class_ = speciesRecord.class_;
        order = speciesRecord.order;
        family = speciesRecord.family;
        genus = speciesRecord.genus;
        species = speciesRecord.species;
      });
    }
  }

  locationCallback(newValue) {
    setState(() {
      sightingLocation = newValue;
    });
  }

  titleClearCallback() {
    setState(() {
      title = '';
      titleController.clear();
    });
  }

  locationClearCallback() {
    setState(() {
      sightingLocation = '';
      locationController.clear();
    });
  }

  Widget selectableTextForm(
      TextEditingController controller,
      String labelText,
      Icon leadingIcon,
      List<String> options,
      Function updateCallback,
      Function clearCallback) {
    return Container(
        margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
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
              onChanged: (value) => updateCallback(value),
              controller: controller,
              decoration: InputDecoration(
                focusColor: const Color.fromARGB(255, 51, 64, 113),
                icon: leadingIcon,
                border: InputBorder.none,
                labelText: labelText,
                suffixIcon: IconButton(
                  onPressed: () {
                    clearCallback();
                  },
                  icon: const Icon(Icons.clear),
                ),
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
            updateCallback(suggestion);
            controller.text = suggestion;
          },
        ));
  }

  picUploadRequestProcessingCallback() {
    setState(() {
      picUploadRequestProcessing = !picUploadRequestProcessing;
    });
  }
}
