# configuration-dunst

Dunst is a notification daemon which resonds to nofication signals sent by nofity-send over dbus. Dunst also comes with dunstctl which provides extra features like...

dunstctl close-all # removes all notificatons and is bound to Super-Esc in openboxrc.
dunstctl history-pop # redisplay previous notification

The global dunstrc is in /etc/xdg/dunstrc.

Dunst can be killed at any time, but its existance as /usr/share/dbus-1/services/org.knopwob.dunst.service causes notify-send to automatically launch dunst.

I have grown to like dunst, but volume with a jacked keyboard can quickly send a slew of replacement notifications fast which causes dunst to lock solid. The problem seems to fix itself, but it is very annoying.
