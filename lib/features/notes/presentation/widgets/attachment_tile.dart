import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/note_attachment.dart';

class AttachmentTile extends StatelessWidget {
  final NoteAttachmentModel attachment;
  final IconData icon;
  final VoidCallback onDelete;

  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.icon,
    required this.onDelete,
  });

  Future<void> _open() async {
    await OpenFilex.open(attachment.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        attachment.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: _open,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
        tooltip: 'Remove',
      ),
    );
  }
}
