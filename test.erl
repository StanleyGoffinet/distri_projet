-module(test).
-import(node,[init/6]).
-import(network,[listen/1]).
-export([launch/0]).

launch() ->
  ListPid = spawn(network,listen,[[]]),
  ListPid ! {init,5},
  ListPid ! {launchNodes,1,0,0,true,tail}.
  %NodePid1 = spawn(node,init,[1,1,0,0,true,tail]),
  %NodePid2 = spawn(node,init,[2,1,0,0,true,tail]),
  %NodePid1 ! {update, [[0,NodePid2]],active},
  %NodePid1 ! {update, [[0,NodePid2]],passive},
  %NodePid2 ! {update, [[0,NodePid1]],active},
  %NodePid2 ! {update, [[0,NodePid1]],passive},
  %NodePid1 ! {timer}.
