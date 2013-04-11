# ircnotify

`ircnotify` is a basic daemon for communicating between an IRC bot and the outside world via a socket.

The following assume that `SOCKET=/path/to/ircnotify/socket`

For example, to say "Hello world!" via the bot:

    echo 'Hello world!' | socat - unix-connect:$SOCKET

The message from the bot will be tagged by the name of the client, which by default is the username of the owner of the process connecting to the socket.

If you want to set your client's name, you can communicate this to ircnotify via a json-encoded command:

    { echo '{"set_name":"mrtest"}'
      echo 'Hello from client "mrtest"'
    } | socat - unix-connect:$SOCKET

It might get annoying typing out json, so if you are going to be using the shell, you can use the included utility `opts2json`:

    opts2json --set-name mrtest --send 'Hello from client "mrtest"' | socat - unix-connect:$SOCKET

Using a coproc, you could also communicate the other way from the irc channel to the outside world.  The following will register for the trigger `!test` (assuming the default ircnotify trigger prefix `!`), and report on stdout each trigger, and reply via the bot to each trigger:

    ( coproc fds { socat - unix-connect:$SOCKET;}
      opts2json --set-triggers test >&${fds[1]}
      while read -ru ${fds[0]} line; do
        eval $(echo "$line" | json2bash msg)
        echo "$msg_from_name said: $msg_body"
        echo "$msg_from_name tested" >&${fds[1]}
      done
    )

The above example also uses the included utility `json2bash` which does its best to convert a json object into bash variables.

Of course, there is no reason you have to use bash.  As long as you can connect to a socket and produce and parse json, you are good to go.
