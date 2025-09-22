import '../../../../pages/screens/contacts/widgets/custom_alert_sucess_payment.dart';
import 'package:e_wallet/pages/screens/contacts/widgets/payment_amount_textField.dart';
import 'package:e_wallet/pages/screens/contacts/widgets/payment_note_textField.dart';
import 'package:e_wallet/pages/widgets/custom_button_navigation_bar.dart';
import 'package:e_wallet/pages/widgets/user_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:e_wallet/models/user_model.dart';
import '../../../../styles/constrant.dart';

class RequestPaymentScreen extends StatelessWidget {
  final UserModel user;

  RequestPaymentScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  final TextEditingController _amountTextEditingController = TextEditingController();
  final TextEditingController _noteTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: k_black),
            onPressed: () => Get.back(),
          ),
          title: Text(
            "Request Money",
            style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
                child: Row(
                  children: [
                    UserImage(imagePath: k_imagePath, raduis: 50),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${user.name}",
                            style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${user.email}",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: PaymentAmountTextField(
                  amount: 24.6,
                  color: k_blue,
                  textEditingController: _amountTextEditingController,
                  title: "Payment Amount",
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: PaymentNoteTextField(
                  textEditingController: _noteTextEditingController,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomButtonNavigationBar(
          color: k_blue,
          label: "Requset Payment",
          imagePath: "assets/images/request_icon.png",
          onPress: () {
            showDialog(
              context: context,
              builder: (ctx) => CustomAlertSuccessPayment(
                message: "The amount has been requested successfully!",
              ),
            );
          },
        ),
      ),
    );
  }
}
