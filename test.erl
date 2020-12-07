-module(test).
-import(node,[init/6]).
-import(network,[listen/1]).
-export([launch/7,test/1]).

launch(H,S,C,Peers,PushPull,Time,N) ->
  ListPid = spawn(network,listen,[[]]),
  ListPid ! {init,floor(N*0.4)},
  ListPid ! {launchNodes,C,H,S,PushPull,floor(Time/2),Peers},
  cycle(ListPid,1,Time,1),
  ListPid ! {init,floor(N*0.2)},
  ListPid ! {launchNodes,C,H,S,PushPull,floor(Time/2),Peers},
  cycle(ListPid,1,Time,31),
  ListPid ! {init,floor(N*0.2)},
  ListPid ! {launchNodes,C,H,S,PushPull,floor(Time/2),Peers},
  cycle(ListPid,1,Time,61),
  ListPid ! {init,floor(N*0.2)},
  ListPid ! {launchNodes,C,H,S,PushPull,floor(Time/2),Peers},
  cycle(ListPid,1,Time,91),
  Killed = floor(N*0.6),
  ListPid ! {kill,Killed},
  cycle(ListPid,1,Time,121),
  ListPid ! {recover,floor(Killed*0.6)},
  cycle(ListPid,1,Time,151).
  %ListPid ! {launchNodes,7,4,3,true,floor(Time/2),tail},

  %test_time(Time).

cycle(ListPid,N,Time,Counter) ->
  if
    N =< 30 ->
      io:format("Cycle ~p~n",[Counter]),
      ListPid ! {timer,Counter},
      timer:sleep(Time),
      cycle(ListPid,N+1,Time,Counter+1);
    true ->
      true
  end.


test(List) ->
  lists:map(fun([_,B]) -> B end, List).
