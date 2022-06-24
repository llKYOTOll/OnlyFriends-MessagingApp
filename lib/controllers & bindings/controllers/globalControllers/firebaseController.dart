import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:only_friends/controllers%20&%20bindings/controllers/globalControllers/authenticationController.dart';
import 'package:only_friends/data/models/chatChannelModel.dart';
import 'package:only_friends/data/models/userModel.dart';
import 'package:uuid/uuid.dart';

class FirebaseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthenticationController authenticationController = Get.find();

  Future<String> addAContact({
    required String OnlyFriendId,
  }) async {
    try {
      if (authenticationController.userModel!.friendList
          .contains(OnlyFriendId)) {
        return "You're already friends with this user!";
      } else {
        QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .where('userUniqueId', isEqualTo: OnlyFriendId)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          UserModel friendUserModel =
              UserModel.fromSnapshot(querySnapshot.docs[0]);
          await _firestore.collection('users').doc(friendUserModel.uid).update({
            'friendList': FieldValue.arrayUnion(
                [authenticationController.userModel!.userUniqueId])
          });
          await _firestore
              .collection('users')
              .doc(authenticationController.userModel!.uid)
              .update({
            'friendList': FieldValue.arrayUnion([friendUserModel.userUniqueId])
          });
          return "Success";
        } else {
          return "No User Found!";
        }
      }
    } on FirebaseException catch (error) {
      return error.message.toString();
    } catch (error) {
      return "An error occurred!";
    }
  }

  Future<String> startANewChatChannel(
      {required String friendUid, required String userUid}) async {
    try {
      String chatChannelId = Uuid().v1();
      ChatChannelModel chatChannelModel = ChatChannelModel.name(
        chatChannelId: chatChannelId,
        users: [
          userUid,
          friendUid,
        ],
      );
      await _firestore
          .collection('chatChannels')
          .doc(chatChannelId)
          .set(chatChannelModel.toJson());
      await _firestore.collection('users').doc(userUid).update({
        'chatChannels': FieldValue.arrayUnion([chatChannelId])
      });
      await _firestore.collection('users').doc(friendUid).update({
        'chatChannels': FieldValue.arrayUnion([chatChannelId])
      });
      return "Success";
    } on FirebaseException catch (error) {
      return error.message.toString();
    } catch (error) {
      return "An error occurred!";
    }
  }
}