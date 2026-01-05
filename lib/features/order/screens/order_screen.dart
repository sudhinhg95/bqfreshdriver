import 'dart:async';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/history_order_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/order/screens/multi_order_route_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ScrollController scrollController = ScrollController();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    Get.find<OrderController>().getCompletedOrders(1, willUpdate: false);
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent
          && Get.find<OrderController>().completedOrderList != null
          && !Get.find<OrderController>().paginate) {
        int pageSize = (Get.find<OrderController>().pageSize! / 10).ceil();
        if (Get.find<OrderController>().offset < pageSize) {
          Get.find<OrderController>().setOffset(Get.find<OrderController>().offset+1);
          debugPrint('end of the page');
          Get.find<OrderController>().showBottomLoader();
          Get.find<OrderController>().getCompletedOrders(Get.find<OrderController>().offset);
        }
      }
    });
    // Auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      Get.find<OrderController>().getCurrentOrders();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: CustomAppBarWidget(title: 'my_orders'.tr, isBackButtonExist: false),

      // Add navigation button to MultiOrderRouteScreen
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MultiOrderRouteScreen()),
          );
        },
        label: Text('Show Multi-Order Route'),
        icon: Icon(Icons.route),
      ),

      body: GetBuilder<OrderController>(builder: (orderController) {
        return orderController.currentOrderList != null ? orderController.currentOrderList!.isNotEmpty ? RefreshIndicator(
          onRefresh: () async {
            await orderController.getCurrentOrders();
          },
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(child: SizedBox(
              width: 1170,
              child: Column(children: [
                ListView.builder(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  itemCount: orderController.currentOrderList!.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return HistoryOrderWidget(orderModel: orderController.currentOrderList![index], isRunning: true, index: index);
                  },
                ),
              ]),
            )),
          ),
        ) : Center(child: Text('no_order_found'.tr)) : const Center(child: CircularProgressIndicator());
      }),
    );
  }
}
