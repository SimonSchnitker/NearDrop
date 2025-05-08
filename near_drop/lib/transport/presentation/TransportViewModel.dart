import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:near_drop/transport/domain/enums/SendResponse.dart';
import '../../core/entity/Device.dart';
import '../domain/TransportController.dart';

class TransportViewModel extends ChangeNotifier
{
    final _transportController = KiwiContainer().resolve<TransportController>();

    void init()
    {
        _transportController.startSignalingListening();
    }

    Future<SendResponse> sendFiles(Device device, List<File> files) async
    {
        return await _transportController.sendFiles(device, files);
    }
}