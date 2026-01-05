import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

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
