-module(network).
-export([network_list/2,getNeighbors/2,getPID/2,test_getN/0,test_getPID/0,test_network/0,listen/1]).
-import(node,[listen/0]).
% first node
add(ID,PID,_,[])->
  [#{id => ID,pid => PID, linked_node_list => [#{id => 1}]}];
% other node
add(ID,PID, ID_max,[ #{id := ID_before,pid := PID_before , linked_node_list := List_before} |T ])->
  if
    % last node with id = 1 (cause tail recursive implementation)
    ID == 1 ->
      [  #{id =>ID,pid => PID , linked_node_list => [#{id=>ID_before}, #{id=>ID_max}]},
      #{id => ID_before,pid => PID_before, linked_node_list => lists:append([#{id=>ID}],List_before)} |T];
    % other node
    ID > 1 ->
      [#{id =>ID, pid => PID , linked_node_list => [#{id=>ID_before}]},
      #{id => ID_before,pid => PID_before ,linked_node_list => lists:append([#{id => ID}],List_before)} |T]
  end.


%make_circular(#{id := 1 , linked_node_list := List} |T])->
%  [ #{id => 1 , linked_node_list => lists:append([#{id =>(lists:length(T)+1)}],List)} | T]
%  .

%make_circular(ID_max, [ #{id := ID_max , linked_node_list := List} |T])->

%  make_circular(lists:reverse([ #{id => ID_max , linked_node_list => lists:append([#{id => 1}],List)} | T])).


%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;
network_list(Node,List)->
NodePid = spawn(node,listen,[]),
network_list(Node-1, add(Node,NodePid, Node+length(List), List)).


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

listen(LinkedList) ->
  receive
    {init,N} ->
      L = network_list(N,LinkedList),
      listen(L);
    {getNeigh,Id, From} ->
      Neighbors = getNeighbors(Id,LinkedList),
      From ! {neigh,Neighbors},
      listen(LinkedList);
    {launchNodes,C,H,S,PushPull,T,PeerS} ->
      launchNodes(LinkedList,C,H,S,PushPull,T,PeerS),
      listen(LinkedList);
    {getPID,Id,From} ->
      From ! {pid,getPID(Id,LinkedList)},
      listen(LinkedList);
    {timer} ->
      time(LinkedList),
      listen(LinkedList)
  end.

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

%test_makeC() ->
%  make_circular(5,[
%  #{id => 5,
%    linked_node_list => [#{id => 4}],
%    pid => 0},
%  #{id => 4,
%    linked_node_list => [#{id => 3},#{id => 5}],
%    pid => 0},
%  #{id => 3,
%    linked_node_list => [#{id => 2},#{id => 4}],
%    pid => 0},
%#{id => 2,
%   linked_node_list => [#{id => 1},#{id => 3}],
%   pid => 0},
%   #{id => 1,
%    linked_node_list => [#{id => 2}],
%    pid => 0}
%   ]).
