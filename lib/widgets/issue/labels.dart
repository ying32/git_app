import 'package:flutter/material.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/utils/utils.dart';

class IssueLabels extends StatelessWidget {
  const IssueLabels({super.key, required this.labels});

  final List<IssueLabel> labels;

  Color _getColor(Color color) {
    if ((0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) /
            255.0 <
        0.66) return Colors.white;
    return Colors.black;
  }

  Widget _buildItem(IssueLabel item) {
    final color = hexColorTo(item.color);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: Text(
        item.name,
        style: TextStyle(color: _getColor(color), fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 5,
        runSpacing: 5,
        children: labels.map((e) => _buildItem(e)).toList(),
      );
}
