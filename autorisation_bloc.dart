import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:walkscreen/helpers/dialogs.dart';
import 'package:walkscreen/helpers/helpers.dart';
import 'package:walkscreen/helpers/requests.dart';
import 'package:walkscreen/repos/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'autorisation_event.dart';
part 'autorisation_state.dart';

class AutorisationBloc extends Bloc<AutorisationEvent, AutorisationState> {
  bool _hasAuth = false;

  AutorisationBloc() : super(AutorisationInitial(false));

  bool getAuthStatus() {
    return _hasAuth;
  }

 

  Stream<AutorisationState> enterInProfile() async* {
    var onlyNum = Helpers.getOnlyNumber(UserRepository.number);
    if (onlyNum.length != 11) {
      Dialogs.showWarningDialog('Ошибка ввода', 'Номер ввведён некорректно');
      return;
    }
    if (UserRepository.password.length == 0) {
      Dialogs.showWarningDialog('Ошибка ввода', 'Пароль не введён');
      return;
    }

    if (UserRepository.password.length < 8) {
      Dialogs.showWarningDialog(
          'Ошибка авторизации', 'Пароль должен содержать не менее 8 символов');
      return;
    }

    var r = RegExp('[A-Za-zА-Яа-я]');
    if (!r.hasMatch(UserRepository.password)) {
      Dialogs.showWarningDialog(
          'Ошибка авторизации', 'Пароль должен содержать хотя бы одну букву');
      return;
    }

    yield StartLoadingState(_hasAuth, );
    //если есть соединение

    _hasAuth = await Requests.enterInProfile(UserRepository.number, UserRepository.password);

    yield FinishLoadingState(_hasAuth, );
    yield AutorisationInitial(_hasAuth, );
  }

  Stream<AutorisationState> register(String code) async* {
    yield StartLoadingState(_hasAuth, );
    _hasAuth =
        await Requests.register(UserRepository.regNumber, UserRepository.regPassword, code);
    if (_hasAuth) {
      UserRepository.number = UserRepository.regNumber;
      UserRepository.password = UserRepository.regPassword;
      await UserRepository.persistNumber(UserRepository.number);
      await UserRepository.persistPassword(UserRepository.password);
    }
    yield FinishLoadingState(_hasAuth, );
    yield LoadDataState(_hasAuth, );
  }

  Stream<AutorisationState> getOTP(bool isFirst) async* {
    if (Helpers.getOnlyNumber(UserRepository.regNumber).length != 11) {
      Dialogs.showWarningDialog('Ошибка регистрации', 'Номер введён неправильно');
      return;
    }

    if (UserRepository.regPassword.length < 8) {
      Dialogs.showWarningDialog(
          'Ошибка регистрации', 'Пароль должен содержать не менее 8 символов');
      return;
    }

    var r = RegExp('[A-Za-zА-Яа-я]');
    if (!r.hasMatch(UserRepository.regPassword)) {
      Dialogs.showWarningDialog(
          'Ошибка регистрации', 'Пароль должен содержать хотя бы одну букву');
      return;
    }

    //кнопка "Создать аккаунт"
    if (UserRepository.regPassword != UserRepository.confirmedPassword) //проверка подтверждения пароля
    {
      Dialogs.showWarningDialog('Ошибка регистрации', 'Введённые пароли не совпадают');
      return;
    }


    yield StartLoadingState(_hasAuth, );
    await Requests.getOTP(UserRepository.regNumber, isFirst);
    yield FinishLoadingState(_hasAuth, );
  }

  Stream<AutorisationState> logOut() async* {
    _hasAuth = false;
    yield StartLoadingState(_hasAuth, );
    await Requests.logout();
    yield FinishLoadingState(_hasAuth, );
    yield LogOutState(_hasAuth);
  }

  @override
  Stream<AutorisationState> mapEventToState(
    AutorisationEvent event,
  ) async* {
    if (event is LogOut) {
      yield* logOut();
    } else if (event is EnterInProfile) {
      //запрос login /нажатие на "Войти"
      yield* enterInProfile();
    } else if (event is Register) {
      yield* register(event.code);
    } else if (event is GetOTP) {
      //запрос на получение кода подтверждения - нажатие на "Создать аккаунт"
      yield* getOTP(event.isFirst);
    } else if (event is AuthStatusChanged) {
      _hasAuth = event.hasAuth;
      yield AutorisationInitial(_hasAuth, );
    }  else if (event is LoadData) {
      if (await UserRepository.hasPassword()) {
        UserRepository.password = await UserRepository.getPassword();
      }
      if (await UserRepository.hasNumber()) {
        UserRepository.number = await UserRepository.getNumber();
      }
      yield LoadDataState(_hasAuth, );
    }
    if (event is FinishLoadData) {
      yield AutorisationInitial(_hasAuth, );
    }
  }
}
//Используем один н
