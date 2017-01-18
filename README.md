# Reboot server in Haskell

This reboot server can be used to reboot your system through TCP communication. It also sends UDP messages when something is wrong, like the protocol not being followed.

Feel free to let me know if something isn't working as it should at bouwe.ceune$

### Get it running

Note that this must be run with sudo if you want sudo access to reboot.

```sh
$ ./rebootserver
```
This will give an error args, arguments are needed.
Append the arguments so that the first argument is the UDP send port, the second argument the UDP send IP and the third port the actual port used for TCP communication.

```sh
$ ./rebootserver 1012 127.0.0.1 5678
```
### Protocol 

In order to get into the messageserver when connecting to it, a protocol is needed. The init and pass can be customized. An example is 'connect' 'name' 'password'.
-   init
-   'name'
-   pass

### Features

- UDP messages are send when the protocol is not followed by the host, this prevents unwanted intrusions

### Example usage

```sh
$ ./rebootserver 1012 127.0.0.1 5678
```

```sh
$ telnet 127.0.0.1 5678
>> connect
>> user1
>> passw
```
