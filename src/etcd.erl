-module(etcd).

-export([start/0, stop/0]).
-compile(export_all).

-include("include/etcd_types.hrl").

-define(DEFAULT_TIMEOUT, 50000).

%% @doc Start application with all depencies
-spec start() -> ok | {error, term()}.
start() ->
  case application:ensure_all_started(etcd) of
    {ok, _} ->
      ok;
    {error, Reason} ->
      {error, Reason}
  end.

%% @doc Stop application
-spec stop() -> ok | {error, term()}.
stop() ->
  application:stop(etcd).

-spec read(key()) -> {ok, response()} | {error, response()}.
read(Key) ->
  read(Key, false, 'infinity').

-spec read(key(), recursive()) -> {ok, response()} | {error, response()}.
read(Key, Recursive) ->
  read(Key, Recursive, 'infinity').

-spec read(key(), recursive(), pos_timeout()) -> {ok, response()} | {error, response()}.
read(Key, Recursive, Timeout) ->
  Url  = url() ++ convert_to_string(Key) ++ "?" ++ encode_params([{recursive, Recursive}]),
  Response = request(Url, get, [], Timeout),
  handle_request_result(Response).

-spec create_dir(dir()) -> {ok, response()} | {error, response()}.
create_dir(Dir) ->
  create_dir(Dir, false, 'infinity').

-spec create_dir(dir(), pre_exist()) -> {ok, response()} | {error, response()}.
create_dir(Dir, PreExist) ->
  create_dir(Dir, PreExist, 'infinity').

-spec create_dir(dir(), pre_exist(), pos_timeout()) -> {ok, response()} | {error, response()}.
create_dir(Dir, PreExist, TTL) ->
  TTL_ = ttl(TTL),
  Url  = url() ++ convert_to_string(Dir),
  PayLoad = TTL_ ++ [{prevExist, PreExist}, {dir, true}],
  Response = request(Url, put, PayLoad),
  handle_request_result(Response).

-spec insert(key(), value()) -> {ok, response()} | {error, response()}.
insert(Key, Value) ->
  insert(Key, Value, 'infinity').

-spec insert(key(), value(), pos_timeout()) -> {ok, response()} | {error, response()}.
insert(Key, Value, TTL) ->
  TTL_ = ttl(TTL),
  Url  = url() ++ convert_to_string(Key),
  PayLoad = TTL_ ++ [{prevExist, false}, {value, Value}],
  Response = request(Url, put, PayLoad),
  handle_request_result(Response).

-spec insert_ex(key(), pre_value(), value()) -> {ok, response()} | {error, response()}.
insert_ex(Key, PreValue, Value) ->
  insert_ex(Key, PreValue, Value, 'infinity').

-spec insert_ex(key(), pre_value(), value(), pos_timeout()) -> {ok, response()} | {error, response()}.
insert_ex(Key, PreValue, Value, TTL) ->
  TTL_ = ttl(TTL),
  Url  = url() ++ convert_to_string(Key),
  PayLoad = TTL_ ++ [{prevValue, PreValue}, {value, Value}],
  Response = request(Url, put, PayLoad),
  handle_request_result(Response).

-spec update(key(), value()) -> {ok, response()} | {error, response()}.
update(Key, Value) ->
  update(Key, Value, 'infinity').

-spec update(key(), value(), pos_timeout()) -> {ok, response()} | {error, response()}.
update(Key, Value, TTL) ->
  TTL_ = ttl(TTL),
  Url  = url() ++ convert_to_string(Key),
  PayLoad = TTL_ ++ [{prevExist, true}, {value, Value}],
  Response = request(Url, put, PayLoad),
  handle_request_result(Response).

-spec update_ex(key(), pre_value(), value()) -> {ok, response()} | {error, response()}.
update_ex(Key, PreValue, Value) ->
  update_ex(Key, PreValue, Value, 'infinity').

