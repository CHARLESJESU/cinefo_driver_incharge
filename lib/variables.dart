import 'package:flutter/material.dart';

Map? baseurlresponsebody;
Map? baseurlresult;
TextEditingController loginmobilenumber = TextEditingController();
TextEditingController loginpassword = TextEditingController();

Map? loginresult;
String? location;
bool isoffline = false;
Map? getdeviceidresponse;

String? productionHouse;
String? projectId;
String? managerName;
Map? passProjectidresponse;
String? registeredMovie;
int? callsheetid;
String? projectid;
int? productionTypeId;
List<dynamic> movieProjects = [];
String? selectedProjectId;
String? selectedProjectTitle;
Map? shiftresponse1;
String? vcid;
String? vsid;
List<Map<String, dynamic>> updatedDubbingConfigs = [];
List<Map<String, dynamic>> dubbingConfigs = [];
int mainCharacter = 0;
int smallCharacter = 0;
int bitCharacter = 0;
int group = 0;
int fight = 0;
int mainCharacterOtherLanguage = 0;
int smallCharacterOtherLanguage = 0;
int bitCharacterOtherLanguage = 0;
int groupOtherLanguage = 0;
int fightOtherLanguage = 0;
int voicetest = 0;
int leadRole = 0;
int secondLeadRole = 0;
int leadRoleOtherLanguage = 0;
int secondLeadRoleOtherLanguage = 0;
final processRequest =
    Uri.parse('https://vgate.vframework.in/vgateapi/processRequest');
final processSessionRequest =
    Uri.parse('https://vgate.vframework.in/vgateapi/processSessionRequest');

Map? closecallsheetresponse;
Map<String, int> dubbingConfigStates = {};
Map<String, int> finalDoubingMap = {};

// Charles made Variables
Map? baseurlresultbody;
Map? loginresponsebody;
String? ProfileImage;
String? Platformlogo;
String? vpid;
int? vmid;
int? vuid;
int? mtypeId;
int? vmTypeId;
int? vpoid;
int? vbpid;
int? vsubid;
int? vpidpo;
int? vpidbp;
int? unitid;
String? companyName;
String? createdBy;
String? email;
String? unitName;
String? idcardurl;
