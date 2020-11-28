-module(network0).
-export([network_list/2,test/0]).

% first node
add(ID,_,[])->
  [#{id => ID, linked_node_list => [#{id_link => 1, age_neighbors => 0}]}];
% other node
add(ID, ID_max,[ #{id := ID_before, linked_node_list := List_before} |T ])->
  if
    % last node with id = 1 (cause tail recursive implementation)
    ID == 1 ->
      [  #{id =>ID, linked_node_list => [#{id_link=>ID_before, age_neighbors => 0}, #{id_link=>ID_max, age_neighbors => 0}]},
      #{id => ID_before, linked_node_list => lists:append([#{id_link=>ID,age_neighbors => 0}],List_before)} |T];
    % other node
    ID > 1 ->
      [#{id =>ID, linked_node_list => [#{id_link=>ID_before, age_neighbors => 0}]},
      #{id => ID_before, linked_node_list => lists:append([#{id_link => ID,age_neighbors => 0}],List_before)} |T]
  end.

%network_list(0,List_netw)->lists:reverse(List_netw);
network_list(0,List_netw)->List_netw;
network_list(Node,List)-> network_list(Node-1, add(Node, Node+length(List), List)).

test() ->
  network_list(5,[]).
