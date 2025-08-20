// // Modified version with language tabs for property title & description
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';

// class AddPropertyDetails extends StatefulWidget {
//   @override
//   _AddPropertyDetailsState createState() => _AddPropertyDetailsState();
// }

// class _AddPropertyDetailsState extends State<AddPropertyDetails> with TickerProviderStateMixin {
//   late TabController _tabController;
//   Map<String, Map<String, String>> translatedFields = {}; // language_id -> {title, description}
//   List<LanguageModel> languages = []; // Fill this from LanguageSelector

//   @override
//   void initState() {
//     super.initState();
//     languages = LanguageSelector.getLanguages();
//     _tabController = TabController(length: languages.length, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Add Property")),
//       body: Column(
//         children: [
//           TabBar(
//             controller: _tabController,
//             isScrollable: true,
//             tabs: languages.map((lang) => Tab(text: lang.name)).toList(),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: languages.map((lang) {
//                 final langId = lang.id.toString();

//                 return Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       TextFormField(
//                         initialValue: translatedFields[langId]?['title'] ?? '',
//                         decoration: InputDecoration(labelText: "Property Title (${lang.name})"),
//                         onChanged: (value) {
//                           setState(() {
//                             translatedFields[langId] ??= {};
//                             translatedFields[langId]!['title'] = value;
//                           });
//                         },
//                       ),
//                       SizedBox(height: 16),
//                       TextFormField(
//                         initialValue: translatedFields[langId]?['description'] ?? '',
//                         decoration: InputDecoration(labelText: "Property Description (${lang.name})"),
//                         onChanged: (value) {
//                           setState(() {
//                             translatedFields[langId] ??= {};
//                             translatedFields[langId]!['description'] = value;
//                           });
//                         },
//                         maxLines: 4,
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _submitForm,
//             child: Text("Submit"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _submitForm() {
//     final translations = translatedFields.entries.map((entry) {
//       final languageId = entry.key;
//       final values = entry.value;

//       return {
//         "language_id": languageId,
//         "title": values["title"] ?? "",
//         "description": values["description"] ?? "",
//       };
//     }).toList();

//     FormData formData = FormData.fromMap({
//       "translations": translations,
//     });

//     // TODO: Send formData to backend via Dio or your API call handler
//     print(formData.fields);
//   }
// }
