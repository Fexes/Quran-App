package com.coreinfinite.quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

private const val UPDATE_TIMELINES = "com.coreinfinite.quran.UPDATE_WIDGET_TIMELINES"
internal const val WIDGET_PATH = "com.coreinfinite.quran.WIDGET_PATH"

class PrayerHomeWidget : QuranHomeWidget("prayer", R.string.widget_prayer)
class PrayerScheduleHomeWidget : QuranHomeWidget("prayer", R.string.widget_prayer_medium, mediumPrayer = true)
class ReadingHomeWidget : QuranHomeWidget("reading", R.string.widget_reading)
class AyahHomeWidget : QuranHomeWidget("ayah", R.string.widget_ayah)
class AzkarHomeWidget : QuranHomeWidget("azkar", R.string.widget_azkar)
class FastingHomeWidget : QuranHomeWidget("fasting", R.string.widget_fasting)
class HifzHomeWidget : QuranHomeWidget("hifz", R.string.widget_hifz)
class GoalHomeWidget : QuranHomeWidget("goal", R.string.widget_goal)

abstract class QuranHomeWidget(
    private val kind: String,
    private val label: Int,
    private val mediumPrayer: Boolean = false,
) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val snapshot = QuranWidgets.snapshot(context)
        val now = System.currentTimeMillis()
        for (id in ids) render(context, manager, id, snapshot, now)
        QuranWidgets.schedule(context, snapshot, now)
    }

    override fun onDisabled(context: Context) {
        QuranWidgets.schedule(context, QuranWidgets.snapshot(context), System.currentTimeMillis())
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in setOf(UPDATE_TIMELINES, Intent.ACTION_BOOT_COMPLETED)) {
            QuranWidgets.refresh(context)
        }
    }

    internal fun render(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        snapshot: JSONObject?,
        now: Long,
    ) {
        val entry = QuranWidgets.entries(snapshot, kind).lastOrNull {
            it.optLong("start") <= now
        }
        val dark = snapshot?.optBoolean("dark") == true
        val paper = kind == "reading" || kind == "goal" || kind == "ayah"
        val ink = if (paper && !dark) 0xff213831.toInt() else android.graphics.Color.WHITE
        val secondary = if (paper && !dark) 0xff43564a.toInt() else 0xfff2e9dc.toInt()
        val labelColor = if (kind == "ayah") secondary else android.graphics.Color.WHITE
        val rtl = when (snapshot?.optString("language")) {
            null -> context.resources.configuration.layoutDirection == View.LAYOUT_DIRECTION_RTL
            "ar", "ur" -> true
            else -> false
        }
        val views = RemoteViews(context.packageName, R.layout.quran_home_widget)
        val (art, icon) = artwork(entry?.optString("prayerPhase"), dark, rtl)
        views.setImageViewResource(R.id.widget_background, art)
        views.setImageViewResource(R.id.widget_icon, icon)
        views.setInt(R.id.widget_icon, "setColorFilter", labelColor)
        views.setInt(R.id.widget_root, "setLayoutDirection",
            if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        views.setViewVisibility(R.id.widget_art_space, if (kind == "fasting") View.VISIBLE else View.GONE)
        views.text(R.id.widget_label, entry?.optString("label") ?: context.getString(label), labelColor)

        val heading = entry?.optString("heading") ?: context.getString(R.string.widget_setup)
        val arabic = entry?.optString("arabic").orEmpty()
        val detail = entry?.optString("detail").orEmpty()
        val prayerTime = kind == "prayer" && detail.isNotEmpty()
        val metric = (kind == "goal" || kind == "hifz") && heading.firstOrNull()?.isDigit() == true
        val height = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        val compact = height in 1..136
        val titleSize = when {
            metric -> if (compact) 24f else 30f
            prayerTime -> if (compact) 15f else 18f
            arabic.isNotEmpty() -> if (compact) 18f else 22f
            else -> if (compact) 18f else 21f
        }
        views.setTextViewTextSize(R.id.widget_heading, TypedValue.COMPLEX_UNIT_SP, titleSize)
        val detailSize = when {
            !prayerTime -> 13f
            compact -> 22f
            mediumPrayer -> 32f
            else -> 28f
        }
        views.setTextViewTextSize(R.id.widget_detail, TypedValue.COMPLEX_UNIT_SP, detailSize)
        views.setInt(R.id.widget_heading, "setGravity", if (arabic.isEmpty()) Gravity.START else Gravity.RIGHT)
        views.setInt(R.id.widget_detail, "setMaxLines", if (arabic.isEmpty()) 2 else 1)
        views.text(R.id.widget_heading, arabic.ifEmpty { heading }, ink)
        views.text(R.id.widget_detail, detail, if (prayerTime) ink else secondary)

        val footer = if (arabic.isEmpty()) entry?.optString("footer").orEmpty() else heading
        if (mediumPrayer) {
            views.setTextViewTextSize(R.id.widget_footer, TypedValue.COMPLEX_UNIT_SP, 13f)
            views.setTextViewCompoundDrawablesRelative(R.id.widget_footer, R.drawable.widget_location_pin, 0, 0, 0)
        }
        views.text(R.id.widget_footer, footer, secondary)
        val progress = entry?.optDouble("progress", -1.0) ?: -1.0
        views.setViewVisibility(R.id.widget_progress, if (progress >= 0) View.VISIBLE else View.GONE)
        if (progress >= 0) {
            views.setProgressBar(R.id.widget_progress, 100, (progress * 100).toInt(), false)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(R.id.widget_progress, "setProgressTintList",
                    android.content.res.ColorStateList.valueOf(if (dark) 0xffafdcc7.toInt() else 0xff357363.toInt()))
                views.setColorStateList(R.id.widget_progress, "setProgressBackgroundTintList",
                    android.content.res.ColorStateList.valueOf(if (dark) 0x44ffffff else 0x44213831))
            }
        }
        val path = entry?.optString("path") ?: "/"
        views.setOnClickPendingIntent(R.id.widget_root, open(context, id, 0, path))
        views.setOnClickPendingIntent(R.id.widget_footer,
            open(context, id, 2, entry?.optString("footerPath", path) ?: path))
        manager.updateAppWidget(id, views)
    }

    private fun artwork(phase: String?, dark: Boolean, rtl: Boolean): Pair<Int, Int> = when (kind) {
        "prayer" -> when (phase) {
            "fajr" -> R.drawable.widget_prayer_fajr
            "sunrise" -> R.drawable.widget_prayer_sunrise
            "asr" -> R.drawable.widget_prayer_asr
            "sunset" -> R.drawable.widget_prayer_sunset
            "maghrib" -> R.drawable.widget_prayer_maghrib
            "isha" -> R.drawable.widget_prayer_isha
            else -> R.drawable.widget_prayer_dhuhr
        } to R.drawable.widget_icon_prayer
        "reading" -> (if (dark) R.drawable.widget_reading_dark else R.drawable.widget_reading) to R.drawable.widget_icon_reading
        "goal" -> (if (dark) R.drawable.widget_goal_dark else R.drawable.widget_goal) to R.drawable.widget_icon_goal
        "ayah" -> (if (dark) R.drawable.widget_ayah_dark else R.drawable.widget_ayah) to R.drawable.widget_icon_ayah
        "fasting" -> (if (rtl) R.drawable.widget_fasting_rtl else R.drawable.widget_fasting) to R.drawable.widget_icon_fasting
        "azkar" -> R.drawable.widget_azkar to R.drawable.widget_icon_azkar
        "hifz" -> R.drawable.widget_hifz to R.drawable.widget_icon_hifz
        else -> error("Unknown widget type $kind")
    }

    private fun open(context: Context, id: Int, part: Int, path: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(WIDGET_PATH, path)
        return PendingIntent.getActivity(
            context, 3 * id + part, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun RemoteViews.text(id: Int, text: String, color: Int) {
        setTextViewText(id, text)
        setTextColor(id, color)
        setViewVisibility(id, if (text.isBlank()) View.GONE else View.VISIBLE)
    }
}

internal object QuranWidgets {
    private val providers = mapOf(
        "prayer" to PrayerHomeWidget(),
        "prayer:medium" to PrayerScheduleHomeWidget(),
        "reading" to ReadingHomeWidget(),
        "ayah" to AyahHomeWidget(),
        "azkar" to AzkarHomeWidget(),
        "fasting" to FastingHomeWidget(),
        "hifz" to HifzHomeWidget(),
        "goal" to GoalHomeWidget(),
    )

    private fun preferences(context: Context) =
        context.getSharedPreferences("home_screen_widgets", Context.MODE_PRIVATE)

    fun publish(context: Context, json: String?) {
        val preferences = preferences(context)
        if (preferences.getString("snapshot", null) == json) return
        preferences.edit().putString("snapshot", json).apply()
        refresh(context)
    }

    fun snapshot(context: Context): JSONObject? =
        preferences(context).getString("snapshot", null)?.let {
            runCatching { JSONObject(it) }.getOrNull()
        }

    fun entries(snapshot: JSONObject?, kind: String): List<JSONObject> {
        val list = snapshot?.optJSONObject("widgets")?.optJSONArray(kind) ?: return emptyList()
        return (0 until list.length()).mapNotNull { list.optJSONObject(it) }
    }

    fun canPin(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported

    fun pin(context: Context, kind: String?, size: String?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !canPin(context)) return false
        val key = if (kind == "prayer" && size == "medium") "prayer:medium" else kind
        val provider = providers[key] ?: return false
        return AppWidgetManager.getInstance(context)
            .requestPinAppWidget(ComponentName(context, provider.javaClass), null, null)
    }

    fun refresh(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val snapshot = snapshot(context)
        val now = System.currentTimeMillis()
        for (provider in providers.values) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider.javaClass))
            for (id in ids) provider.render(context, manager, id, snapshot, now)
        }
        schedule(context, snapshot, now)
    }

    fun schedule(context: Context, snapshot: JSONObject?, now: Long) {
        val manager = AppWidgetManager.getInstance(context)
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(context, PrayerHomeWidget::class.java).setAction(UPDATE_TIMELINES)
        val pending = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val next = providers.entries.asSequence()
            .filter { manager.getAppWidgetIds(ComponentName(context, it.value.javaClass)).isNotEmpty() }
            .mapNotNull { provider ->
                entries(snapshot, provider.key.substringBefore(':')).firstOrNull {
                    it.optLong("start") > now
                }?.optLong("start")
            }
            .minOrNull()
        if (next == null) {
            alarms.cancel(pending)
        } else {
            val mayScheduleExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarms.canScheduleExactAlarms()
            if (mayScheduleExact) {
                try {
                    alarms.setExactAndAllowWhileIdle(AlarmManager.RTC, next, pending)
                    return
                } catch (_: SecurityException) {
                    // Exact alarm access can change between the check and scheduling.
                }
            }
            alarms.setAndAllowWhileIdle(AlarmManager.RTC, next, pending)
        }
    }
}
