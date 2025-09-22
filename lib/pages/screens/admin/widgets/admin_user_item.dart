import 'package:e_wallet/models/database_models.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:flutter/material.dart';

class AdminUserItem extends StatelessWidget {
  final User user;

  const AdminUserItem({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: k_blue,
              backgroundImage: user.image != null 
                  ? NetworkImage(user.image!) 
                  : null,
              child: user.image == null 
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${user.id.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (user.age != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tuổi: ${user.age}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (user.dateOfBirth != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ngày sinh: ${user.dateOfBirth}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (user.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Địa chỉ: ${user.address}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tạo: ${_formatDate(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
