import 'package:flutter/material.dart';

class BottomNavItemWidget extends StatelessWidget {
  final IconData iconData;
  final Function? onTap;
  final bool isSelected;
  final int? pageIndex;
  const BottomNavItemWidget({super.key, required this.iconData, this.onTap, this.isSelected = false, this.pageIndex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: onTap as void Function()?,
        icon: Icon(iconData, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 25),
      ),
    );
  }
}
