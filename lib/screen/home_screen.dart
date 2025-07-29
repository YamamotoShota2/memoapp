import 'package:flutter/material.dart';
import 'package:memoapp/base/base_screen.dart';
import 'package:memoapp/screen/create_new_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();

}

class _HomeScreen extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      customAppBar: HomeAppBar(),
      customAppBody: Center(
        child: createNewButton()
      )
    );
  }

  Widget createNewButton() {
    return Builder(
      builder: (context) {
        return FloatingActionButton(
          child: Icon(Icons.edit_note),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return CreateNewScreen();
          }))
        );
      }
    );
  }
} 

class HomeAppBar extends StatelessWidget 
  implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize {
    return Size(double.infinity, 60);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      title: Text(
        'メモアプリ',
      ),
    );
  }
}