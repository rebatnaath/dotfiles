#!/usr/bin/env python3
"""XDG desktop portal Notification backend for the quickshell bar.

Implements org.freedesktop.impl.portal.Notification (v1 API) on the session bus
so portal-based apps (Chrome, Zen/Firefox, Electron, ...) that would otherwise
fall back to in-app toasts get a real path, forwarding every call to the
quickshell bar which owns org.freedesktop.Notifications.

Impl interface (xdg-desktop-portal 1.22, version=1):
    AddNotification(app_id, id, notification a{sv})
    RemoveNotification(app_id, id)
    signal ActionInvoked(app_id, id, action, parameter)
"""

import asyncio
import sys

from dbus_next.aio import MessageBus
from dbus_next.message import Message
from dbus_next.service import ServiceInterface, method
from dbus_next import Variant

BAR_OWNER = "org.freedesktop.Notifications"
BAR_PATH = "/org/freedesktop/Notifications"
PORTAL_IFACE = "org.freedesktop.impl.portal.Notification"
PATH = "/org/freedesktop/portal/desktop"


def unwrap(v):
    """dbus-next hands a{sv} values as Variant; peel them for plain access."""
    if isinstance(v, Variant):
        return v.value
    return v


async def bar_call_notify(bus, app_id, notification):
    """Call org.freedesktop.Notifications.Notify on the bar.

    Signature: susssasa{sv}i -> u
    (app_name, replaces_id, app_icon, summary, body, actions, hints, timeout)
    """
    title = str(unwrap(notification.get("title", "")))
    body = str(unwrap(notification.get("body", "")))
    icon = unwrap(notification.get("app-icon", notification.get("icon")))
    actions = list(unwrap(notification.get("actions", []))) if notification.get("actions") else []
    hints = dict(unwrap(notification.get("hints", {}))) if notification.get("hints") else {}
    if icon is not None:
        hints["app_icon"] = str(icon)
    msg = Message(
        destination=BAR_OWNER,
        path=BAR_PATH,
        interface="org.freedesktop.Notifications",
        member="Notify",
        signature="susssasa{sv}i",
        body=[app_id or "", 0, str(icon or ""), title, body, actions, hints, 6000],
    )
    return await bus.call(msg)


async def bar_call_close(bus, bar_id):
    msg = Message(
        destination=BAR_OWNER,
        path=BAR_PATH,
        interface="org.freedesktop.Notifications",
        member="CloseNotification",
        signature="u",
        body=[bar_id],
    )
    return await bus.call(msg)


class NotificationBackend(ServiceInterface):
    _MAX_MAP_SIZE = 500

    def __init__(self, bus: MessageBus):
        super().__init__(PORTAL_IFACE)
        self.bus = bus
        self._map: dict = {}

    @method()
    async def AddNotification(self, app_id: "s", nid: "s", notification: "a{sv}"):
        print(f"[portal-backend] AddNotification app={app_id!r} id={nid!r} "
              f"{notification!r}", file=sys.stderr)
        try:
            reply = await bar_call_notify(self.bus, app_id, notification)
            if reply.message_type.name == "ERROR":
                print(f"[portal-backend] bar Notify ERROR: {reply.error_name}"
                      f" {reply.body}", file=sys.stderr)
                return
            bar_id = reply.body[0]
            self._map[(app_id, nid)] = bar_id
            # Evict oldest entries if the map grows too large. Uses simple FIFO
            # eviction (not LRU) which is acceptable for transient notifications.
            # Frequently-used notifications (e.g. ongoing media) are unlikely to
            # be in the oldest 25% since they're typically re-added periodically.
            if len(self._map) > self._MAX_MAP_SIZE:
                oldest = list(self._map.keys())[:len(self._map) // 4]
                for k in oldest:
                    self._map.pop(k, None)
            print(f"[portal-backend] forwarded -> bar id {bar_id}", file=sys.stderr)
        except Exception as exc:
            print(f"[portal-backend] AddNotification forward failed: {exc}",
                  file=sys.stderr)

    @method()
    async def RemoveNotification(self, app_id: "s", nid: "s"):
        key = (app_id, nid)
        bar_id = self._map.pop(key, None)
        if bar_id is None:
            return
        try:
            await bar_call_close(self.bus, bar_id)
        except Exception as exc:
            print(f"[portal-backend] RemoveNotification failed: {exc}",
                  file=sys.stderr)


async def amain():
    try:
        bus = await MessageBus().connect()
    except Exception as e:
        print(f"[portal-backend] cannot connect to session bus: {e}",
              file=sys.stderr)
        sys.exit(1)
    backend = NotificationBackend(bus)
    bus.export(PATH, backend)
    owner = "org.freedesktop.impl.portal.desktop.quickshell"
    await bus.request_name(owner)
    print(f"[portal-backend] ready on {owner} (impl v1 AddNotification API)",
          file=sys.stderr)
    sys.stderr.flush()
    await asyncio.Event().wait()


if __name__ == "__main__":
    asyncio.run(amain())