-module(network).
-export([network_list/2,getNeighbors/2,getPID/2,test_getN/0,test_getPID/0,test_network/0]).

% first node
add(ID,PID,_,[])->
  [#{id => ID,pid => PID, linked_node_list => [#{id_node => 1}]}];
% other node
add(ID,PID, ID_max,[ #{id := ID_before,pid := PID_before , linked_node_list := List_before} |T ])->
  if
    % last node with id = 1 (cause tail recursive implementation)
    ID == 1 ->
      [  #{id =>ID,pid => PID , linked_node_list => [#{id_node=>ID_before}, #{id_node=>ID_max}]},
      #{id => ID_before,pid => PID_before, linked_node_list => lists:append([#{id_node=>ID}],List_before)} |T];
    % other node
    ID > 1 ->
      [#{id =>ID, pid => PID , linked_node_list => [#{id_node=>ID_before}]},
      #{id => ID_before,pid => PID_before ,linked_node_list => lists:append([#{id_node => ID}],List_before)} |T]
  end.

%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;
network_list(Node,List)-> network_list(Node-1, add(Node,0, Node+length(List), List)).


getPID(_,[])-> "Error, give empty list";
getPID(ID, [#{id := ID,pid := PID}|_])-> PID;
getPID(ID, [_|T])-> getPID(ID, T).

getNeighbors(_,[])-> "Error, the node is not in the list";
getNeighbors(ID, [#{id := ID,linked_node_list:= Neighbors}|_])-> Neighbors;
getNeighbors(ID, [_|T])-> getNeighbors(ID, T).

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
