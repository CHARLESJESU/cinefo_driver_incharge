// import 'package:flutter/foundation.dart';

// class DubbingConfig {
//   final String id;
//   final String name;
//   int status;
//   int count;

//   DubbingConfig({
//     required this.id,
//     required this.name,
//     this.status = 0,
//     this.count = 0,
//   });
// }

// class DubbingConfigProvider with ChangeNotifier {
//   List<DubbingConfig> configs = [];

//   DubbingConfigProvider();

//   factory DubbingConfigProvider.fromConfigs(List<Map<String, dynamic>> raw) {
//     return DubbingConfigProvider()
//       ..configs = raw
//           .map((c) => DubbingConfig(
//                 id: c['dubbingConfigName'],
//                 name: c['dubbingConfigName'],
//                 status: 0,
//                 count: 0,
//               ))
//           .toList();
//   }

//   void toggleSelection(String id, bool selected) {
//     final config = configs.firstWhere((c) => c.id == id);
//     config.status = selected ? 1 : 0;
//     notifyListeners();
//   }

//   void rejectConfig(String id) {
//     final config = configs.firstWhere((c) => c.id == id);
//     config.status = -1;
//     notifyListeners();
//   }

//   void incrementCount(String id) {
//     final config = configs.firstWhere((c) => c.id == id);
//     config.count += 1;
//     notifyListeners();
//   }

//   void decrementCount(String id) {
//     final config = configs.firstWhere((c) => c.id == id);
//     if (config.count > 0) {
//       config.count -= 1;
//       notifyListeners();
//     }
//   }

//   Map<String, int> getSelectedStates() {
//     final Map<String, int> result = {};
//     for (var config in configs) {
//       result[config.name] =
//           config.name.toLowerCase() == "bits" ? config.count : config.status;
//     }
//     return result;
//   }
// }
