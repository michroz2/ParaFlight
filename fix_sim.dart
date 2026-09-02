import 'dart:io';

void main() {
  final file = File('lib/features/dashboard/presentation/dashboard_screen.dart');
  final content = file.readAsStringSync();
  
  final startStr = 'if (dataSource == DataSource.simulator)';
  final endStr = '// Панель: Линейная панель управления (Linear Control Bar)';
  
  final startIndex = content.indexOf(startStr);
  final endIndex = content.indexOf(endStr);
  
  if (startIndex == -1 || endIndex == -1) {
    print('Failed to find markers');
    return;
  }
  
  final newBlock = '''if (dataSource == DataSource.simulator)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showOverlays ? 80 : -100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xDD333333),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => playbackNotifier.togglePlay(),
                      child: Icon(
                        playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            ),
                            child: Slider(
                              value: playbackState.progress,
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => playbackNotifier.seek(value),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(playbackState.currentDuration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                              Text(_formatDuration(playbackState.totalDuration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        double nextSpeed = playbackState.speedFactor == 1.0 ? 2.0 :
                                           playbackState.speedFactor == 2.0 ? 5.0 :
                                           playbackState.speedFactor == 5.0 ? 10.0 : 1.0;
                        playbackNotifier.setSpeed(nextSpeed);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('\x', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          ''';
          
  final newContent = content.substring(0, startIndex) + newBlock + content.substring(endIndex);
  file.writeAsStringSync(newContent);
  print('Successfully updated Simulator UI block');
}
