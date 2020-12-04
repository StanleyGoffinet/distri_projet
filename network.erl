-module(network).
-export([network_list/2,getNeighbors/2,getPID/2,test_getN/0,test_getPID/0,test_network/0,listen/1,test_makeC/0,test_unmakeC/0]).
-import(node,[listen/0]).
% first node
add(ID,PID,[])->
  [#{id => ID,pid => PID, linked_node_list => [#{id => 1}]}];
% other node
add(ID,PID,[ #{id := ID_before,pid := PID_before , linked_node_list := List_before} |T ])->

  [#{id =>ID, pid => PID , linked_node_list => [#{id=>ID_before}]},
  #{id => ID_before,pid => PID_before ,linked_node_list => lists:append([#{id => ID}],List_before)} |T].

% need filter list with le ID_max in first position and id = 1 in last with lists:reverse(lists:sort(LIST))
make_circular2([#{id := 1, linked_node_list := List}|T])->
  lists:reverse([ #{id => 1 , linked_node_list => lists:append([#{id =>(length(T)+1)}],List)} | T]).

make_circular([ #{id := ID_max , linked_node_list := List} |T])->
  make_circular2(lists:reverse([ #{id => ID_max , linked_node_list => lists:append([#{id => 1}],List)} | T])).

% undo the cycles on the list
% need filter list with le ID_max in first position and id = 1 in last with lists:reverse(lists:sort(LIST))
unmake_circular2([#{id := 1}|T])->
  lists:reverse([ #{id => 1 , linked_node_list =>[#{id => 2}]} | T]).

unmake_circular([#{id := ID_max}|T])->
  unmake_circular2(lists:reverse([ #{id => ID_max , linked_node_list =>[#{id => (ID_max-1)}]} | T])).



%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;
network_list(Node,[]) ->
  network_list(Node,[],0);
network_list(Node,List)->
  network_list(Node, List, length(List)).

network_list(0,List,N) ->
  %make_circular(N,List);
  List;
network_list(Node,List,N) ->
  NodePid = spawn(node,listen,[]),
  network_list(Node-1, add(Node+N,NodePid,List),N).

getPID(_,[])-> "Error, give empty list";
getPID(ID, [#{id := ID,pid := PID}|_])-> PID;
getPID(ID, [_|T])-> getPID(ID, T).

getNeighbors(_,[])-> "Error, the node is not in the list";
getNeighbors(ID, [#{id := ID,linked_node_list:= Neighbors}|_])-> Neighbors;
getNeighbors(ID, [_|T])-> getNeighbors(ID, T).

launchNodes([A],C,H,S,PushPull,T,PeerS) ->
  maps:get(pid,A) ! {init,maps:get(id,A),C,H,S,PushPull,T,PeerS,self()};

launchNodes([A|B],C,H,S,PushPull,T,PeerS) ->
  maps:get(pid,A) ! {init,maps:get(id,A),C,H,S,PushPull,T,PeerS,self()},
  launchNodes(B,C,H,S,PushPull,T,PeerS).

time([A]) ->
  maps:get(pid,A) ! {timer};

time([A|B]) ->
  maps:get(pid,A) ! {timer},
  time(B).

kill(_,[])-> true;
kill(ID, [#{id := ID,pid := PID}|_])-> PID ! {kill};
kill(ID, [_|T])-> kill(ID, T).

listen(LinkedList) ->
  receive
    {init,N} ->
      L = network_list(N,LinkedList),
      io:format("LinkedList ~n ~p ~n",[L]),
      listen(L);
    {getNeigh,Id, From} ->
      Neighbors = getNeighbors(Id,LinkedList),
      From ! {neigh,Neighbors};
    {launchNodes,C,H,S,PushPull,T,PeerS} ->
      launchNodes(LinkedList,C,H,S,PushPull,T,PeerS);
    {getPID,Id,From} ->
      From ! {pid,getPID(Id,LinkedList)};
    {timer} ->
      time(LinkedList);
    {kill,Id} ->
      kill(Id,LinkedList)
  end,
  listen(LinkedList).


test_getN() ->
  List = network_list(5,[]),
  [getNeighbors(1,List),getNeighbors(4,List)]
  .

test_getPID() ->
  List = network_list(5,[]),
  [getPID(1,List),getPID(4,List)]
  .

test_network() ->
  network_list(5,[])
  .
test_makeC() ->
  make_circular(lists:reverse(lists:sort([
  #{id => 5,linked_node_list => [#{id => 4}],pid => 0},
  #{id => 1,linked_node_list => [#{id => 2}],pid => 0},
  #{id => 4,linked_node_list => [#{id => 3},#{id => 5}],pid => 0},
  #{id => 3,linked_node_list => [#{id => 2},#{id => 4}],pid => 0},
  #{id => 2,linked_node_list => [#{id => 1},#{id => 3}],pid => 0}
   ]))).

 test_unmakeC() ->
   unmake_circular(lists:reverse(lists:sort([
   #{id => 5,linked_node_list => [#{id => 4},#{id => 1}],pid => 0},
   #{id => 1,linked_node_list => [#{id => 2},#{id => 5}],pid => 0},
   #{id => 4,linked_node_list => [#{id => 3},#{id => 5}],pid => 0},
   #{id => 3,linked_node_list => [#{id => 2},#{id => 4}],pid => 0},
   #{id => 2,linked_node_list => [#{id => 1},#{id => 3}],pid => 0}
    ]))).
