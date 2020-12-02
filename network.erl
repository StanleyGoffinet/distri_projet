-module(network).
-export([network_list/2,getNeighbors/2,test_getN/0,test_network/0]).

% first node
add(ID,PID,_,[])->
  [#{id => ID, linked_node_list => [#{id_node => 1, pid => PID}]}];
% other node
add(ID,PID, ID_max,[ #{id := ID_before, linked_node_list := List_before} |T ])->
  if
    % last node with id = 1 (cause tail recursive implementation)
    ID == 1 ->
      [  #{id =>ID, linked_node_list => [#{id_node=>ID_before, pid => PID}, #{id_node=>ID_max, pid => PID}]},
      #{id => ID_before, linked_node_list => lists:append([#{id_node=>ID,pid => PID}],List_before)} |T];
    % other node
    ID > 1 ->
      [#{id =>ID, linked_node_list => [#{id_node=>ID_before, pid => PID}]},
      #{id => ID_before, linked_node_list => lists:append([#{id_node => ID,pid => PID}],List_before)} |T]
  end.

%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;
network_list(Node,List)-> network_list(Node-1, add(Node,0, Node+length(List), List)).

getNeighbors(_,[])-> "Error, the node is not in the list";
getNeighbors(ID, [#{id := ID,linked_node_list:= Neighbors}|_])-> Neighbors;
getNeighbors(ID, [_|T])-> getNeighbors(ID, T).

test_getN() ->
  List = network_list(5,[]),
  [getNeighbors(1,List),getNeighbors(4,List)]
  .

test_network() ->
  network_list(5,[])
  .
