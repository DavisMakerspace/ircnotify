# ircnotify

`ircnotify` is a basic daemon for communicating between an IRC bot and the outside world via a socket.

For example, to say "Hello world!" via the bot:

    echo 'Hello world!' | socat stdin unix-connect:/path/to/ircnotify/socket
