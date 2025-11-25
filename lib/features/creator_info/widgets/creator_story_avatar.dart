import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class CreatorStoryAvator extends StatelessWidget {
  const CreatorStoryAvator({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> authorInfo = {
      "name": "Tenzin",
      "imageUrl":
          "https://avatars2.githubusercontent.com/u/5024388?s=460&u=d260850b9267cf89188499695f8bcf71e743f8a7&v=4",
      "time": "1h",
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 22,
          backgroundImage:
              (authorInfo['imageUrl'] as String).cachedNetworkImageProvider,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                authorInfo['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Text(
                authorInfo['time'],
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
