import 'package:flutter/material.dart';

class CreateImage extends StatelessWidget {
  const CreateImage({super.key});

  @override
  Widget build(BuildContext context) {
    final imagePath = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Create Image'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Text("Close"),
        ),
        actions: [IconButton(onPressed: () {}, icon: const Text("Save"))],
      ),
      body: Center(
        child:
            imagePath != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    imagePath,
                    width: 260,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                )
                : const Text('No image selected'),
      ),
    );
  }
}