-spec update_ex(key(), pre_value(), value(), pos_timeout()) -> {ok, response()} | {error, response()}.
update_ex(Key, PreValue, Value, TTL) ->
  TTL_ = ttl(TTL),
  Url  = url() ++ convert_to_string(Key),
  PayLoad = TTL_ ++ [{prevValue, PreValue}, {value, Value}],
  Response = request(Url, put, PayLoad),
  handle_request_result(Response).

-spec watch(key()) -> {ok, response()} | {error, response()}.
watch(Key) ->
  watch(Key, false, 'infinity').

-spec watch(key(), recursive()) -> {ok, response()} | {error, response()}.
watch(Key, Recursive) when is_boolean(Recursive) ->
  watch(Key, Recursive, 'infinity').

-spec watch(key(), recursive(), pos_timeout()) -> {ok, response()} | {error, response()}.
watch(Key, Recursive, Timeout) ->
  WaitParams = encode_params([{wait, true}, {recursive, Recursive}]),
  Url  = url() ++ convert_to_string(Key) ++ "?" ++ WaitParams,
  Response = request(Url, get, [], Timeout),
  handle_request_result(Response).

-spec watch_ex(key(), wait_index()) -> {ok, response()} | {error, response}.
watch_ex(Key, WaitIndex) ->
  watch_ex(Key, WaitIndex, true, 'infinity').

-spec watch_ex(key(), wait_index(), recursive()) -> {ok, response()} | {error, response}.
watch_ex(Key, WaitIndex, Recursive) when is_boolean(Recursive) ->
  watch_ex(Key, WaitIndex, Recursive, 'infinity').

-spec watch_ex(key(), wait_index(), recursive(), pos_timeout()) -> {ok, response()} | {error, response}.
watch_ex(Key, WaitIndex, Recursive, Timeout) ->
  WaitParams = encode_params([{recursive, Recursive}, {wait, true}, {waitIndex, WaitIndex}]),
  Url  = url() ++ convert_to_string(Key) ++ "?" ++ WaitParams,
  Response = request(Url, get, [], Timeout),
  handle_request_result(Response).

%% internal functions
%% Just for version 2.**
url() ->
  Url = config(etcd_utl, "http://127.0.0.1:4001"),
  Url ++ "/v2" ++ "/keys".

config(Key, Default) ->
  config(etcd, Key, Default).

config(App, Key, Default) ->
  application:get_env(App, Key, Default).

ttl('infinity') -> [];
ttl(TTL) when is_integer(TTL) -> [{ttl, TTL}].
  
request(Url, Method, Body) ->
  request(Url, Method, Body, ?DEFAULT_TIMEOUT).

request(Url, Method, Body, Timeout) ->
  Body_ = encode_params(Body),
io:format("----------> Url:~p Method:~p Body:~p~n", [Url, Method, Body_]),
  Headers = [{"Content-Type", "application/x-www-form-urlencoded"}],
  lhttpc:request(Url, Method, Headers, Body_, Timeout).

%% @private
handle_request_result(Result) ->
  case Result of
    {ok, {{StatusCode, _ReasonPhrase}, _Hdrs, ResponseBody}} ->
      io:format("--------> code:~p~n", [Result]),
      case StatusCode div 100 of
        2 ->
         Decoded = jiffy:decode(ResponseBody),
         {ok, Decoded};
        _ ->
          Error = try
            jiffy:decode(ResponseBody)
          catch _:_ ->
            ResponseBody
          end,
          {error, Error}
      end;
    Error -> Error
  end.

%% @private
encode_params(Pairs) ->
  List = [ http_uri:encode(convert_to_string(Key)) ++ "=" ++ http_uri:encode(convert_to_string(Value)) || {Key, Value} <- Pairs ],
  %%binary:list_to_bin(string:join(List, "&")).
  string:join(List, "&").

%% @private
convert_to_string(Value) when is_integer(Value) ->
  integer_to_list(Value);
convert_to_string(Value) when is_binary(Value) ->
  binary_to_list(Value);
convert_to_string(Value) when is_atom(Value) ->
  atom_to_list(Value);
convert_to_string(Value) when is_list(Value) ->
  Value.


%%%
%%%

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-endif.
