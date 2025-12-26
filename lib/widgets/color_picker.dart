import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColorPicker extends StatelessWidget {
  const AppColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.palette = defaultPalette,
    this.showCustom = true,
  });

  final Color selected;
  final ValueChanged<Color> onChanged;
  final List<Color> palette;
  final bool showCustom;

  static const Color defaultColor = Color(0xFF1E3A8A);

  static const List<Color> defaultPalette = <Color>[
    Color(0xFF1E3A8A),
    Color(0xFF0EA5E9),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFF0F172A),
    Color(0xFF334155),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        ...palette.map((c) {
          final isSelected = c.value == selected.value;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.black.withOpacity(0.35) : Colors.white, width: isSelected ? 2 : 1),
                boxShadow: [BoxShadow(color: c.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          );
        }),
        if (showCustom)
          ActionChip(
            avatar: const Icon(Icons.palette_outlined, size: 18),
            label: const Text('Custom'),
            onPressed: () async {
              final picked = await _pickCustomColor(context, selected);
              if (picked != null) onChanged(picked);
            },
          ),
      ],
    );
  }

  Future<Color?> _pickCustomColor(BuildContext context, Color initial) async {
    double hue = HSVColor.fromColor(initial).hue;
    double saturation = HSVColor.fromColor(initial).saturation;
    double value = HSVColor.fromColor(initial).value;

    final hexController = TextEditingController(text: _hexFromColor(initial));
    final hexFocusNode = FocusNode();
    bool isSettingHex = false;

    void syncHexText(Color color) {
      final next = _hexFromColor(color);
      if (hexController.text.toUpperCase() == next) return;
      isSettingHex = true;
      hexController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      isSettingHex = false;
    }

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final theme = Theme.of(ctx);

          void setHsv({double? h, double? s, double? v, bool syncHex = true}) {
            setLocal(() {
              if (h != null) hue = h;
              if (s != null) saturation = s;
              if (v != null) value = v;
            });
            if (syncHex) {
              final color = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
              syncHexText(color);
            }
          }

          void updateFromOffset(Offset position, Size size) {
            if (size.width <= 0 || size.height <= 0) return;
            final dx = position.dx.clamp(0.0, size.width);
            final dy = position.dy.clamp(0.0, size.height);
            setHsv(h: (dx / size.width * 360).clamp(0.0, 360.0), s: (dy / size.height).clamp(0.0, 1.0));
          }

          final preview = HSVColor.fromAHSV(1, hue, saturation, value).toColor();

          return AlertDialog(
            title: const Text('Pick a color', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 170,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        final markerX = (hue / 360).clamp(0.0, 1.0) * size.width;
                        final markerY = saturation.clamp(0.0, 1.0) * size.height;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              CustomPaint(size: size, painter: _ColorPickerPainter()),
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) => updateFromOffset(details.localPosition, size),
                                  onPanDown: (details) => updateFromOffset(details.localPosition, size),
                                  onPanUpdate: (details) => updateFromOffset(details.localPosition, size),
                                ),
                              ),
                              Positioned(
                                left: (markerX - 7).clamp(0.0, size.width - 14),
                                top: (markerY - 7).clamp(0.0, size.height - 14),
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 36,
                        decoration: BoxDecoration(
                          color: preview,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: hexController,
                          focusNode: hexFocusNode,
                          autocorrect: false,
                          enableSuggestions: false,
                          maxLength: 9,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]'))],
                          decoration: const InputDecoration(
                            labelText: 'Hex',
                            hintText: '#RRGGBB',
                            counterText: '',
                            isDense: true,
                          ),
                          onChanged: (value) {
                            if (isSettingHex) return;
                            final parsed = _parseHex(value);
                            if (parsed == null) return;
                            final hsv = HSVColor.fromColor(parsed);
                            setHsv(h: hsv.hue, s: hsv.saturation, v: hsv.value, syncHex: false);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Hue: ${hue.toStringAsFixed(0)}'),
                  Slider(
                    label: 'Hue',
                    min: 0,
                    max: 360,
                    divisions: 36,
                    value: hue,
                    onChanged: (v) => setHsv(h: v),
                  ),
                  Text('Saturation: ${(saturation * 100).toStringAsFixed(0)}%'),
                  Slider(
                    label: 'Saturation',
                    min: 0,
                    max: 1,
                    divisions: 10,
                    value: saturation,
                    onChanged: (v) => setHsv(s: v),
                  ),
                  Text('Brightness: ${(value * 100).toStringAsFixed(0)}%'),
                  Slider(
                    label: 'Brightness',
                    min: 0,
                    max: 1,
                    divisions: 10,
                    value: value.clamp(0, 1),
                    onChanged: (v) => setHsv(v: v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, preview), child: const Text('Use color')),
            ],
          );
        },
      ),
    );
    hexController.dispose();
    hexFocusNode.dispose();
    return result;
  }

  String _hexFromColor(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }

  Color? _parseHex(String input) {
    var raw = input.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('#')) {
      raw = raw.substring(1);
    }
    if (raw.length != 6 && raw.length != 8) return null;
    final value = int.tryParse(raw, radix: 16);
    if (value == null) return null;
    if (raw.length == 6) {
      return Color(0xFF000000 | value);
    }
    return Color(value);
  }
}

class _ColorPickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueGradient = LinearGradient(colors: [for (double h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h, 1, 1).toColor()]);

    final saturationGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.transparent],
    );

    final paint = Paint();
    paint.shader = hueGradient.createShader(rect);
    canvas.drawRect(rect, paint);

    paint.shader = saturationGradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
