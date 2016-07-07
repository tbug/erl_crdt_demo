-module (demo_SUITE).
-include_lib("common_test/include/ct.hrl").
-compile(export_all).

all() ->
  [
    orswot_3_actors, 
    lwwreg_map_3_actors
  ].

orswot_v(V) ->
  riak_dt_orswot:value(V).

map_v(V) ->
  riak_dt_map:value(V).

orswot_3_actors(_Config) ->
  S1 = riak_dt_orswot:new(),
  ct:log("server adds an element"),
  {ok, S2} = riak_dt_orswot:update({add, <<"common">>}, server, S1),
  ct:log("alice gets servers state and adds 2 elements, a1, and a2"),
  {ok, A1} = riak_dt_orswot:update({add, <<"a1">>}, alice, S2),
  {ok, A2} = riak_dt_orswot:update({add, <<"a2">>}, alice, A1),
  ct:log("bob gets servers state and adds 2 elements, a1, and a2"),
  {ok, B1} = riak_dt_orswot:update({add, <<"b1">>}, bob, S2),
  {ok, B2} = riak_dt_orswot:update({add, <<"b2">>}, bob, B1),

  % state print
  ct:log("Alice: ~p\nBob: ~p\nServer: ~p", [
    orswot_v(A2), orswot_v(B2), orswot_v(S2)]),

  ct:log("alice sends bob her state and bob merge it"),
  B3 = riak_dt_orswot:merge(B2, A2),
  ct:log("bob removes his first item, and alice' first item."),
  {ok, B4} = riak_dt_orswot:update({remove_all, [<<"a1">>, <<"b1">>]}, bob, B3),

  % state print
  ct:log("Alice: ~p\nBob: ~p\nServer: ~p", [
    orswot_v(A2), orswot_v(B4), orswot_v(S2)]),

  ct:log("Server gets both bob's and alice' latest state, \nServer1 and Server2 shows difference between of bob or alice is merged into server first."),

  S3 = riak_dt_orswot:merge(S2, B4),
  S4 = riak_dt_orswot:merge(S3, A2),

  S3Alt = riak_dt_orswot:merge(S2, A2),
  S4Alt = riak_dt_orswot:merge(S3Alt, B4),
  % just to show that merge order doesn't matter:
  S4Alt = S4,

  % state print
  ct:log("Alice: ~p\nBob: ~p\nServer: ~p\nServer (alice first): ~p", [
    orswot_v(A2), orswot_v(B4), orswot_v(S4), orswot_v(S4Alt)]),

  ct:log("Alice notices she is behind and syncs with the server"),
  A3 = riak_dt_orswot:merge(A2, S4),

  % state print
  ct:log("Alice: ~p\nBob: ~p\nServer: ~p", [
    orswot_v(A3), orswot_v(B4), orswot_v(S4)]),
  ok.



lwwreg_map_3_actors(_Config) ->
  FieldFoo = {<<"foo">>, riak_dt_lwwreg},
  FieldBar = {<<"bar">>, riak_dt_lwwreg},
  S1 = riak_dt_map:new(),
  Ops = [
    {update, FieldFoo, {assign, <<"s1foo">>}},
    {update, FieldBar, {assign, <<"s1bar">>}}
  ],
  {ok, S2} = riak_dt_map:update({update, Ops}, server, S1),
  ct:print("Server: ~p", [map_v(S2)]),
  ok.