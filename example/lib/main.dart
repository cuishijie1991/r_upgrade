import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_upgrade/r_upgrade.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int id;

  GlobalKey<ScaffoldState> _state=GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _state,
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          children: <Widget>[
            Container(
                height: 200,
                alignment: Alignment.center,
                padding: EdgeInsets.all(8),
                child: id!=null?StreamBuilder(
                  stream: RUpgrade.stream,
                  builder: (BuildContext context,
                      AsyncSnapshot<DownloadInfo> snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('正在下载'),
                              Text(
                                  '${snapshot.data.planTime.toStringAsFixed(0)}s后完成'),
                            ],
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LinearProgressIndicator(
                              value: snapshot.data.percent == 0
                                  ? null
                                  : snapshot.data.percent / 100,
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('${snapshot.data.percent}%'),
                              Text(
                                  '${snapshot.data.speed.toStringAsFixed(2)}kb/s'),
                            ],
                          ),
                          Text('${getStatus(snapshot.data.status)}'),
                        ],
                      );
                    } else {
                      return Text('等待下载');
                    }
                  },
                ):Text('等待下载')),
            ListTile(
              title: Center(child: Text('开始更新')),
              onTap: () async {
                if(!await canReadStorage()) return;

                id = await RUpgrade.upgrade(
                    'https://raw.githubusercontent.com/rhymelph/r_upgrade/master/apk/app-release.apk',
                    apkName: 'app-release.apk');
                setState(() {});
              },
            ),
            ListTile(
              title: Center(child: Text('取消更新')),
              onTap: () async {
                bool isSuccess = await RUpgrade.cancel(id);
                if(isSuccess){
                  _state.currentState.showSnackBar(SnackBar(content: Text('取消成功')));
                  id=null;
                  setState(() {});
                }
                print('cancel');
              },
            ),
            ListTile(
              title: Center(child: Text('安装apk')),
              onTap: () async {
                bool isSuccess = await RUpgrade.install(id);
                if(isSuccess){
                  _state.currentState.showSnackBar(SnackBar(content: Text('请求成功')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String getStatus(DownloadStatus status) {
    if (status == DownloadStatus.STATUS_FAILED) {
      return "下载失败";
    } else if (status == DownloadStatus.STATUS_PAUSED) {
      return "下载暂停";
    } else if (status == DownloadStatus.STATUS_PENDING) {
      return "获取资源中";
    } else if (status == DownloadStatus.STATUS_RUNNING) {
      return "下载中";
    } else if (status == DownloadStatus.STATUS_SUCCESSFUL) {
      return "下载成功";
    } else {
      return "未知";
    }
  }

  Future<bool> canReadStorage() async {
    if(Platform.isIOS) return true;
    var status = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (status != PermissionStatus.granted) {
      var future = await PermissionHandler()
          .requestPermissions([PermissionGroup.storage]);
      for (final item in future.entries) {
        if (item.value != PermissionStatus.granted) {
          return false;
        }
      }
    } else {
      return true;
    }
    return true;
  }
}
