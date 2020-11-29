-module(network0).
-export([network_list/2,getNeighbors/2,test_getN/0,test_network/0]).

% first node
add(ID,_,[])->
  [#{id => ID, linked_node_list => [#{id_link => 1, age => 0}]}];
% other node
add(ID, ID_max,[ #{id := ID_before, linked_node_list := List_before} |T ])->
  if
    % last node with id = 1 (cause tail recursive implementation)
    ID == 1 ->
      [  #{id =>ID, linked_node_list => [#{id_link=>ID_before, age => 0}, #{id_link=>ID_max, age => 0}]},
      #{id => ID_before, linked_node_list => lists:append([#{id_link=>ID,age => 0}],List_before)} |T];
    % other node
    ID > 1 ->
      [#{id =>ID, linked_node_list => [#{id_link=>ID_before, age => 0}]},
      #{id => ID_before, linked_node_list => lists:append([#{id_link => ID,age => 0}],List_before)} |T]
  end.

%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;
network_list(Node,List)-> network_list(Node-1, add(Node, Node+length(List), List)).

getNeighbors(_,[])-> "Error, the node is not in the list";
getNeighbors(ID, [#{id := ID,linked_node_list:= Neighbors}|_])-> Neighbors;
getNeighbors(ID, [_|T])-> getNeighbors(ID, T).

test_getN() ->
  List = network_list(5,[]),
  getNeighbors(1,List)
  .

test_network() ->
  network_list(5,[])
  .
