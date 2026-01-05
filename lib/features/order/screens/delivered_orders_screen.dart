import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/history_order_widget.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';

class DeliveredOrdersScreen extends StatefulWidget {
  const DeliveredOrdersScreen({super.key});

  @override
  State<DeliveredOrdersScreen> createState() => _DeliveredOrdersScreenState();
}

class _DeliveredOrdersScreenState extends State<DeliveredOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Load first page of delivered/completed orders
    Get.find<OrderController>().getCompletedOrders(1);

    // Paginate on scroll
    _scrollController.addListener(() {
      final orderController = Get.find<OrderController>();
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
          && orderController.completedOrderList != null
          && !orderController.paginate) {
        int pageSize = (orderController.pageSize! / 10).ceil();
        if (orderController.offset < pageSize) {
          orderController.setOffset(orderController.offset + 1);
          orderController.showBottomLoader();
          orderController.getCompletedOrders(orderController.offset);
        }
      }
    });

    // Optional periodic refresh to keep list up-to-date
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      Get.find<OrderController>().getCompletedOrders(1);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a hardcoded title to ensure immediate display regardless of localization cache
      appBar: CustomAppBarWidget(title: 'Delivered Orders', isBackButtonExist: false),
      body: GetBuilder<OrderController>(builder: (orderController) {
        final completed = orderController.completedOrderList;
        if (completed == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (completed.isEmpty) {
          return Center(child: Text('no_order_found'.tr));
        }
        return RefreshIndicator(
          onRefresh: () async {
            await orderController.getCompletedOrders(1);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: SizedBox(
                width: 1170,
                child: Column(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      itemCount: completed.length,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return HistoryOrderWidget(
                          orderModel: completed[index],
                          isRunning: false,
                          index: index,
                        );
                      },
                    ),
                    if (orderController.paginate)
                      const Padding(
                        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
