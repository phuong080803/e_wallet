import 'package:e_wallet/models/user_model.dart';
import 'package:e_wallet/pages/widgets/user_image.dart';
import '../../../../styles/constrant.dart';
import 'package:flutter/material.dart';

class BuildUserTransaction extends StatelessWidget {
  final UserModel user;
  const BuildUserTransaction({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            UserImage(imagePath: k_imagePath, raduis: 50),
          ],
        ),
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
                "${user.dateTime}",
                style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
        Text(
          "${user.amount}",
          style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 14),
        )
      ],
    );
  }
}
