"""Minimal notification owner for the private D-Bus integration tests."""
import asyncio
import os
import sys
from pathlib import Path

from dbus_next import RequestNameReply
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, dbus_property, method
from dbus_next.constants import PropertyAccess

NAME = 'org.freedesktop.Notifications'
PATH = '/app/hokum/Daemon'


class Hokum(ServiceInterface):
    def __init__(self, dnd, dismissed):
        super().__init__('app.hokum.Daemon')
        self.dnd = dnd
        self.dismissed = dismissed

    @dbus_property(access=PropertyAccess.READ)
    def DoNotDisturb(self) -> 'b':
        return self.dnd

    @method()
    def SetDoNotDisturb(self, enabled: 'b') -> 'b':
        self.set_dnd(enabled)
        return enabled

    def set_dnd(self, enabled):
        self.dnd = enabled
        self.emit_properties_changed({'DoNotDisturb': enabled})

    @method()
    def Dismiss(self, all_cards: 'b') -> 'u':
        if all_cards and self.dnd:
            self.dismissed.set()
        return int(all_cards)


async def main():
    bus = await MessageBus().connect()
    dismissed = asyncio.Event()
    if sys.argv[1] == 'hokum':
        control = Hokum(True, dismissed)
        bus.export(PATH, control)
    assert await bus.request_name(NAME) == RequestNameReply.PRIMARY_OWNER
    if sys.argv[1] == 'other':
        Path(os.environ['HOME'], 'ready').touch()
        await bus.wait_for_disconnect()
        return
    # Change DND from outside Sitka after the test has read the initial value.
    while not Path(os.environ['HOME'], 'flip-dnd').exists():
        await asyncio.sleep(0.02)
    control.set_dnd(False)
    await dismissed.wait()
    bus.disconnect()
    # Give Sitka time to react to the empty name before a fresh owner claims it.
    await asyncio.sleep(0.15)
    replacement = await MessageBus().connect()
    replacement.export(PATH, Hokum(True, asyncio.Event()))
    assert await replacement.request_name(NAME) == RequestNameReply.PRIMARY_OWNER
    await replacement.wait_for_disconnect()


asyncio.run(main())
