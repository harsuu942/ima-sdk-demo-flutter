package com.example.flios

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Presentation
import android.content.Context
import android.content.pm.ActivityInfo
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.*
import android.view.WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
import android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
import android.widget.ImageView
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import io.flutter.embedding.android.FlutterActivity

@SuppressLint("SourceLockedOrientationActivity")
fun ExoPlayer.preparePlayer(playerView: PlayerView, forceLandscape:Boolean = false,
                            mainActivity: com.example.flios.MainActivity,methodChannel: io.flutter.plugin.common.MethodChannel) {
    (playerView.context as Context).apply {
        val playerViewFullscreen = PlayerView(this)
        val layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        playerViewFullscreen.layoutParams = layoutParams
        playerViewFullscreen.visibility = View.GONE
        playerViewFullscreen.setBackgroundColor(Color.TRANSPARENT)
        (playerView.rootView as ViewGroup).apply { addView(playerViewFullscreen, childCount) }
        val fullScreenButton: ImageView = playerView.findViewById(R.id.exo_fullscreen_icon)
        val normalScreenButton: ImageView = playerViewFullscreen.findViewById(R.id.exo_fullscreen_icon)
        fullScreenButton.setImageDrawable(ContextCompat.getDrawable(this, R.drawable.ic_fullscreen_open))
        normalScreenButton.setImageDrawable(ContextCompat.getDrawable(this, R.drawable.ic_fullscreen_close))
        fullScreenButton.setOnClickListener {
            if (forceLandscape)
                mainActivity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
            playerView.visibility = View.VISIBLE
            playerViewFullscreen.visibility = View.VISIBLE
            methodChannel.invokeMethod("fullScreen",0)
            PlayerView.switchTargetView(this@preparePlayer, playerView, playerViewFullscreen)
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
            playerView.player = this@preparePlayer
        }
        normalScreenButton.setOnClickListener {
            if (forceLandscape)
                mainActivity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            normalScreenButton.setImageDrawable(ContextCompat.getDrawable(this, R.drawable.ic_fullscreen_close))
            playerView.visibility = View.VISIBLE
            playerViewFullscreen.visibility = View.GONE
            methodChannel.invokeMethod("normalScreen",0)
            PlayerView.switchTargetView(this@preparePlayer, playerViewFullscreen, playerView)
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
            playerView.player = this@preparePlayer
        }
    }
}


