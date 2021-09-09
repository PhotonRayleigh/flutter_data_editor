import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';

import 'package:data_editor/app/controllers/editor_table_controller.dart';

class DataEditorTable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DataEditorTableState();
  }
}

class DataEditorTableState extends State<DataEditorTable> {
  late EditorTableController controller;

  @override
  void initState() {
    super.initState();

    try {
      controller = Get.find<EditorTableController>();
    } catch (e) {
      controller = Get.put(EditorTableController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildTable();
  }

  DataTable buildTable() {
    List<DataColumn> columns = <DataColumn>[];
    List<DataRow> rows = <DataRow>[];

    for (var column in controller.tables[0].columnDefs) {
      columns.add(DataColumn(label: Text(column.toString())));
    }

    for (var row in controller.tables[0].rows) {
      List<DataCell> dataCells = <DataCell>[];
      for (var item in row) {
        dataCells.add(DataCell(Text(item.toString())));
      }
      rows.add(DataRow(cells: dataCells));
    }

    return DataTable(
      columns: columns,
      rows: rows,
    );
  }
}
