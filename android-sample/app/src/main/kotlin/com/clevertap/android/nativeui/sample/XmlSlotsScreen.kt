package com.clevertap.android.nativeui.sample

import android.view.View
import android.widget.FrameLayout
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.fragment.app.FragmentActivity
import com.clevertap.android.nativeui.sample.xmlslots.XmlSlotsFragment

/**
 * Compose host for the XML-based slot demo. Mirrors [XmlFeedScreen] — the same
 * AndroidView+Fragment commitment dance, just hosting a different fragment.
 */
@Composable
fun XmlSlotsScreen(modifier: Modifier = Modifier) {
    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            val activity = ctx as FragmentActivity
            FrameLayout(ctx).apply {
                id = View.generateViewId()
                addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                    override fun onViewAttachedToWindow(v: View) {
                        val fm = activity.supportFragmentManager
                        val existing = fm.findFragmentByTag("xml_slots")
                        if (existing != null) {
                            fm.beginTransaction().remove(existing).commitNow()
                        }
                        fm.beginTransaction()
                            .replace(v.id, XmlSlotsFragment(), "xml_slots")
                            .commitNow()
                        removeOnAttachStateChangeListener(this)
                    }
                    override fun onViewDetachedFromWindow(v: View) {}
                })
            }
        }
    )
}
