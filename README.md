etcd.erl
========

Erlang bindings for [etcd](https://github.com/coreos/etcd) key value store.

## Usage
### start
```erlang
etcd:start()
```
### read
```erlang
{ok, Response} = etcd:read("Hello world").

{ok, Response} = etcd:read("Hello world", 5000).
```
``"Hello world"`` is the value. ``5000`` is the timeout.
### insert
```erlang
{ok, Response} = etcd:insert("/message", "Value", infinity).
```
### insert_ex
```erlang
etcd:insert("/message", "one"),
{ok, Response} = etcd:insert_ex("/message", "one", "two", infinity).
```
Directories are also supported:
### create directory
```erlang
{ok, Response1} = etcd:create_dir("/foo", infinity).
{ok, Response2} = etcd:insert("/foo/message2", "Hello night", infinity).

```
### delete
```erlang
etcd:insert("/message", "Hello world", infinity),
etcd:delete("/message", infinity).
```
### watch
```erlang
Result = etcd:watch("/foo", true, infinity),
```
``true`` means recursive
Watch for commands at index ``42``:
```erlang
Result = etcd:watch_ex("/foo", 42, infinity),
```
