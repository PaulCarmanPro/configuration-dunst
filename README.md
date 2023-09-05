# configuration-dunst

Dunst is a notification daemon which resonds to nofication signals sent by nofity-send over dbus. It incldes dunstctl which provides extra features like "close-all" (bound to Super-Esc in openboxrc) and "history-pop" (bound to Shift-Super-Esc in openboxrc).

Global dunstrc is /etc/xdg/dunstrc. Dunst can be killed at any time, but its existance as /usr/share/dbus-1/services/org.knopwob.dunst.service causes notify-send to automatically launch dunst.

I use a speedy-repeat keyboard with a highly-adjustable volume control and discovered that many quick repeated notificatoin causes the notification system to deadlock. The following code is used in "volume" to avoid total deadlock:

````bash
NotifyVolume "$1" &
declare z="$!"
timeout 0.5s bash -c wait $z
[[ 124 = "$?" ]] \
   && while pkill dunst; do sleep 0.01s; done # avoid lockup
````

This kind of thing is needed only for fast repeated notifications. Leaving the keyboard repeat rate alone eliminates the problem. 
