import 'package:flutter/material.dart';
import 'package:map/screen/osm/map_search_page.dart';

class LocationInput extends StatelessWidget {
  final String label;
  final String? initialValue;
  final Function(String) onSelected;

  const LocationInput({
    super.key,
    required this.label,
    required this.onSelected,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      readOnly: true,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapSearchPage()),
        );
        if (result != null) {
          onSelected(result);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
