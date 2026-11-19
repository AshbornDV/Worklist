package com.example.worklist.ui.navigation

/**
 * One entry per GoRoute declared in the Flutter app (`lib/app.dart`). Exactly
 * 24 — see [entries].
 *
 * [route] mirrors the Flutter path list verbatim, except the four detail/edit
 * routes use Navigation Compose's `{id}` argument placeholder where Flutter's
 * `go_router` writes `:id`. Paths and their order are otherwise identical.
 */
sealed interface WorklistDestination {
    val route: String
    val title: String

    object Login : WorklistDestination {
        override val route = "/login"
        override val title = "Login"
    }

    object Home : WorklistDestination {
        override val route = "/"
        override val title = "Home"
    }

    object Collections : WorklistDestination {
        override val route = "/collections"
        override val title = "Collections"
    }

    object Analytics : WorklistDestination {
        override val route = "/analytics"
        override val title = "Analytics"
    }

    object Calendar : WorklistDestination {
        override val route = "/calendar"
        override val title = "Calendar"
    }

    object Documents : WorklistDestination {
        override val route = "/documents"
        override val title = "Documents"
    }

    object Sites : WorklistDestination {
        override val route = "/sites"
        override val title = "Sites"
    }

    object SiteNew : WorklistDestination {
        override val route = "/sites/new"
        override val title = "New site"
    }

    data class SiteDetail(val id: Int) : WorklistDestination {
        override val route = "/sites/{id}"
        override val title get() = "Site $id"
    }

    data class SiteEdit(val id: Int) : WorklistDestination {
        override val route = "/sites/{id}/edit"
        override val title get() = "Edit site $id"
    }

    object Workers : WorklistDestination {
        override val route = "/workers"
        override val title = "Workers"
    }

    object WorkerNew : WorklistDestination {
        override val route = "/workers/new"
        override val title = "New worker"
    }

    data class WorkerDetail(val id: Int) : WorklistDestination {
        override val route = "/workers/{id}"
        override val title get() = "Worker $id"
    }

    data class WorkerEdit(val id: Int) : WorklistDestination {
        override val route = "/workers/{id}/edit"
        override val title get() = "Edit worker $id"
    }

    object Attendance : WorklistDestination {
        override val route = "/attendance"
        override val title = "Attendance"
    }

    object Payroll : WorklistDestination {
        override val route = "/payroll"
        override val title = "Payroll"
    }

    object Products : WorklistDestination {
        override val route = "/products"
        override val title = "Products"
    }

    object ProductNew : WorklistDestination {
        override val route = "/products/new"
        override val title = "New product"
    }

    object Stock : WorklistDestination {
        override val route = "/stock"
        override val title = "Stock"
    }

    object Services : WorklistDestination {
        override val route = "/services"
        override val title = "Services"
    }

    object ServiceNew : WorklistDestination {
        override val route = "/services/new"
        override val title = "New service"
    }

    object Notifications : WorklistDestination {
        override val route = "/notifications"
        override val title = "Notifications"
    }

    object NotificationSettings : WorklistDestination {
        override val route = "/notifications/settings"
        override val title = "Notification settings"
    }

    object NotificationDiagnostics : WorklistDestination {
        override val route = "/notifications/diagnostics"
        override val title = "Notification diagnostics"
    }

    object Insights : WorklistDestination {
        override val route = "/notifications/insights"
        override val title = "Notification insights"
    }

    object Account : WorklistDestination {
        override val route = "/account"
        override val title = "Account"
    }

    companion object {
        /** One representative instance per destination, in Flutter router order. */
        val entries: List<WorklistDestination> = listOf(
            Login,
            Home,
            Collections,
            Analytics,
            Calendar,
            Documents,
            Sites,
            SiteNew,
            SiteDetail(0),
            SiteEdit(0),
            Workers,
            WorkerNew,
            WorkerDetail(0),
            WorkerEdit(0),
            Attendance,
            Payroll,
            Products,
            ProductNew,
            Stock,
            Services,
            ServiceNew,
            Notifications,
            NotificationSettings,
            NotificationDiagnostics,
            Insights,
            Account,
        )
    }
}
