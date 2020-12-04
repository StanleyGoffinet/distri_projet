-module(network).
-export([network_list/2,getNeighbors/2,getPID/2,test_getN/0,test_getPID/0,test_network/0,listen/1,test_makeC/0,test_unmakeC/0]).
-import(node,[listen/0]).
% first node
add(ID,PID,[])->
  [#{id => ID,pid => PID, linked_node_list => []}];
% other node
add(ID,PID,[ #{id := ID_before,pid := PID_before , linked_node_list := List_before} |T ])->

  [#{id =>ID, pid => PID , linked_node_list => [#{id=>ID_before}]},
  #{id => ID_before,pid => PID_before ,linked_node_list => lists:append([#{id => ID}],List_before)} |T].

% need filter list with le ID_max in first position and id = 1 in last with lists:reverse(lists:sort(LIST))
make_circular2([#{id := 1, linked_node_list := List, pid := PID}|T])->
  lists:reverse([ #{id => 1 , linked_node_list => lists:append([#{id =>(length(T)+1)}],List),  pid => PID} | T]).

make_circular([ #{id := ID_max , linked_node_list := List, pid := PID} |T])->
  make_circular2(lists:reverse([ #{id => ID_max , linked_node_list => lists:append([#{id => 1}],List),pid => PID} | T])).

% undo the cycles on the list
% need filter list with le ID_max in first position and id = 1 in last with lists:reverse(lists:sort(LIST))
unmake_circular2([#{id := 1,pid := PID}|T])->
  lists:reverse([ #{id => 1, linked_node_list =>[#{id => 2}],pid => PID} | T]).

unmake_circular([]) ->
   [];

unmake_circular([#{id := ID_max,pid := PID}|T])->
  unmake_circular2(lists:reverse([ #{id => ID_max, linked_node_list =>[#{id => (ID_max-1)}],pid =>PID} | T])).

%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;

network_list(Node,[]) ->
  network_list(Node,[],0);
network_list(Node,List)->
  network_list(Node, List, length(List)).

network_list(0,List,_) ->
  %make_circular(N,List);
  List;
network_list(Node,List,N) ->
  NodePid = spawn(node,listen,[]),
  network_list(Node-1, add(1+N,NodePid,List),N+1).

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

%kill(_,[])-> true;
%kill(ID, [#{id := ID,pid := PID}|_])-> PID ! {kill};
%kill(ID, [_|T])-> kill(ID, T).

kill_N_nodes(0,_) -> true;
kill_N_nodes(_,[]) -> true;
kill_N_nodes(N,List) ->
  Node = lists:nth(rand:uniform(length(List)),List),
  maps:get(pid,Node) ! {kill},
  kill_N_nodes(N-1,lists:delete(Node,List)).

listen(LinkedList) ->
  receive
    {init,N} ->
      L = network_list(N,unmake_circular(lists:reverse(lists:sort(LinkedList)))),
      H = make_circular(lists:reverse(lists:sort(L))),
      io:format("linkedlist ~p ~n", [H]),
      listen(H);
    {getNeigh,Id, From} ->
      Neighbors = getNeighbors(Id,LinkedList),
      From ! {neigh,Neighbors};
    {launchNodes,C,H,S,PushPull,T,PeerS} ->
      launchNodes(LinkedList,C,H,S,PushPull,T,PeerS);
    {getPID,Id,From} ->
      From ! {pid,getPID(Id,LinkedList)};
    {timer} ->
      time(LinkedList);
    {kill,N} ->
      kill_N_nodes(N,LinkedList)
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
  make_circular(lists:reverse(lists:sort(network_list(2,[])))).

test_unmakeC() ->
  L = make_circular(lists:reverse(lists:sort(network_list(3,[])))),
  H = unmake_circular(lists:reverse(lists:sort(L))),
  L2 = network_list(6,H),
  L3 = make_circular(lists:reverse(lists:sort(L2))),
  io:format("LIST 1 ~p~n", [L]),
  io:format("LIST 2 ~p~n", [H]),
  io:format("LIST 3 ~p~n", [L2]),
  io:format("LIST 4 ~p~n", [L3]).
