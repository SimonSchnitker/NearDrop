import 'ControlMessage.dart';

class ProgressMessage extends ControlMessage
{
    static const String label = "progress";

    final double progress;

    ProgressMessage(this.progress) : super(label);

    Map<String, dynamic> toMap()
    {
        return {
            "type": label,
            "progress": progress,
        };
    }
}