-module(test).
-import(node,[init/6]).
-import(network,[listen/1]).
-export([launch/1]).

launch(Time) ->
  ListPid = spawn(network,listen,[[]]),
  ListPid ! {init,5},
  ListPid ! {launchNodes,4,3,7,true,floor(Time/2),tail},
  cycle(ListPid,0,Time).
  %test_time(Time).

cycle(ListPid,N,Time) ->
  if
    N < 3 ->
      io:format("Cycle ~p~n",[N]),
      ListPid ! {timer},
      timer:sleep(Time),
      cycle(ListPid,N+1,Time);
    true ->
      io:format("end of cycles")
  end.
