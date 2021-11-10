import 'package:get/get.dart';
import 'dart:io';

class EditorTableController {
  // What is my datascheme?
  // Mode 1: Columns and rows
  // Mode 2: Keys and values

  List<TabularData> tables = <TabularData>[];
  List<KeyValueData> keyVals = <KeyValueData>[];

  EditorTableController() {
    tables.add(TabularData()
      ..columnDefs.add(String)
      ..columnDefs.add(String)
      ..columnDefs.add(double));

    tables[0].rows.add({0, "Hello", "World", 3.184});
  }
}

// Supported data types will be limited to collections and primative types.
/*
    - bool
    - int
    - double
    - String
    - List
    - Map
    - Set? Sets probably aren't useful outside of internal structure.
*/

class TabularData {
  //
  List<Type> columnDefs = <Type>[];
  List<Set<Object>> rows = <Set<Object>>[];

  TabularData() {
    columnDefs.add(int); // First row will always be row ID
    // Row ID must be unique per SQL specification.
  }
}

class KeyValueData {
  //
  Map<Object, Object> keyStore = <Object, Object>{};

  KeyValueData() {
    //
  }
}
