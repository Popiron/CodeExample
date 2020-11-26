import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:walkscreen/bloc/user_data_block/bloc/userdata_bloc.dart';
import 'package:walkscreen/helpers/helpers.dart';
import 'package:walkscreen/repos/user_repository.dart';
import 'package:walkscreen/main.dart';
import 'package:walkscreen/pages/fill_in_the_profile_page/fill_in_the_profile_page.dart';
import 'package:walkscreen/pages/profile_page/widgets/request_password_dialog.dart';

class ProfileInfo extends StatelessWidget {
  final double height;
  final double width;

  ProfileInfo(this.height, this.width);

  double _adaptationHeight(double myHeight) {
    return height * (myHeight / 740);
  }

  double _adaptationWidth(double myWidth) {
    return width * (myWidth / 360);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: close_sinks
    final userDataBloc = MyApp.userDataBloc;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 0.5,
          color: Color(HexColor.getColorFromHex("#E5E5E5")),
        ),
      ),
      padding: EdgeInsets.only(
          left: _adaptationWidth(10),
          bottom: _adaptationHeight(5),
          right: _adaptationWidth(15)),
      child: ListTile(
          leading: GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (ctx) => Platform.isAndroid
                      ? SimpleDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: EdgeInsets.only(
                              left: _adaptationWidth(20),
                              right: _adaptationWidth(20),
                              top: _adaptationHeight(24),
                              bottom: _adaptationHeight(24)),
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    userDataBloc.add(ChooseAvatar());
                                    Navigator.of(ctx).pop();
                                  },
                                  child: Container(
                                    width: _adaptationWidth(300),
                                    child: Text(
                                      "Загрузить фотографию",
                                      style: TextStyle(
                                        color: Theme.of(context).accentColor,
                                        fontSize: 16,
                                        fontFamily: Theme.of(context)
                                            .textTheme
                                            .body1
                                            .fontFamily,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: height * 0.027,
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                               userDataBloc.add(AddNewAvatar());
                                Navigator.of(ctx).pop();
                              },
                              child: Container(
                                width: _adaptationWidth(300),
                                child: Text(
                                  "Сделать фото",
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                    fontSize: 16,
                                    fontFamily: Theme.of(context)
                                        .textTheme
                                        .body1
                                        .fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: CupertinoActionSheet(
                              actions: [
                                CupertinoActionSheetAction(
                                  child: const Text('Загрузить фотографию'),
                                  onPressed: () {
                                   userDataBloc.add(ChooseAvatar());
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: const Text('Сделать фото'),
                                  onPressed: () {
                                   userDataBloc.add(AddNewAvatar());
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                child: const Text('Отменить'),
                                isDefaultAction: true,
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                              ))));
            },
            child: BlocBuilder<UserdataBloc, UserdataState>(
              buildWhen: (previous, current) => previous.loadingAvatar!=current.loadingAvatar||previous.avatar!=current.avatar,
              builder: (context, state) {
              return state.loadingAvatar
                  ? Platform.isAndroid
                      ? CircularProgressIndicator()
                      : CupertinoActivityIndicator()
                  : CircleAvatar(
                      backgroundColor: Theme.of(context).accentColor,
                      radius: height * 0.027,
                      backgroundImage: ResizeImage(
                        state.avatar == null
                            ? AssetImage('assets/no-avatar.png')
                            : state.avatar is File
                                ? FileImage(state.avatar)
                                : MemoryImage(state.avatar),
                        width: (height * 0.027 * 8).ceil(),
                      ),
                    );
            }),
          ),
          title: Text(
           UserRepository.userData.name + ' ' +UserRepository.userData.surname,
            style: Theme.of(context).textTheme.body1,
          ),
          subtitle: Text(
           UserRepository.userData.getStatus(),
            style: Theme.of(context)
                .textTheme
                .body2
                .apply(color: Helpers.getStatusColor(  UserRepository.userData.status)),
          ),
          trailing: GestureDetector(
            onTap: () {
              showDialog(
                builder: (ctx) => RequestPasswordDialog(height, width, context),
                context: context,
              );
            },
            child: Image.asset(
              "assets/edit.png",
              height: _adaptationHeight(27),
              width: _adaptationHeight(27),
            ),
          )),
    );
  }
}
