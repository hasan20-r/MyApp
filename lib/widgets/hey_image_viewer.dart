import 'package:flutter/material.dart';

class HeyImageViewer {
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (ctx, anim, secAnim) {
          return FadeTransition(
            opacity: anim,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                title: title != null
                    ? Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              body: SafeArea(
                child: Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: heroTag != null
                        ? Hero(
                            tag: heroTag,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                                      SizedBox(height: 8),
                                      Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                                    SizedBox(height: 8),
                                    Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
