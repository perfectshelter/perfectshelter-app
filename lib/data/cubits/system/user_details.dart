import 'package:perfectshelter/data/model/user_model.dart';
import 'package:perfectshelter/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailsCubit extends Cubit<UserDetailsState> {
  UserDetailsCubit()
      : super(
          UserDetailsState(
            user: HiveUtils.isGuest() ? null : HiveUtils.getUserDetails(),
          ),
        );

  void fill(UserModel model) {
    emit(UserDetailsState(user: model));
  }

  void copy(UserModel model) {
    emit(state.copyWith(user: model));
  }

  void clear() {
    emit(UserDetailsState(user: null));
  }
}

class UserDetailsState {
  UserDetailsState({
    required this.user,
  });
  final UserModel? user;

  UserDetailsState copyWith({
    UserModel? user,
  }) {
    return UserDetailsState(
      user: user ?? this.user,
    );
  }
}
