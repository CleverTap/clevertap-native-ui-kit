package com.clevertap.android.nativeui.sample

import android.view.View
import android.widget.FrameLayout
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.fragment.app.FragmentActivity
import com.clevertap.android.nativeui.sample.xmlfeed.XmlFeedFragment

@Composable
fun XmlFeedScreen(modifier: Modifier = Modifier) {
    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            val activity = ctx as FragmentActivity
            FrameLayout(ctx).apply {
                id = View.generateViewId()
                // Defer the fragment transaction until this view is attached to the window.
                // commitNow() called inside factory() fails because the FrameLayout hasn't
                // been added to the view hierarchy yet, so FragmentManager can't find its ID.
                addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                    override fun onViewAttachedToWindow(v: View) {
                        val fm = activity.supportFragmentManager
                        if (fm.findFragmentByTag("xml_feed") == null) {
                            fm.beginTransaction()
                                .replace(v.id, XmlFeedFragment(), "xml_feed")
                                .commitNow()
                        }
                        removeOnAttachStateChangeListener(this)
                    }
                    override fun onViewDetachedFromWindow(v: View) {}
                })
            }
        }
    )
}
