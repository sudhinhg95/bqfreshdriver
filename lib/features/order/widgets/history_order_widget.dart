import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryOrderWidget extends StatelessWidget {
  final OrderModel orderModel;
  final bool isRunning;
  final int index;
  const HistoryOrderWidget({super.key, required this.orderModel, required this.isRunning, required this.index});

  @override
  Widget build(BuildContext context) {
    bool parcel = orderModel.orderType == 'parcel';

    String subtitleText;
    if(parcel) {
      subtitleText = orderModel.parcelCategory != null
          ? orderModel.parcelCategory!.name!
          : 'no_parcel_category_data_found'.tr;
    } else {
      String customerName = orderModel.deliveryAddress?.contactPersonName ?? '';
      String blockNumber = orderModel.deliveryAddress?.blockNumber ?? '';
      String area = orderModel.deliveryAddress?.area ?? orderModel.deliveryAddress?.address ?? '';

      List<String> parts = [];
      if(customerName.isNotEmpty) {
        parts.add(customerName);
      }
      if(blockNumber.isNotEmpty) {
        parts.add(blockNumber);
      }
      if(area.isNotEmpty) {
        parts.add(area);
      }

      subtitleText = parts.isNotEmpty
          ? parts.join(', ')
          : (orderModel.storeName ?? 'no_store_data_found'.tr);
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: orderModel.id, isRunningOrder: isRunning, orderIndex: index))),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: Get.isDarkMode ? null : [BoxShadow(color: Colors.grey[200]!, spreadRadius: 1, blurRadius: 5)],
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Row(children: [

          Container(
            height: 70, width: 70, alignment: Alignment.center,
            decoration: parcel ? BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              color: Theme.of(context).primaryColor.withOpacity( 0.2),
            ) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImageWidget(
                image: parcel ? '${orderModel.parcelCategory != null ? orderModel.parcelCategory!.imageFullUrl : ''}' : orderModel.storeLogoFullUrl ?? '',
                height: parcel ? 45 : 70, width: parcel ? 45 : 70, fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Text(
                  '${parcel ? 'delivery_id'.tr : 'order_id'.tr}:',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(child: Text(
                  '#${orderModel.id}',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                )),
                parcel ? Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    color: Theme.of(context).primaryColor.withOpacity( 0.1),
                  ),
                  child: Text('parcel'.tr, style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                  )),
                ) : const SizedBox(),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                subtitleText,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Row(children: [
                const Icon(Icons.access_time, size: 15),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(
                  DateConverterHelper.dateTimeStringToDateTime(orderModel.createdAt!),
                  style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                ),
              ]),

            ]),
          ),

        ]),
      ),
    );
  }
}
