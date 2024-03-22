import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/comment.dart';
import '../Models/post.dart';
import '../Models/user.dart';
import '../Models/species.dart';
import '../Models/dispute.dart';
import '../Models/expert_application_request.dart';
import '../Models/notifications.dart';

//class which stores the functions responsible for backend communication
class HttpHelpers {
  //signup request returns success message or error message
  //the string can be used for pop-up display etc.
  Future<String> signupRequest(
      String username, String password, String email) async {
    String url = 'https://ichthyolog.onrender.com/user';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(<String, String>{
        'username': username,
        'password': password,
        'email': email
      }),
    );
    if (response.statusCode == 201) {
      return 'Signup Successful';
    } else if (response.body ==
        'duplicate key value violates unique constraint "users_email_key"') {
      return 'Email Already Exists';
    } else if (response.body ==
        'duplicate key value violates unique constraint "users_username_key"') {
      return ('Username Already Exists');
    } else {
      return ('Signup Failed');
    }
  }

  Future<String> loginRequest(
      String email, String username, String password) async {
    String url = 'https://ichthyolog.onrender.com/user/login';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(<String, String>{
        'email': email,
        'username': username,
        'password': password
      }),
    );
    if (response.body == 'Password incorrect') {
      return ('Password Incorrect');
    } else if (response.body == 'User not found') {
      return ('User Not Found');
    } else if (response.statusCode != 200) {
      return ('Error');
    } else {
      return response.body;
    }
  }

  Future<String> logoutRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/user/logout';
    var response = await http.post(Uri.parse(url), headers: <String, String>{
      'Content-type': 'application/json; charset=UTF-8',
      'Authorisation': jwt
    });
    if (response.body == 'Valid token') {
      return ('Logged out');
    } else {
      return ('Logged out with expired token');
    }
  }

  Future<User> viewOwnUserProfileRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/user';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'User not found') {
      return Future.error('User Not Found');
    } else if (response.body == 'jwt expired') {
      return Future.error('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      return User.fromJson(json.decode(response.body)[0]);
    }
  }

  Future<List<String>> viewAllUsernamesRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/usernames';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'Users not found') {
      return Future.error(response.body);
    } else if (response.body == 'jwt expired') {
      return Future.error('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<String> usernames = [];
      var responseData = json.decode(response.body);
      for (var everyUsername in responseData) {
        usernames.add(everyUsername['username']);
      }
      return usernames;
    }
  }

  Future<User> viewAnyUserProfileRequest(int userid) async {
    String url = 'https://ichthyolog.onrender.com/user/$userid';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'User not found') {
      return Future.error('User Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      return User.fromJson(json.decode(response.body)[0]);
    }
  }

  Future<String> editUserProfileRequest(String email, String username,
      String oldPassword, String newPassword, String jwt) async {
    String urlUsername = 'https://ichthyolog.onrender.com/user/username';
    String urlEmail = 'https://ichthyolog.onrender.com/user/email';
    String urlPassword = 'https://ichthyolog.onrender.com/user/password';
    var responseUsername = await http.put(
      Uri.parse(urlUsername),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(
          <String, String>{'username': username, 'oldPassword': oldPassword}),
    );
    var responseEmail = await http.put(
      Uri.parse(urlEmail),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json
          .encode(<String, String>{'email': email, 'oldPassword': oldPassword}),
    );
    var responsePassword = await http.put(
      Uri.parse(urlPassword),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, String>{
        'newPassword': newPassword,
        'oldPassword': oldPassword
      }),
    );
    if (responseUsername.body == 'User not found' ||
        responseEmail.body == 'User not found' ||
        responsePassword.body == 'User not found') {
      return ('User Not Found');
    } else if (responseUsername.body == 'Incorrect password' ||
        responseEmail.body == 'Incorrect password' ||
        responsePassword.body == 'Incorrect password') {
      return ('Incorrect Password');
    } else if (responseEmail.body ==
        'duplicate key value violates unique constraint "users_email_key"') {
      return 'Email Already In Use';
    } else if (responseUsername.body ==
        'duplicate key value violates unique constraint "users_username_key"') {
      return ('Username Already In Use');
    } else if (responseUsername.statusCode != 200 ||
        responseEmail.statusCode != 200 ||
        responsePassword.statusCode != 200) {
      return ('Error');
    } else if (responseUsername.body == 'jwt expired' ||
        responseEmail.body == 'jwt expired' ||
        responsePassword.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('User Edited');
    }
  }

  Future<String> editUserProfilePicRequest(String imageurl, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/user/profilepic';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, String>{
        'profilepic': imageurl,
      }),
    );
    if (response.body == 'User not found') {
      return ('User Not Found');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return ('Error');
    } else {
      return ('User Edited');
    }
  }

  Future<List<Post>> viewAllPostsRequest() async {
    String url = 'https://ichthyolog.onrender.com/posts';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'Posts not found') {
      return Future.error('Posts Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<Post> postlist = [];
      var responseData = json.decode(response.body);
      for (var everypost in responseData) {
        Post post = Post.fromJson(everypost);
        postlist.add(post);
      }
      return postlist;
    }
  }

  Future<List<Post>> viewAllVerifiedPostsRequest() async {
    String url = 'https://ichthyolog.onrender.com/posts/verified';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'Posts not found') {
      return Future.error('Posts Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<Post> postlist = [];
      var responseData = json.decode(response.body);
      for (var everypost in responseData) {
        Post post = Post.fromJson(everypost);
        postlist.add(post);
      }
      return postlist;
    }
  }

  Future<List<Post>> viewAllUnverifiedPostsRequest() async {
    String url = 'https://ichthyolog.onrender.com/posts/unverified';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'Posts not found') {
      return Future.error('Posts Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<Post> postlist = [];
      var responseData = json.decode(response.body);
      for (var everypost in responseData) {
        Post post = Post.fromJson(everypost);
        postlist.add(post);
      }
      return postlist;
    }
  }

  Future<List<Post>> viewOwnPostsRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/posts/user';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'Posts not found') {
      return Future.error('Posts Not Found');
    } else if (response.body == 'jwt expired') {
      return Future.error('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<Post> postlist = [];
      var responseData = json.decode(response.body);
      for (var everypost in responseData) {
        Post post = Post.fromJson(everypost);
        postlist.add(post);
      }
      return postlist;
    }
  }

  Future<Post> viewPostRequest(int postid) async {
    String url = 'https://ichthyolog.onrender.com/post/$postid';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'Post not found') {
      return Future.error('Post Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      return Post.fromJson(json.decode(response.body)[0]);
    }
  }

  Future<int> viewPostIdByTitleRequest(String title) async {
    String url = 'https://ichthyolog.onrender.com/postid/$title';
    var response = await http.get(Uri.parse(url), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    if (response.body == 'Post not found') {
      return Future.error('Post Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      return json.decode(response.body)[0]['postid'];
    }
  }

  Future<String> uploadPostRequest(
      String title,
      String description,
      String sightingLocation,
      String sightingTime,
      String imageURLs,
      String jwt,
      String class_,
      String order,
      String family,
      String genus,
      String species) async {
    String url = 'https://ichthyolog.onrender.com/post';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{
        'title': title.trim(),
        'description': description,
        'sightingLocation': sightingLocation,
        'sightingTime': sightingTime,
        'imageURL': imageURLs,
        '_class': class_,
        'order': order,
        'family': family,
        'genus': genus,
        'species': species
      }),
    );
    print(sightingTime);
    print(response.body);
    if (response.statusCode == 201) {
      return ('Post Uploaded');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Post Upload Failed');
    }
  }

  Future<String> editPostInfoRequest(
      int postid,
      String jwt,
      String title,
      String description,
      String location,
      String class_,
      String order,
      String family,
      String genus,
      String species) async {
    String urlTitle = 'https://ichthyolog.onrender.com/post/$postid/title';
    String urlDescription =
        'https://ichthyolog.onrender.com/post/$postid/description';
    String urlSightingLocation =
        'https://ichthyolog.onrender.com/post/$postid/sightinglocation';
    String urlClass = 'https://ichthyolog.onrender.com/post/$postid/class';
    String urlOrder = 'https://ichthyolog.onrender.com/post/$postid/order';
    String urlFamily = 'https://ichthyolog.onrender.com/post/$postid/family';
    String urlGenus = 'https://ichthyolog.onrender.com/post/$postid/genus';
    String urlSpecies = 'https://ichthyolog.onrender.com/post/$postid/species';
    var responseTitle = await http.put(Uri.parse(urlTitle),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'title': title}));
    var responseDescription = await http.put(Uri.parse(urlDescription),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'description': description}));
    var responseSightingLocation = await http.put(
        Uri.parse(urlSightingLocation),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'sightingLocation': location}));

    var responseClass = await http.put(Uri.parse(urlClass),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'_class': class_}));
    var responseOrder = await http.put(Uri.parse(urlOrder),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'order': order}));
    var responseFamily = await http.put(Uri.parse(urlFamily),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'family': family}));
    var responseGenus = await http.put(Uri.parse(urlGenus),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'genus': genus}));
    var responseSpecies = await http.put(Uri.parse(urlSpecies),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'species': species}));

    if (responseTitle.body == 'Post not found' ||
        responseDescription.body == 'Post not found' ||
        responseSightingLocation.body == 'Post not found' ||
        responseClass.body == 'Post not found' ||
        responseOrder.body == 'Post not found' ||
        responseFamily.body == 'Post not found' ||
        responseGenus.body == 'Post not found' ||
        responseSpecies.body == 'Post not found') {
      return ('Post Not Found :(');
    } else if (responseTitle.body == 'jwt expired' ||
        responseDescription.body == 'jwt expired' ||
        responseSightingLocation.body == 'jwt expired' ||
        responseClass.body == 'jwt expired' ||
        responseOrder.body == 'jwt expired' ||
        responseFamily.body == 'jwt expired' ||
        responseGenus.body == 'jwt expired' ||
        responseSpecies.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (responseTitle.statusCode != 200) {
      return ('Title Edit Error :(');
    } else if (responseDescription.statusCode != 200) {
      return ('Description Edit Error :(');
    } else if (responseSightingLocation.statusCode != 200) {
      return ('Location Edit Error :(');
    } else if (responseClass.statusCode != 200) {
      return ('Class Edit Error :(');
    } else if (responseOrder.statusCode != 200) {
      return ('Order Edit Error :(');
    } else if (responseFamily.statusCode != 200) {
      return ('Family Edit Error :(');
    } else if (responseGenus.statusCode != 200) {
      return ('Genus Edit Error :(');
    } else if (responseSpecies.statusCode != 200) {
      return ('Species Edit Error :(');
    } else {
      return ('Post Edited');
    }
  }

  Future<List<Comment>> viewPostCommentsRequest(int postid) async {
    String url = 'https://ichthyolog.onrender.com/comments/$postid';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'Comments not found') {
      return Future.error('Comments Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<Comment> comments = [];
      var responseData = json.decode(response.body);
      for (var everycomment in responseData) {
        Comment comment = Comment.fromJson(everycomment);
        comments.add(comment);
      }
      return comments;
    }
  }

  Future<List<Comment>> viewUserCommentsRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/comments/user';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'Comments not found') {
      return Future.error('Comments Not Found');
    } else if (response.body == 'jwt expired') {
      return Future.error('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      List<Comment> comments = [];
      var responseData = json.decode(response.body);
      for (var everycomment in responseData) {
        Comment comment = Comment.fromJson(everycomment);
        comments.add(comment);
      }
      return comments;
    }
  }

  Future<Comment> viewCommentRequest(int commentid) async {
    String url = 'https://ichthyolog.onrender.com/comments/$commentid';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.body == 'Comment not found') {
      return Future.error('Comment Not Found');
    } else if (response.statusCode != 200) {
      return Future.error('Error');
    } else {
      return Comment.fromJson(json.decode(response.body)[0]);
    }
  }

  Future<String> addCommentRequest(
      int postid, String content, bool authorexpert, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/comment';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{
        'postid': postid,
        'content': content,
        'authorexpert': authorexpert
      }),
    );
    if (response.statusCode == 201) {
      return ('Comment Posted');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Comment Post Failed');
    }
  }

  Future<String> addIdSuggestionRequest(
      int postid, String content, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/comment/idsuggestion';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body:
          json.encode(<String, dynamic>{'postid': postid, 'content': content}),
    );
    if (response.statusCode == 201) {
      return ('ID suggestion posted successfully!');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('ID suggestion failed to post :(');
    }
  }

  Future<String> acceptIdSuggestionRequest(
    int postid,
    int commentid,
    String content,
    String jwt,
  ) async {
    String class_ = '';
    String order = '';
    String family = '';
    String genus = '';
    String species = '';

    final speciesRecord = singaporeRecords.singleWhere(
        (record) => '${record.commonNames} (${record.species})' == content,
        orElse: () {
      return SpeciesRecord(
          class_: '',
          order: '',
          family: '',
          genus: '',
          species: '',
          commonNames: '');
    });
    content = (content.split('(')[0].split(', ')[0]).trim();

    if (speciesRecord.class_ != '' &&
        speciesRecord.order != '' &&
        speciesRecord.family != '' &&
        speciesRecord.genus != '') {
      class_ = speciesRecord.class_;
      order = speciesRecord.order;
      family = speciesRecord.family;
      genus = speciesRecord.genus;
      species = speciesRecord.species;
    }

    String urlComment =
        'https://ichthyolog.onrender.com/comment/$commentid/idsuggestion/accept';
    String urlClass = 'https://ichthyolog.onrender.com/post/$postid/class';
    String urlOrder = 'https://ichthyolog.onrender.com/post/$postid/order';
    String urlFamily = 'https://ichthyolog.onrender.com/post/$postid/family';
    String urlGenus = 'https://ichthyolog.onrender.com/post/$postid/genus';
    String urlSpecies = 'https://ichthyolog.onrender.com/post/$postid/species';

    var responseClass = await http.put(Uri.parse(urlClass),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'_class': class_}));
    var responseOrder = await http.put(Uri.parse(urlOrder),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'order': order}));
    var responseFamily = await http.put(Uri.parse(urlFamily),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'family': family}));
    var responseGenus = await http.put(Uri.parse(urlGenus),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'genus': genus}));
    var responseSpecies = await http.put(Uri.parse(urlSpecies),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{'species': species}));

    var responseComment = await http.put(
      Uri.parse(urlComment),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body:
          json.encode(<String, dynamic>{'postid': postid, 'content': content}),
    );

    if (responseComment.body == 'Approved ID already exists') {
      return ('Approved ID Already Exists');
    } else if (responseComment.body == 'Post not found' ||
        responseClass.body == 'Post not found' ||
        responseOrder.body == 'Post not found' ||
        responseFamily.body == 'Post not found' ||
        responseGenus.body == 'Post not found' ||
        responseSpecies.body == 'Post not found') {
      return ('Post Not Found');
    } else if (responseComment.body == 'jwt expired' ||
        responseClass.body == 'jwt expired' ||
        responseOrder.body == 'jwt expired' ||
        responseFamily.body == 'jwt expired' ||
        responseGenus.body == 'jwt expired' ||
        responseSpecies.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (responseComment.statusCode != 200) {
      return ('SUggestion Edit Error :(');
    } else if (responseClass.statusCode != 200) {
      return ('Class Edit Error :(');
    } else if (responseOrder.statusCode != 200) {
      return ('Order Edit Error :(');
    } else if (responseFamily.statusCode != 200) {
      return ('Family Edit Error :(');
    } else if (responseGenus.statusCode != 200) {
      return ('Genus Edit Error :(');
    } else if (responseSpecies.statusCode != 200) {
      return ('Species Edit Error :(');
    } else {
      return ('ID Suggestion Accepted');
    }
  }

  Future<String> rejectIdSuggestionRequest(
      int commentid, String jwt, String rejectionReason) async {
    String url =
        'https://ichthyolog.onrender.com/comment/$commentid/idsuggestion/reject';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{'rejectionreason': rejectionReason}),
    );
    if (response.body == 'Suggestion not found') {
      return ('ID Suggestion Not Found');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return ('Error');
    } else {
      return ('ID Suggestion Rejected');
    }
  }

  Future<String> editCommentRequest(
      int commentid, String content, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/comment/$commentid';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{'content': content}),
    );
    if (response.body == 'Comment not found') {
      return ('Comment Not Found');
    } else if (response.statusCode != 200) {
      return ('Error');
    } else {
      return ('Comment Edited');
    }
  }

  Future<String> deleteUserRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/user';
    var response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('User Deleted');
    } else {
      return ('User Deletion Failed');
    }
  }

  Future<String> deletePostRequest(int postid, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/post/$postid';
    var response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Post Deleted');
    } else {
      return ('Post Failed to Delete :(');
    }
  }

  Future<String> deleteCommentRequest(int commentid, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/comment/$commentid';
    var response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Comment Deleted');
    } else {
      return ('Comment Deletion Failed');
    }
  }

  Future<String> verifyPostRequest(int postid, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/post/$postid/verify';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Post Verified');
    } else {
      return ('Post Verification Failed');
    }
  }

  Future<String> flagPostRequest(int postid, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/post/$postid/flag';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Post Flagged');
    } else {
      return ('Post Flagging Failed');
    }
  }

  Future<String> unFlagPostRequest(int postid, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/post/$postid/unflag';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Post Unflagged');
    } else {
      return ('Post Unflagging Failed');
    }
  }

  Future<String> upVoteCommentRequest(
      int commentid, int authorid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/comment/$commentid/$authorid/upvote';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Comment Upvoted');
    } else {
      return ('Comment Upvoting Failed');
    }
  }

  Future<String> unUpVoteCommentRequest(
      int commentid, int authorid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/comment/$commentid/$authorid/unupvote';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Comment Un-upvoted');
    } else {
      return ('Comment Un-upvoting Failed');
    }
  }

  Future<String> downVoteCommentRequest(
      int commentid, int authorid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/comment/$commentid/$authorid/downvote';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Comment Downvoted');
    } else {
      return ('Comment Downvoting Failed');
    }
  }

  Future<String> unDownVoteCommentRequest(
      int commentid, int authorid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/comment/$commentid/$authorid/undownvote';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Comment Un-downvoted');
    } else {
      return ('Comment Un-downvoting Failed');
    }
  }

  Future<bool> checkUpvoteStatus(
      int commentid, String jwt, int authorid) async {
    String url = 'https://ichthyolog.onrender.com/upvotes/$commentid/$authorid';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'Invalid search') {
      return false;
    } else if (response.statusCode != 200) {
      return Future.error('Server error');
    } else {
      return true;
    }
  }

  Future<bool> checkDownvoteStatus(
      int commentid, String jwt, int authorid) async {
    String url =
        'https://ichthyolog.onrender.com/downvotes/$commentid/$authorid';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'Invalid search') {
      return false;
    } else if (response.statusCode != 200) {
      return Future.error('Server error');
    } else {
      return true;
    }
  }

  Future<List<Dispute>> viewDisputesRequest(int commentid) async {
    String url = 'https://ichthyolog.onrender.com/$commentid/disputes';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.body == 'Disputes not found') {
      return Future.error('Disputes not found');
    } else if (response.statusCode != 200) {
      return Future.error('Error, pleae try again');
    } else {
      List<Dispute> disputes = [];
      var responseData = json.decode(response.body);
      for (var everydispute in responseData) {
        Dispute dispute = Dispute.fromJson(everydispute);
        disputes.add(dispute);
      }
      return disputes;
    }
  }

  Future<String> addDisputeRequest(
      int commentid, String content, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/disputes';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(
          <String, dynamic>{'commentid': commentid, 'content': content}),
    );

    if (response.statusCode == 201) {
      return ('Dispute added successfully!');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Dispute failed to add :(');
    }
  }

  Future<String> editDisputeRequest(
      int disputeid, String content, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/disputes/$disputeid';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{'content': content}),
    );

    if (response.body == 'Dispute not found') {
      return ('Dispute Not Found');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return ('Error, please try again');
    } else {
      return ('Dispute Edited');
    }
  }

  Future<String> deleteDisputeRequest(
      int commentid, int disputeid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/$commentid/disputes/$disputeid';
    var response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Dispute Deleted');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Dispute Deletion Failed :(');
    }
  }

  Future<String> approveDisputeRequest(
      int commentid, int disputeid, int postid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/$commentid/disputes/$disputeid/approve';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{'postid': postid}),
    );
    if (response.body == 'Dispute not found' ||
        response.body == 'ID suggestion not found' ||
        response.body == 'Post not found') {
      return response.body;
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (response.statusCode != 200) {
      return ('Error, please try again');
    } else {
      return ('Dispute approved successfully');
    }
  }

  Future<List<ExpertApplicationRequest>> viewAllExpertApplicationsRequest(
      String jwt) async {
    String url = 'https://ichthyolog.onrender.com/expertapplications';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );

    if (response.body == 'Applications not found') {
      return Future.error(response.body);
    } else if (response.statusCode != 200) {
      return Future.error('Error, pleae try again');
    } else {
      List<ExpertApplicationRequest> requests = [];
      var responseData = json.decode(response.body);
      for (var everyrequest in responseData) {
        ExpertApplicationRequest request =
            ExpertApplicationRequest.fromJson(everyrequest);
        requests.add(request);
      }
      return requests;
    }
  }

  Future<List<ExpertApplicationRequest>> viewOwnExpertApplicationsRequest(
      int authorid, String jwt) async {
    String url = 'https://ichthyolog.onrender.com/$authorid/expertapplications';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );

    if (response.body == 'Applications not found') {
      return Future.error(response.body);
    } else if (response.statusCode != 200) {
      return Future.error('Error, pleae try again');
    } else {
      List<ExpertApplicationRequest> requests = [];
      var responseData = json.decode(response.body);
      for (var everyrequest in responseData) {
        ExpertApplicationRequest request =
            ExpertApplicationRequest.fromJson(everyrequest);
        requests.add(request);
      }
      return requests;
    }
  }

  Future<String> addExpertApplicationRequest(
      int authorid,
      String name,
      int age,
      String gender,
      String occupation,
      String email,
      int contact,
      String credentials,
      String jwt) async {
    String url = 'https://ichthyolog.onrender.com/expertapplications';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{
        'authorid': authorid,
        'name': name,
        'age': age,
        'gender': gender,
        'occupation': occupation,
        'email': email,
        'contact': contact,
        'credentials': credentials,
      }),
    );
    if (response.statusCode == 201) {
      return ('Application added successfully!');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else if (response.body == 'Existing requests need to be processed') {
      return ('Please wait for exisiting application to be processed!');
    } else {
      return ('Application failed to add :(');
    }
  }

  Future<String> approveExpertApplicationRequest(
      int authorid, int applicationid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/$authorid/expertapplications/$applicationid';
    var response = await http.put(Uri.parse(url), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorisation': jwt
    });
    if (response.statusCode == 200) {
      return ('Application approved successfully!');
    } else if (response.body == 'Application not found') {
      return response.body;
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Application failed to approve :(');
    }
  }

  Future<String> rejectExpertApplicationRequest(
      int applicationid, String rejectionReason, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/expertapplications/$applicationid';
    var response = await http.put(Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorisation': jwt
        },
        body: json.encode(<String, dynamic>{
          'rejectionreason': rejectionReason,
        }));
    if (response.statusCode == 200) {
      return ('Application rejected successfully!');
    } else if (response.body == 'Application not found') {
      return response.body;
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Application failed to rejecte :(');
    }
  }

  Future<String> deleteExpertApplicationRequest(
      int applicationid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/expertapplications/$applicationid';
    var response = await http.delete(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Application deleted successfully!');
    } else if (response.body == 'Application not found') {
      return response.body;
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Application Deletion Failed :(');
    }
  }

// statistics request
  Future<List<String>> searchAll(
      String startTime, String endTime, String sightinglocation) async {
    var url = Uri.https('ichthyolog.onrender.com', '/statistics/all', {
      'sightingLocation': sightinglocation,
    });
    var response = await http.get(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    if (response.statusCode == 200) {
      List<String> speciesList = [];
      var responseData = json.decode(response.body);
      for (var everyspecies in responseData) {
        speciesList.add(everyspecies['title']);
      }
      return speciesList;
    } else {
      print('Error ${response.statusCode}');
      return Future.error('Error ${response.statusCode}');
    }
  }

  Future<List<String>> searchSpeciesName(String species, String startTime,
      String endTime, String sightinglocation) async {
    if (species == '') {
      return searchAll(startTime, endTime, sightinglocation);
    }
    String url =
        'https://ichthyolog.onrender.com/statistics/speciesName/$species';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      List<String> speciesList = [];
      var responseData = json.decode(response.body);
      for (var everyspecies in responseData) {
        speciesList.add(everyspecies['title']);
      }
      return speciesList;
    } else {
      return Future.error('Family not found! Error ${response.statusCode}');
    }
  }

  Future<List<String>> searchSpecies(String species, String startTime,
      String endTime, String sightinglocation) async {
    var uri =
        Uri.https('ichthyolog.onrender.com', '/statistics/species/$species', {
      'species': species,
      'startTime': startTime,
      'endTime': endTime,
      'sightingLocation': sightinglocation,
    });

    var response = await http.get(uri, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });

    if (response.statusCode == 200) {
      List<String> dataList = [];
      var responseData = json.decode(response.body);
      dataList.add(responseData['count'].toString());
      dataList.add(responseData['latest_sightingtime'].toString());
      dataList.add(responseData['latest_sightinglocation'].toString());
      return dataList;
    } else {
      return Future.error('Species not found! Error ${response.statusCode}');
    }
  }

  Future<List<String>> searchClassification(
      String class_,
      String order,
      String family,
      String genus,
      String startTime,
      String endTime,
      String sightinglocation) async {
    if (class_ == '' && order == '' && family == '' && genus == '') {
      return searchAll(startTime, endTime, sightinglocation);
    } else if (class_ != '' && order == '' && family == '' && genus == '') {
      return searchClass(class_, startTime, endTime, sightinglocation);
    } else if (order != '' && family == '' && genus == '') {
      return searchOrder(order, startTime, endTime, sightinglocation);
    } else if (family != '' && genus == '') {
      return searchFamily(family, startTime, endTime, sightinglocation);
    } else if (genus != '') {
      return searchGenus(genus, startTime, endTime, sightinglocation);
    } else {
      return Future.error('Classification not found!');
    }
  }

  Future<List<String>> searchClass(String class_, String startTime,
      String endTime, String sightinglocation) async {
    var url =
        Uri.https('ichthyolog.onrender.com', '/statistics/class/$class_', {
      'class_': class_,
      'sightingLocation': sightinglocation,
    });
    var response = await http.get(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    if (response.statusCode == 200) {
      List<String> speciesList = [];
      var responseData = json.decode(response.body);
      for (var everyspecies in responseData) {
        speciesList.add(everyspecies['title']);
      }
      return speciesList;
    } else {
      return Future.error('Class not found! Error ${response.statusCode}');
    }
  }

  Future<List<String>> searchOrder(String order, String startTime,
      String endTime, String sightinglocation) async {
    var url = Uri.https('ichthyolog.onrender.com', '/statistics/order/$order', {
      'order': order,
      'sightingLocation': sightinglocation,
    });
    var response = await http.get(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    if (response.statusCode == 200) {
      List<String> speciesList = [];
      var responseData = json.decode(response.body);
      for (var everyspecies in responseData) {
        speciesList.add(everyspecies['title']);
      }
      return speciesList;
    } else {
      return Future.error('Order not found! Error ${response.statusCode}');
    }
  }

  Future<List<String>> searchFamily(String family, String startTime,
      String endTime, String sightinglocation) async {
    var url =
        Uri.https('ichthyolog.onrender.com', '/statistics/family/$family', {
      'family': family,
      'sightingLocation': sightinglocation,
    });
    var response = await http.get(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    if (response.statusCode == 200) {
      List<String> speciesList = [];
      var responseData = json.decode(response.body);
      for (var everyspecies in responseData) {
        speciesList.add(everyspecies['title']);
      }
      return speciesList;
    } else {
      return Future.error('Family not found! Error ${response.statusCode}');
    }
  }

  Future<List<String>> searchGenus(String genus, String startTime,
      String endTime, String sightinglocation) async {
    var url = Uri.https('ichthyolog.onrender.com', '/statistics/genus/$genus', {
      'genus': genus,
      'sightingLocation': sightinglocation,
    });
    var response = await http.get(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    if (response.statusCode == 200) {
      List<String> speciesList = [];
      var responseData = json.decode(response.body);
      for (var everyspecies in responseData) {
        speciesList.add(everyspecies['title']);
      }
      return speciesList;
    } else {
      return Future.error('Genus not found! Error ${response.statusCode}');
    }
  }

  Future<List<List<String>>> searchFamilyCatalogue() async {
    String url = 'https://ichthyolog.onrender.com/catalogue/family';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      List<List<String>> familyList = [];
      var responseData = json.decode(response.body);
      for (var everyfamily in responseData) {
        List<String> family = [];
        if (everyfamily['family'] == '') {
          family.add('Unknown');
        } else {
          family.add(everyfamily['family'].toString());
        }
        family.add(everyfamily['species_count'].toString());
        familyList.add(family);
      }
      return familyList;
    } else {
      print(response.body);
      throw Exception('Family not found! Error ${response.statusCode}');
    }
  }

  Future<List<List<String>>> searchGenusCatalogue() async {
    String url = 'https://ichthyolog.onrender.com/catalogue/genus';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      List<List<String>> genusList = [];
      var responseData = json.decode(response.body);
      for (var everygenus in responseData) {
        List<String> genus = [];
        if (everygenus['genus'] == '') {
          genus.add('Unknown');
        } else {
          genus.add(everygenus['genus'].toString());
        }
        genus.add(everygenus['species_count'].toString());
        genusList.add(genus);
      }
      return genusList;
    } else {
      print(response.body);
      throw Exception('Genus not found! Error ${response.statusCode}');
    }
  }

  Future<List<List<String>>> searchOrderCatalogue() async {
    String url = 'https://ichthyolog.onrender.com/catalogue/order';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      List<List<String>> orderList = [];
      var responseData = json.decode(response.body);
      for (var everyorder in responseData) {
        List<String> order = [];
        if (everyorder['_order'] == '') {
          order.add('Unknown');
        } else {
          order.add(everyorder['_order'].toString());
        }
        order.add(everyorder['species_count'].toString());
        orderList.add(order);
      }
      return orderList;
    } else {
      print(response.body);
      throw Exception('Order not found! Error ${response.statusCode}');
    }
  }

  Future<List<List<String>>> searchClassCatalogue() async {
    String url = 'https://ichthyolog.onrender.com/catalogue/class';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      List<List<String>> classList = [];
      var responseData = json.decode(response.body);
      for (var everyclass in responseData) {
        List<String> class_ = [];
        if (everyclass['class'] == '') {
          class_.add('Unknown');
        } else {
          class_.add(everyclass['class'].toString());
        }
        class_.add(everyclass['species_count'].toString());
        classList.add(class_);
      }
      return classList;
    } else {
      print(response.body);
      throw Exception('Class not found! Error ${response.statusCode}');
    }
  }

  Future<List<List<String>>> speciesCountByDay(String species) async {
    String url = 'https://ichthyolog.onrender.com/statistics/hour/$species';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<List<String>> dataList = [];
      var responseData = json.decode(response.body);
      for (var everydata in responseData) {
        List<String> data = [];
        data.add(everydata['hour_interval']
            .toString()
            .substring(0, 16)
            .replaceAll("T", " "));
        data.add(everydata['sightings_count'].toString());
        dataList.add(data);
      }
      return dataList;
    } else {
      return Future.error('Error ${response.statusCode} Day');
    }
  }

  Future<List<List<String>>> speciesCountByWeek(String species) async {
    String url = 'https://ichthyolog.onrender.com/statistics/week/$species';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<List<String>> dataList = [];
      var responseData = json.decode(response.body);
      for (var everydata in responseData) {
        List<String> data = [];
        data.add(
            everydata['day'].toString().substring(0, 10).replaceAll("T", " "));
        data.add(everydata['sightings_count'].toString());
        dataList.add(data);
      }
      return dataList;
    } else {
      return Future.error('Error ${response.statusCode} Week');
    }
  }

  Future<List<List<String>>> speciesCountByMonth(String species) async {
    String url = 'https://ichthyolog.onrender.com/statistics/month/$species';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<List<String>> dataList = [];
      var responseData = json.decode(response.body);
      for (var everydata in responseData) {
        List<String> data = [];
        data.add(
            everydata['date'].toString().substring(0, 10).replaceAll("T", " "));
        data.add(everydata['species_count'].toString());
        dataList.add(data);
      }
      return dataList;
    } else {
      return Future.error('Error ${response.statusCode} Month');
    }
  }

  Future<List<List<List<String>>>> speciesCountStats(String species) async {
    Future<List<List<List<String>>>> dataList = Future.wait([
      speciesCountByDay(species),
      speciesCountByWeek(species),
      speciesCountByMonth(species)
    ]);
    return dataList;
  }

  Future<List<CommentNotification>> viewNotificationsRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/notifications';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );

    if (response.body == 'Notifications not found') {
      return Future.error(response.body);
    } else if (response.statusCode != 200) {
      return Future.error('Error, pleae try again');
    } else {
      List<CommentNotification> notifications = [];
      var responseData = json.decode(response.body);
      for (var everyNotification in responseData) {
        CommentNotification notification =
            CommentNotification.fromJson(everyNotification);
        notifications.add(notification);
      }
      return notifications;
    }
  }

  Future<int> countUnviewedNotificationsRequest(String jwt) async {
    String url = 'https://ichthyolog.onrender.com/notifications/unviewed';
    var response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.body == 'Notifications not found') {
      return 0;
    } else if (response.statusCode != 200) {
      return Future.error('Error, pleae try again');
    } else {
      return json.decode(response.body);
    }
  }

  Future<String> createNotificationRequest(
    String receiverUsername,
    String notificationContent,
    int postid,
    String jwt,
  ) async {
    String url = 'https://ichthyolog.onrender.com/notifications';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
      body: json.encode(<String, dynamic>{
        'receipient': receiverUsername,
        'content': notificationContent,
        'postid': postid,
      }),
    );
    if (response.statusCode == 201) {
      return ('Notification Created');
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Notification Creation Failed');
    }
  }

  Future<String> openNotificationRequest(int notificationid, String jwt) async {
    String url =
        'https://ichthyolog.onrender.com/notifications/$notificationid';
    var response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorisation': jwt
      },
    );
    if (response.statusCode == 200) {
      return ('Notification opened successfully!');
    } else if (response.body == 'Notifications not found') {
      return response.body;
    } else if (response.body == 'jwt expired') {
      return ('Session expired. Please login again!');
    } else {
      return ('Notifications failed to open :(');
    }
  }
}

checkBlank(String value) {
  if (value == '') {
    print('$value: true');
  } else {
    return print('$value: false');
  }
}
