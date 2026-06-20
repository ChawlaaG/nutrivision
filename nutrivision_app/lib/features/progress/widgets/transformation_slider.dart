import 'package:flutter/material.dart';

class TransformationSlider extends StatefulWidget {
  final ImageProvider beforeImage;
  final ImageProvider afterImage;

  const TransformationSlider({
    super.key,
    required this.beforeImage,
    required this.afterImage,
  });

  @override
  State<TransformationSlider> createState() => _TransformationSliderState();
}

class _TransformationSliderState extends State<TransformationSlider> {
  double _splitPosition = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _splitPosition = (details.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // Before Image (Base)
              SizedBox(
                width: width,
                height: height,
                child: Image(
                  image: widget.beforeImage,
                  fit: BoxFit.cover,
                ),
              ),
              
              // After Image (Clipped)
              ClipRect(
                clipper: _SplitClipper(_splitPosition),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Image(
                    image: widget.afterImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Slider Handle
              Positioned(
                left: (width * _splitPosition) - 20, // Center the handle
                top: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    color: Colors.white,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Labels
              Positioned(
                bottom: 16,
                left: 16,
                child: Opacity(
                  opacity: _splitPosition > 0.1 ? 1.0 : 0.0,
                  child: _buildLabel('Before'),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Opacity(
                  opacity: _splitPosition < 0.9 ? 1.0 : 0.0,
                  child: _buildLabel('After'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double splitPosition;

  _SplitClipper(this.splitPosition);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * splitPosition, size.height);
  }

  @override
  bool shouldReclip(_SplitClipper oldClipper) {
    return oldClipper.splitPosition != splitPosition;
  }
}
