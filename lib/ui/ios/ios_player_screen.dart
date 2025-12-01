import 'package:flutter/cupertino.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../core/audio_controller.dart';
import '../../core/model/playback_view_model.dart';

class IosPlayerScreen extends StatefulWidget {
  const IosPlayerScreen({super.key, required this.controller});

  final AudioController controller;

  @override
  State<IosPlayerScreen> createState() => _IosPlayerScreenState();
}

class _IosPlayerScreenState extends State<IosPlayerScreen> {
  final _pathController = TextEditingController();
  final _seekController = TextEditingController(text: '0');

  @override
  void dispose() {
    _pathController.dispose();
    _seekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context)!.iosPlayerTitle),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<PlaybackViewModel>(
          valueListenable: widget.controller.state,
          builder: (context, viewModel, _) {
            final l10n = AppLocalizations.of(context)!;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                CupertinoTextField(
                  controller: _pathController,
                  placeholder: l10n.iosAudioPathPlaceholder,
                  enabled: !viewModel.isBusy,
                ),
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: viewModel.isBusy ? null : _load,
                  child: Text(l10n.iosLoadButton),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      onPressed: (!viewModel.hasFile || viewModel.isBusy)
                          ? null
                          : widget.controller.play,
                      child: const Icon(CupertinoIcons.play_arrow_solid),
                    ),
                    CupertinoButton(
                      onPressed: (!viewModel.isPlaying || viewModel.isBusy)
                          ? null
                          : widget.controller.pause,
                      child: const Icon(CupertinoIcons.pause_solid),
                    ),
                    CupertinoButton(
                      onPressed: (!viewModel.hasFile || viewModel.isBusy)
                          ? null
                          : widget.controller.stop,
                      child: const Icon(CupertinoIcons.stop),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: _seekController,
                  placeholder: l10n.iosSeekPlaceholder,
                  enabled: viewModel.hasFile && !viewModel.isBusy,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: (!viewModel.hasFile || viewModel.isBusy)
                      ? null
                      : _seek,
                  child: Text(l10n.iosSeekButton),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.iosStatusLabel(viewModel.statusMessage),
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _load() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.iosEnterFilePath);
      return;
    }
    await widget.controller.load(path);
  }

  Future<void> _seek() async {
    final value = int.tryParse(_seekController.text.trim());
    if (value == null) {
      _showMessage(AppLocalizations.of(context)!.iosEnterValidPosition);
      return;
    }
    await widget.controller.seek(value);
  }

  void _showMessage(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(AppLocalizations.of(context)!.commonOk),
          ),
        ],
      ),
    );
  }
}
