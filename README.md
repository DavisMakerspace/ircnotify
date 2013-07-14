# ircnotify

`ircnotify` is a basic daemon for communicating between an IRC bot and the outside world via a socket.

## Examples

The following assume that `SOCKET=/path/to/ircnotify/socket`

For example, to say "Hello world!" via the bot and `socat`:

    echo 'Hello world!' | socat - unix-connect:$SOCKET

The message from the bot will be tagged by the name of the client, which by default is the username of the owner of the process connecting to the socket.

If you want to set your client's name, you can communicate this to ircnotify via a json-encoded command:

    { echo '{"set_name":"mrtest"}'
      echo 'Hello from client "mrtest"'
    } | socat - unix-connect:$SOCKET

It might get annoying typing out json, so if you are going to be using the shell, you can use the included utility `opts2json`:

    opts2json --set-name mrtest --send 'Hello from client "mrtest"' | socat - unix-connect:$SOCKET

You can also communicate the other way from the irc channel to the outside world.  The following will register for the command `test` (triggered by saying `!test` in the channel with the bot, assuming the default ircnotify trigger `!`), and report on stdout each invocation:

    socat unix-connect:$SOCKET system:'opts2json --set-commands test >&4; cat',fdout=4

Trying the above, you'll see that ircnotify also uses json to report activity to clients.  If you only care about being invoked, you can do:

    socat unix-connect:$SOCKET system:"$(cat <<'.'
      opts2json --set-commands test >&4
      while read; do echo 'invoked!'; done
    .
    )",fdout=4

Or, using the provided utility `json2bash`, you can get some information about the invocation:

    socat unix-connect:$SOCKET system:"$(cat <<'.'
      opts2json --set-commands test >&4
      while read -r line; do
        eval $(json2bash msg <<<"$line")
        echo "$msg_from_name invoked: ${msg_argv[@]}"
      done
    .
    )",fdout=4

You can take the above a step further and also communicate back to the bot when getting invoked:

    socat unix-connect:$SOCKET system:"$(cat <<'.'
      opts2json --set-commands test >&4
      while read -ru 3 line; do
        eval $(json2bash msg <<<"$line")
        echo "$msg_from_name invoked: ${msg_argv[@]}"
        echo "invoked by $msg_from_name" >&4
      done
    .
    )",fdin=3,fdout=4

Alternatively, you can use a coproc:

    ( coproc fds { socat - unix-connect:$SOCKET;}
      in=${fds[0]}; out=${fds[1]}
      opts2json --set-commands test >&$out
      while read -ru $in line; do
        eval $(json2bash msg <<<"$line")
        echo "$msg_from_name invoked: ${msg_argv[@]}"
        echo "invoked by $msg_from_name" >&$out
      done
    )

Of course, there is no reason you must use bash.  As long as your environment of choice can connect to a socket and produce and parse json, you are good to go.

## JSON Commands

The following commands are recognized in the JSON string:

* `set_name`: (string) Set the name of this client.
* `set_commands`: (array of strings) Register command names for this client to respond to.
* `set_targets`: (array of strings) Set targets for this and future messages.
* `targets`: (array of strings) Send the current message to the given targets.
* `set_shorten_urls`: (boolean) Shorten any urls in this or future messages.
* `shorten_urls`: (boolean) Shorten any urls in the current message.
* `send`: (string, array of strings) Send the given string(s) as separate messages to the set targets.
