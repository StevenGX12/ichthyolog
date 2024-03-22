import 'package:flutter/material.dart';
import '../Helpers/standard_widgets.dart';
import 'post_page_comments.dart';
import '../Helpers/helper.dart';
import '../Helpers/http.dart';
import '../Models/user.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PostPage extends StatefulWidget {
  final int postid;
  final User currUser;
  final Function acceptIdCallback;
  const PostPage(
      {Key? key,
      required this.postid,
      required this.currUser,
      required this.acceptIdCallback})
      : super(key: key);
  @override
  PostPageState createState() => PostPageState();
}

class PostPageState extends State<PostPage> {
  String jwt = '';
  int _current = 0;
  final CarouselController _controller = CarouselController();
  Map<String, dynamic> decodedJWT = {};
  final httpHelpers = HttpHelpers();
  final helpers = Helpers();

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
          decodedJWT = JwtDecoder.decode(token);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: httpHelpers.viewPostRequest(widget.postid),
        builder: ((context, snapshotPost) {
          if (snapshotPost.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: snapshotPost.data!.species == null
                    ? Text(snapshotPost.data!.title)
                    : Text(
                        '${snapshotPost.data!.title} (${snapshotPost.data!.species})'),
                backgroundColor: const Color.fromARGB(255, 65, 90, 181),
              ),
              body: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                      child: Column(
                    children: [
                      Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 8),
                          child: ListTile(
                              visualDensity: const VisualDensity(
                                  horizontal: 0, vertical: -4),
                              leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      snapshotPost.data!.authorPfp)),
                              title: Text(
                                snapshotPost.data!.authorname,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 51, 64, 113)),
                              ),
                              subtitle: Column(
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                          'Sighted at ${snapshotPost.data!.sightingLocation} at ${snapshotPost.data!.sightingTime} ')),
                                  snapshotPost.data!.verified
                                      ? Row(
                                          children: [
                                            const Text('Verified by: '),
                                            Text(
                                              snapshotPost.data!.verifier!,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color.fromARGB(
                                                      255, 89, 108, 175)),
                                            )
                                          ],
                                        )
                                      : const SizedBox.shrink()
                                ],
                              ))),
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: CarouselSlider(
                              carouselController: _controller,
                              options: CarouselOptions(
                                  aspectRatio: 1.2,
                                  enlargeCenterPage: true,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _current = index;
                                    });
                                  }),
                              items: snapshotPost.data!.sightingPics.map((i) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Image(
                                      image: NetworkImage(i),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: snapshotPost.data!.sightingPics
                                .asMap()
                                .entries
                                .map((entry) {
                              return GestureDetector(
                                onTap: () =>
                                    _controller.animateToPage(entry.key),
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
                                          .withOpacity(_current == entry.key
                                              ? 0.9
                                              : 0.4)),
                                ),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                      Container(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 15, bottom: 7),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Description",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: Color.fromARGB(255, 51, 64, 113)),
                          )),
                      Container(
                          padding: const EdgeInsets.only(
                              left: 20, top: 5, right: 20, bottom: 5),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            snapshotPost.data!.description,
                          )),
                      Container(
                          margin: const EdgeInsets.only(bottom: 5, top: 18),
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          alignment: Alignment.centerLeft,
                          width: double.infinity,
                          child: Column(children: [
                            Row(
                              children: [
                                const Text(
                                  'Class: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 51, 64, 113),
                                      fontSize: 14),
                                ),
                                Text(
                                  snapshotPost.data!.class_ == null
                                      ? '[Not recorded]    '
                                      : '${snapshotPost.data!.class_}    ',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const Text(
                                  'Order: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 51, 64, 113),
                                      fontSize: 14),
                                ),
                                Text(
                                  snapshotPost.data!.order == null
                                      ? '[Not recorded]'
                                      : '${snapshotPost.data!.order}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Family: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 51, 64, 113),
                                      fontSize: 14),
                                ),
                                Text(
                                  snapshotPost.data!.family == null
                                      ? '[Not recorded]    '
                                      : '${snapshotPost.data!.family}    ',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const Text(
                                  'Genus: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 51, 64, 113),
                                      fontSize: 14),
                                ),
                                Text(
                                  snapshotPost.data!.genus == null
                                      ? '[Not recorded]'
                                      : '${snapshotPost.data!.genus}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ])),
                      Column(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(
                                left: 20, top: 18, bottom: 12),
                            child: const Text(
                              "Comments",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 51, 64, 113)),
                            ),
                          ),
                          FutureBuilder(
                            future: httpHelpers
                                .viewPostCommentsRequest(widget.postid),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.length > 1) {
                                return PostPageMultiComment(
                                    comments: snapshot.data!,
                                    jwt: jwt,
                                    postid: widget.postid,
                                    postPics: snapshotPost.data!.sightingPics,
                                    currUser: widget.currUser,
                                    decodedJWT: decodedJWT,
                                    updateCallBack: changeCommentCallback);
                              } else if (snapshot.hasData &&
                                  snapshot.data!.length == 1) {
                                return PostPageSingleComment(
                                  comments: snapshot.data!,
                                  jwt: jwt,
                                  decodedJWT: decodedJWT,
                                  postid: widget.postid,
                                  postPics: snapshotPost.data!.sightingPics,
                                  updateCallBack: changeCommentCallback,
                                  currUser: widget.currUser,
                                );
                              } else {
                                return PostPageNoComment(
                                  jwt: jwt,
                                  postid: widget.postid,
                                  postPics: snapshotPost.data!.sightingPics,
                                  currUser: widget.currUser,
                                  addCallBack: changeCommentCallback,
                                );
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  ))),
            );
          } else if (snapshotPost.hasError) {
            print(snapshotPost.error);
            return const NoticeDialog(
                content: 'Post not found! Please try again');
          } else {
            return const LoadingScreen();
          }
        }));
  }

  changeCommentCallback(response) {
    if (response == 'Comment Deleted' ||
        response == 'Comment Posted' ||
        response == 'Comment Upvoted' ||
        response == 'Comment Downvoted' ||
        response == 'Comment Un-upvoted' ||
        response == 'Comment Un-downvoted' ||
        response == 'ID suggestion posted successfully!' ||
        response == 'ID Suggestion Accepted' ||
        response == 'Refreshed') {
      setState(() {});
    }
    if (response == 'ID Suggestion Accepted' ||
        response == 'ID Suggestion Rejected') {
      widget.acceptIdCallback();
    }
  }
}
