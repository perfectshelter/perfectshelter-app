import 'package:perfectshelter/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteMessageState {}

class DeleteMessageInitial extends DeleteMessageState {}

class DeleteMessageInProgress extends DeleteMessageState {}

class DeleteMessageSuccess extends DeleteMessageState {
  DeleteMessageSuccess({
    required this.id,
  });
  final String id;
}

class DeleteMessageFail extends DeleteMessageState {
  DeleteMessageFail({
    required this.error,
  });
  dynamic error;
}

class DeleteMessageCubit extends Cubit<DeleteMessageState> {
  DeleteMessageCubit() : super(DeleteMessageInitial());

  Future<void> delete({
    required String messageId,
    required String receiverId,
    required String senderId,
    required String propertyId,
  }) async {
    try {
      emit(DeleteMessageInProgress());
      final parameters = {
        'message_id': messageId,
        'receiver_id': receiverId,
        'sender_id': senderId,
        'property_id': propertyId,
      }..removeWhere((key, value) => value == '');
      await Api.post(
        url: Api.deleteChatMessage,
        parameter: parameters,
      );

      emit(DeleteMessageSuccess(id: messageId));
    } on ApiException catch (e) {
      emit(DeleteMessageFail(error: e.toString()));
    }
  }
}
