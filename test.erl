-module(test).
-import(node,[init/6]).
-import(network,[listen/1]).
-export([launch/1]).

launch(Time) ->
  ListPid = spawn(network,listen,[[]]),
  ListPid ! {init,3},
  ListPid ! {launchNodes,7,4,3,true,floor(Time/2),rand},
  cycle(ListPid,1,Time),
  ListPid ! {init,6},
  ListPid ! {launchNodes,7,4,3,true,floor(Time/2),rand},
  cycle(ListPid,1,Time),
  ListPid ! {kill,4},
  ListPid ! {recover,2},
  cycle(ListPid,1,Time).
  %ListPid ! {launchNodes,7,4,3,true,floor(Time/2),tail},

  %test_time(Time).

cycle(ListPid,N,Time) ->
  if
    N =< 3 ->
      io:format("Cycle ~p~n",[N]),
      ListPid ! {timer},
      timer:sleep(Time),
      cycle(ListPid,N+1,Time);
    true ->
      io:format("end of cycles ~n")
  end.
