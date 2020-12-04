-module(test).
-import(node,[init/6]).
-import(network,[listen/1]).
-export([launch/1]).

launch(Time) ->
  ListPid = spawn(network,listen,[[]]),
  ListPid ! {init,3},
  ListPid ! {init,6},
  ListPid ! {launchNodes,7,4,3,true,floor(Time/2),rand},
  ListPid ! {kill,2},
  %ListPid ! {launchNodes,7,4,3,true,floor(Time/2),tail},
  cycle(ListPid,1,Time).
  %test_time(Time).

cycle(ListPid,N,Time) ->
  if
    N =< 3 ->
      io:format("Cycle ~p~n",[N]),
      ListPid ! {timer},
      timer:sleep(Time),
      cycle(ListPid,N+1,Time);
    true ->
      io:format("end of cycles")
  end.
