package com.esenyas.esenyas

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt
import kotlin.math.roundToLong

class MainActivity : FlutterActivity() {
    companion object {
        private const val VIDEO_CHANNEL = "esenyas/video_landmarks"
        private const val HAND_MODEL = "hand_landmarker.task"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VIDEO_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "analyzeVideo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("INVALID_PATH", "Video path is empty.", null)
                return@setMethodCallHandler
            }

            Thread {
                try {
                    val payload = analyzeVideo(path)
                    runOnUiThread { result.success(payload) }
                } catch (t: Throwable) {
                    runOnUiThread {
                        result.error(
                            "VIDEO_ANALYSIS_FAILED",
                            t.message ?: t.javaClass.simpleName,
                            null
                        )
                    }
                }
            }.start()
        }
    }

    private fun analyzeVideo(path: String): Map<String, Any> {
        val retriever = MediaMetadataRetriever()

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(HAND_MODEL)
            .setDelegate(Delegate.CPU)
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setNumHands(2)
            .setRunningMode(RunningMode.VIDEO)
            .setMinHandDetectionConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .build()

        val landmarker = HandLandmarker.createFromOptions(this, options)

        try {
            when {
                path.startsWith("content://") ->
                    retriever.setDataSource(this, Uri.parse(path))
                path.startsWith("file://") ->
                    retriever.setDataSource(
                        Uri.parse(path).path ?: path.removePrefix("file://")
                    )
                else -> retriever.setDataSource(path)
            }

            val durationMs = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull()
                ?: throw IllegalArgumentException("Could not read video duration.")

            val metadataFps = retriever
                .extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE
                )
                ?.toDoubleOrNull()
                ?.takeIf { it > 0.0 && it.isFinite() }

            // The Colab/OpenCV pipeline processes source frames in order.
            // Follow the video's own FPS where available instead of imposing
            // the live phone-camera callback cadence.
            val sourceFps = metadataFps ?: 30.0
            val estimatedFrameCount =
                ((durationMs / 1000.0) * sourceFps)
                    .roundToInt()
                    .coerceAtLeast(1)

            val firstFrame = retriever.getFrameAtTime(
                0,
                MediaMetadataRetriever.OPTION_CLOSEST
            ) ?: throw IllegalArgumentException(
                "Could not decode the first video frame."
            )
            val width = firstFrame.width
            val height = firstFrame.height
            firstFrame.recycle()

            val frames =
                ArrayList<List<List<List<Double>>>>(estimatedFrameCount + 1)
            var activeFrames = 0

            for (frameIndex in 0..estimatedFrameCount) {
                val timestampMs =
                    (frameIndex * 1000.0 / sourceFps).roundToLong()
                if (timestampMs > durationMs) break

                val bitmap = retriever.getFrameAtTime(
                    timestampMs * 1000,
                    MediaMetadataRetriever.OPTION_CLOSEST
                )

                if (bitmap == null) {
                    frames.add(emptyList())
                    continue
                }

                val argbFrame =
                    if (bitmap.config == Bitmap.Config.ARGB_8888) bitmap
                    else bitmap.copy(Bitmap.Config.ARGB_8888, false)

                val mpImage = BitmapImageBuilder(argbFrame).build()
                try {
                    val detection =
                        landmarker.detectForVideo(mpImage, timestampMs)

                    val hands = detection.landmarks().map { hand ->
                        hand.map { landmark ->
                            listOf(
                                landmark.x().toDouble(),
                                landmark.y().toDouble(),
                                landmark.z().toDouble()
                            )
                        }
                    }

                    if (hands.isNotEmpty()) activeFrames++
                    frames.add(hands)
                } finally {
                    mpImage.close()
                    if (argbFrame !== bitmap) argbFrame.recycle()
                    bitmap.recycle()
                }
            }

            return mapOf(
                "frames" to frames,
                "durationMs" to durationMs,
                "sourceFps" to sourceFps,
                "sampledFrames" to frames.size,
                "activeFrames" to activeFrames,
                "width" to width,
                "height" to height
            )
        } finally {
            retriever.release()
            landmarker.close()
        }
    }
}
