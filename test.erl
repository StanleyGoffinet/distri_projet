-module(test).
-import(node,[init/6]).
-import(network,[listen/1]).
-export([launch/6,test/1]).

launch(H,S,C,Peers,PushPull,Time) ->
  ListPid = spawn(network,listen,[[]]),
  ListPid ! {init,3},
  ListPid ! {launchNodes,C,H,S,PushPull,floor(Time/2),Peers},
  cycle(ListPid,1,Time,1),
  ListPid ! {init,6},
  ListPid ! {launchNodes,C,H,S,PushPull,floor(Time/2),Peers},
  cycle(ListPid,1,Time,31),
  ListPid ! {kill,4},
  ListPid ! {recover,2},
  cycle(ListPid,1,Time,61).
  %ListPid ! {launchNodes,7,4,3,true,floor(Time/2),tail},

  %test_time(Time).

cycle(ListPid,N,Time,Counter) ->
  if
    N =< 3 ->
      io:format("Cycle ~p~n",[Counter]),
      ListPid ! {timer,Counter},
      timer:sleep(Time),
      cycle(ListPid,N+1,Time,Counter+1);
    true ->
      io:format("end of cycles ~n")
  end.


test(List) ->
  lists:map(fun([_,B]) -> B end, List).
